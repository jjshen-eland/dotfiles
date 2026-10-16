"""gen1 entry points stay inert on hosts dotfiles-gen2 manages (marker: ~/.local/state/dotfiles-gen2/deploy.json).

dotfiles-gen2's dotctl took over brewup/sysup/allup/dotsync and the shell rc files (2026-10-16). Re-running gen1's
setup would swap the rc and Claude settings back, and gen1 allup/dotsync from a host not yet migrated would pull gen1
and rewrite settings on migrated hosts. Each entry point now says where to go instead and touches nothing.
"""
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def snapshot(root):
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob('*')) if p.is_file()}


class Gen2Handoff(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory(prefix='gen2-handoff-')
        self.addCleanup(tmp.cleanup)
        self.base = Path(tmp.name).resolve()
        self.home = self.base / 'home'
        (self.home / '.local/state/dotfiles-gen2').mkdir(parents=True)
        (self.home / '.local/state/dotfiles-gen2/deploy.json').write_text('{}\n')
        (self.home / '.zshrc').write_text('gen2 rc\n')
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.calls = self.base / 'calls'
        for tool in ('git', 'brew', 'ssh', 'claude', 'bun', 'sudo', 'apt'):
            (self.bin / tool).write_text(f'#!/bin/sh\necho "{tool} $*" >> "{self.calls}"\n')
            (self.bin / tool).chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f"{self.bin}:/usr/bin:/bin", DOTFILES_DIR=str(ROOT))

    def run_script(self, *argv):
        return subprocess.run(['bash', *map(str, argv)], env=self.env, capture_output=True, text=True,
                              stdin=subprocess.DEVNULL, timeout=60)

    def tool_calls(self):
        return self.calls.read_text() if self.calls.exists() else ''

    def test_brewup_points_to_dotctl_and_touches_nothing(self):
        before = snapshot(self.home)
        r = self.run_script(ROOT / 'scripts/brewup.sh')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('dotctl upgrade', r.stdout + r.stderr)
        self.assertEqual(self.tool_calls(), '')
        self.assertEqual(snapshot(self.home), before)

    def test_setup_refuses_to_swap_settings_back(self):
        for script in ('setup-mac-env.sh', 'setup-linux-env.sh'):
            with self.subTest(script=script):
                before = snapshot(self.home)
                r = self.run_script(ROOT / script)
                self.assertNotEqual(r.returncode, 0)
                # On the other platform the script's own platform check refuses first, which is just as inert.
                if (script == 'setup-mac-env.sh') == (sys.platform == 'darwin'):
                    self.assertIn('dotfiles-gen2', r.stdout + r.stderr)
                self.assertEqual(snapshot(self.home), before)
                self.assertEqual(self.tool_calls(), '')

    def test_allup_on_a_gen2_host_points_to_dotctl_fleet(self):
        r = self.run_script(ROOT / 'scripts/all-up.sh')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('dotctl fleet upgrade', r.stdout + r.stderr)
        self.assertEqual(self.tool_calls(), '')

    def test_dotsync_skips_this_host_and_reports_gen2_hosts(self):
        remote_home = self.base / 'remote'
        (remote_home / '.dotfiles').mkdir(parents=True)
        (remote_home / '.local/state/dotfiles-gen2').mkdir(parents=True)
        (remote_home / '.local/state/dotfiles-gen2/deploy.json').write_text('{}\n')
        # The fake ssh runs the remote snippet locally, as the remote host's HOME.
        (self.bin / 'ssh').write_text(f'#!/bin/sh\nfor a in "$@"; do last="$a"; done\nHOME="{remote_home}" exec bash -c "$last"\n')
        inventory = self.base / 'inventory.conf'
        inventory.write_text('remote1 10.9.9.9\n')
        self.env['INVENTORY_FILE'] = str(inventory)
        r = self.run_script(ROOT / 'scripts/dotfiles-sync.sh', 'remote1')
        out = r.stdout + r.stderr
        self.assertIn('dotctl sync', out)
        self.assertIn('remote1', out)
        self.assertIn('dotfiles-gen2', out)
        self.assertEqual(r.returncode, 0, out)
        self.assertNotIn('git', self.tool_calls())


if __name__ == '__main__':
    unittest.main()
