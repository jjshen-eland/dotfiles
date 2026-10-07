#!/usr/bin/env python3
"""Exercise emitted shell settings and real archives without running setup."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class MacMetadataTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-mac-metadata-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        source = (ROOT / "setup-mac-env.sh").read_text()
        blocks = re.findall(
            r"cat (?:>|>>) ~/.zshenv << 'ZSHENV_EOF'\n(.*?)^ZSHENV_EOF$",
            source, re.M | re.S,
        )
        # Use the actual emitted environment section. Redirect only the .env
        # lookup so tests cannot load the user's credentials or local overrides.
        environment = blocks[-1].split("# 環境變數\n", 1)[1]
        environment = environment.replace("~/.env", '"$DOTFILES_METADATA_TEST_ENV"')
        (self.root / ".zshenv").write_text(environment)
        self.env = os.environ.copy()
        self.env.pop("COPYFILE_DISABLE", None)
        self.env["ZDOTDIR"] = str(self.root)
        self.env["DOTFILES_METADATA_TEST_ENV"] = str(self.root / "absent.env")
        self.payload = self.root / "payload"
        self.payload.mkdir()
        (self.payload / "release.txt").write_text("release payload\n")

    def zsh(self, command, *args):
        return subprocess.run(
            ["zsh", "-c", command, "metadata-test", *map(str, args)],
            env=self.env, text=True, capture_output=True, check=True,
        ).stdout

    def test_noninteractive_zsh_and_bash_child(self):
        for command in (
            'printf "%s" "${COPYFILE_DISABLE-unset}"',
            "exec /bin/bash --noprofile --norc -c "
            "'printf \"%s\" \"${COPYFILE_DISABLE-unset}\"'",
        ):
            with self.subTest(command=command):
                self.assertEqual(self.zsh(command), "1")

    @unittest.skipUnless(sys.platform == "darwin", "requires macOS copyfile")
    def test_appledouble_default_and_single_command_override(self):
        file = self.payload / "release.txt"
        subprocess.run(["xattr", "-w", "com.example.dotfiles-test", "proof", str(file)], check=True)
        Path(str(file) + "/..namedfork/rsrc").write_bytes(b"resource fork proof")
        for name, prefix, expected in (
            ("default", "", False),
            ("unset", "env -u COPYFILE_DISABLE ", True),
            ("empty", "COPYFILE_DISABLE= ", False),
        ):
            with self.subTest(mode=name):
                archive = self.root / (name + ".tar")
                self.zsh(prefix + 'tar -cf "$1" -C "$2" payload', archive, self.root)
                # bsdtar -t consumes AppleDouble internally and hides these
                # entries; inspect the raw archive with an independent reader.
                with tarfile.open(archive) as stream:
                    names = stream.getnames()
                self.assertEqual(any(Path(n).name.startswith("._") for n in names), expected)
        self.assertEqual(self.zsh('printf "%s" "$COPYFILE_DISABLE"'), "1")

    @unittest.skipUnless(sys.platform == "darwin", "requires macOS tar flags")
    def test_strict_archive_excludes_existing_junk_and_xattrs(self):
        subprocess.run(["xattr", "-w", "com.example.dotfiles-test", "proof",
                        str(self.payload / "release.txt")], check=True)
        for name in (".DS_Store", "._existing"):
            (self.payload / name).write_text("existing junk\n")
        archive = self.root / "strict.tar"
        self.zsh('tar --no-mac-metadata --no-xattrs --exclude=".DS_Store" '
                 '--exclude="._*" -cf "$1" -C "$2" payload', archive, self.root)
        with tarfile.open(archive) as stream:
            entries = stream.getmembers()
        self.assertIn("payload/release.txt", [e.name for e in entries])
        self.assertFalse(any(Path(e.name).name == ".DS_Store" or
                             Path(e.name).name.startswith("._") for e in entries))
        self.assertFalse(any("xattr" in key for e in entries for key in e.pax_headers))

    def test_global_git_ignore(self):
        subprocess.run(["git", "init", "-q", "--template=", str(self.root)], check=True)
        for name, expected in ((".DS_Store", 0), ("._release.txt", 0), ("release.txt", 1)):
            with self.subTest(name=name):
                result = subprocess.run(
                    ["git", "-C", str(self.root), "-c",
                     "core.excludesfile=" + str(ROOT / "git/gitignore_global"),
                     "check-ignore", "--no-index", "payload/" + name],
                    capture_output=True,
                )
                self.assertEqual(result.returncode, expected)

    def test_defaults_network_setting_and_linux_guard(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        calls = self.root / "defaults-calls"
        stubs = {
            "uname": '#!/bin/sh\nprintf "%s\\n" "$METADATA_TEST_OS"\n',
            "defaults": '#!/bin/sh\nprintf "%s\\n" "$*" >> "$METADATA_TEST_CALLS"\n',
            "killall": "#!/bin/sh\nexit 0\n",
        }
        for name, content in stubs.items():
            path = bin_dir / name
            path.write_text(content)
            path.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + os.pathsep + self.env["PATH"],
                   METADATA_TEST_CALLS=str(calls))
        for platform, expected_rc in (("Darwin", 0), ("Linux", 1)):
            env["METADATA_TEST_OS"] = platform
            calls.write_text("")
            result = subprocess.run(["bash", str(ROOT / "write-mac-defaults.sh")],
                                    env=env, capture_output=True)
            self.assertEqual(result.returncode, expected_rc)
            if platform == "Darwin":
                self.assertIn("write com.apple.desktopservices DSDontWriteNetworkStores -bool true",
                              calls.read_text().splitlines())
            else:
                self.assertEqual(calls.read_text(), "")

    @unittest.skipUnless(sys.platform.startswith("linux"), "requires actual GNU/Linux tar")
    def test_linux_tar_ignores_copyfile_variable(self):
        archives = []
        for value in (None, "1"):
            env = self.env.copy()
            if value is not None:
                env["COPYFILE_DISABLE"] = value
            archive = self.root / ("linux-" + str(value) + ".tar")
            subprocess.run([shutil.which("tar"), "-cf", str(archive), "-C",
                            str(self.root), "payload"], env=env, check=True)
            archives.append(archive.read_bytes())
        self.assertEqual(*archives)


if __name__ == "__main__":
    unittest.main()
