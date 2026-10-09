#!/usr/bin/env python3
"""Isolated ownership, install failure and Bash/Zsh environment contracts."""
import importlib.util
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Tools(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dev-tools-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / 'home'
        self.home.mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.repo = self.root / 'repo'
        (self.repo / 'scripts').mkdir(parents=True)
        (self.repo / 'shell').mkdir()
        shutil.copy(ROOT / 'shell/environment.sh', self.repo / 'shell/environment.sh')
        shutil.copy(ROOT / 'scripts/dev-tools.sh', self.repo / 'scripts/dev-tools.sh')
        (self.repo / 'scripts/dev-tools.tsv').write_text(
            'core\tall\tformula\talpha\ttool-alpha\t--version\n'
            'workstation\tall\tformula\tbeta\ttool-beta\t--version\n')
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin) + ':/usr/bin:/bin:/usr/sbin:/sbin',
                        TEST_BIN=str(self.bin), TEST_LOG=str(self.root / 'log'))
        self.brew = self.bin / 'brew'
        self.brew.write_text('#!' + sys.executable + '\n' + '''import os, sys
from pathlib import Path
args=sys.argv[1:]
with open(os.environ['TEST_LOG'],'a') as f: f.write(' '.join(args)+'\\n')
bin=Path(os.environ['TEST_BIN'])
package=args[-1]
if args[0]=='list': sys.exit(0 if (bin/('tool-'+package)).exists() else 1)
if args[0]=='deps': print(os.environ.get('TEST_DEPS','')); sys.exit(0)
if args[0]=='outdated': print(os.environ.get('TEST_OUTDATED','')); sys.exit(0)
if args[0] in ('install','upgrade'):
 if os.environ.get('TEST_READ_STDIN')=='1': sys.stdin.read()
 if os.environ.get('TEST_FAIL')=='1': sys.exit(42)
 p=bin/os.environ.get('TEST_INSTALL_EXE','tool-'+package); p.write_text('#!/bin/sh\\necho version-1\\n'); p.chmod(0o755)
 sys.exit(0)
if args[0]=='uninstall':
 if os.environ.get('TEST_DEPENDENT')=='1': sys.exit(1)
 (bin/('tool-'+package)).unlink(); sys.exit(0)
sys.exit(2)
''')
        self.brew.chmod(0o755)

    def tool(self, name, broken=False):
        p = self.bin / ('tool-' + name)
        p.write_text('#!/bin/sh\n' + ('exit 1\n' if broken else 'echo version-1\n'))
        p.chmod(0o755)
        return p

    def run_tools(self, *args):
        return subprocess.run(['bash', str(self.repo / 'scripts/dev-tools.sh'), *args],
                              env=self.env, capture_output=True, text=True)

    def ledger(self):
        p = self.home / '.local/state/dotfiles/tools.tsv'
        return ''.join(line + '\n' for line in p.read_text().splitlines() if line.startswith(('formula\t', 'cask\t', 'native\t'))) if p.exists() else ''

    def log(self):
        p = self.root / 'log'
        return p.read_text() if p.exists() else ''

    def test_plan_is_read_only_and_check_fails_missing(self):
        self.assertEqual(self.run_tools('plan').returncode, 0)
        self.assertFalse((self.home / '.local').exists())
        self.assertEqual(self.run_tools('check').returncode, 1)
        self.assertEqual(self.log(), '')

    def test_unselected_tools_are_not_executed_by_any_mode(self):
        self.tool('alpha')
        marker = self.root / 'unselected-executed'
        for group in ('workstation', 'legacy'):
            (self.repo / 'scripts/dev-tools.tsv').write_text(
                'core\tall\tformula\talpha\ttool-alpha\t--version\n'
                + group + '\tall\tformula\tbeta\ttool-beta\t--version\n')
            extra = self.tool('beta')
            extra.write_text('#!/bin/sh\nprintf called > "' + str(marker) + '"\nexit 1\n')
            for mode in ('plan', 'apply', 'check'):
                with self.subTest(group=group, mode=mode):
                    marker.unlink(missing_ok=True)
                    result = self.run_tools(mode)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertFalse(marker.exists(), 'unselected executable was invoked')
                    if mode == 'plan':
                        self.assertIn('UNMANAGED\tbeta\t', result.stdout)

    def test_install_failure_is_not_success(self):
        self.env['TEST_FAIL'] = '1'
        p = self.run_tools('apply')
        self.assertEqual(p.returncode, 1, p.stdout + p.stderr)
        self.assertIn('FAILED', p.stderr)
        self.assertNotIn('alpha', self.ledger())

    def test_new_install_owned_and_rerun_no_mutation(self):
        p = self.run_tools('apply')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(self.ledger(), 'formula\talpha\n')
        first = self.log()
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertEqual(first, self.log())
        self.assertEqual(self.run_tools('check').returncode, 0)

    def test_installer_stdin_cannot_consume_remaining_tools(self):
        self.env['TEST_READ_STDIN'] = '1'
        result = self.run_tools('apply', '--profile', 'workstation')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.bin / 'tool-beta').exists(), 'installer skipped the next tool')
        self.assertEqual(self.ledger(), 'formula\talpha\nformula\tbeta\n')
        self.assertEqual(self.run_tools('check', '--profile', 'workstation').returncode, 0)

    def test_version_probe_stdin_cannot_hide_missing_tool(self):
        alpha = self.tool('alpha')
        alpha.write_text('#!/bin/sh\ncat >/dev/null\necho version-1\n')
        result = self.run_tools('check', '--profile', 'workstation')
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('MISSING_OR_BROKEN\ttool-beta\tbeta', result.stdout)

    def test_preexisting_and_independent_tools_not_owned_or_changed(self):
        self.tool('alpha')
        local = self.tool('personal')
        before = local.read_bytes()
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertEqual(self.ledger(), '')
        self.assertEqual(local.read_bytes(), before)
        self.assertEqual(self.log(), '')

    def test_broken_unmanaged_tool_is_not_replaced(self):
        local = self.tool('alpha', broken=True)
        before = local.read_bytes()
        self.assertEqual(self.run_tools('apply').returncode, 1)
        self.assertNotIn('install ', self.log())
        self.assertEqual(local.read_bytes(), before)

    def test_adoption_plan_then_removal_only_managed(self):
        self.tool('alpha')
        old = self.tool('beta')
        local = self.tool('personal')
        plan = self.run_tools('plan', '--adopt', 'beta')
        self.assertIn('REMOVE_MANAGED\tbeta', plan.stdout)
        self.assertEqual(self.ledger(), '')
        p = self.run_tools('apply', '--adopt', 'beta')
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        self.assertFalse(old.exists())
        self.assertTrue(local.exists())
        self.assertIn('uninstall --formula beta', self.log())
        self.assertNotIn('upgrade', self.log())

    def test_keep_releases_ownership(self):
        self.assertEqual(self.run_tools('apply', '--profile', 'workstation').returncode, 0)
        self.assertEqual(self.run_tools('apply', '--keep', 'beta').returncode, 0)
        self.assertTrue((self.bin / 'tool-beta').exists())
        self.assertNotIn('beta', self.ledger())
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertTrue((self.bin / 'tool-beta').exists())

    def test_dependents_block_removal_without_force(self):
        self.assertEqual(self.run_tools('apply', '--profile', 'workstation').returncode, 0)
        self.env['TEST_DEPENDENT'] = '1'
        self.assertEqual(self.run_tools('apply', '--profile', 'core').returncode, 1)
        self.assertIn('beta', self.ledger())
        self.assertTrue((self.bin / 'tool-beta').exists())
        self.assertNotIn('--force', self.log())

    def test_outdated_dependency_blocks_before_install(self):
        self.env.update(TEST_DEPS='personal', TEST_OUTDATED='personal')
        self.assertEqual(self.run_tools('apply').returncode, 1)
        self.assertNotIn('install ', self.log())

    def test_profile_persists_without_accidental_removal(self):
        self.assertEqual(self.run_tools('apply', '--profile', 'workstation').returncode, 0)
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertTrue((self.bin / 'tool-beta').exists())
        self.assertNotIn('uninstall', self.log())

    def test_local_override_never_reinstalled(self):
        self.tool('alpha')
        self.assertEqual(self.run_tools('apply', '--keep', 'alpha').returncode, 0)
        (self.bin / 'tool-alpha').unlink()
        self.assertEqual(self.run_tools('apply').returncode, 1)
        self.assertNotIn('install ', self.log())

    def test_bad_manifest_stops_before_first_install(self):
        manifest = self.repo / 'scripts/dev-tools.tsv'
        with manifest.open('a') as f:
            f.write('invalid\n')
        self.assertEqual(self.run_tools('apply').returncode, 2)
        self.assertNotIn('install ', self.log())

    def test_tapped_outdated_dependency_also_blocks(self):
        self.env.update(TEST_DEPS='tap/name/personal', TEST_OUTDATED='personal')
        self.assertEqual(self.run_tools('apply').returncode, 1)
        self.assertNotIn('install ', self.log())

    def test_locked_writer_blocks_without_package_mutation(self):
        lock = self.home / '.local/state/dotfiles/tools.lock'
        lock.mkdir(parents=True)
        self.assertEqual(self.run_tools('apply').returncode, 1)
        self.assertTrue(lock.exists())
        self.assertEqual(self.log(), '')

    def test_corrupt_ledger_cannot_remove_duplicate_packages(self):
        ledger = self.home / '.local/state/dotfiles/tools.tsv'
        ledger.parent.mkdir(parents=True)
        ledger.write_text('formula\tbeta\nformula\tbeta\n')
        self.tool('beta')
        self.assertEqual(self.run_tools('apply').returncode, 2)
        self.assertEqual(self.log(), '')

    def test_both_setup_call_sites_propagate_install_failure(self):
        self.env['TEST_FAIL'] = '1'
        for name, shell in [('setup-linux-env.sh', 'bash'), ('setup-mac-env.sh', 'zsh')]:
            binary = shutil.which(shell)
            if not binary:
                self.skipTest(shell + ' unavailable')
            setup = (ROOT / name).read_text()
            call = next(line for line in setup.splitlines()
                        if 'scripts/dev-tools.sh" apply' in line)
            script = 'set -e\nSCRIPT_DIR="$1"\nTOOL_PROFILE=core\n' + call + '\necho SUCCESS\n'
            p = subprocess.run([binary, '-f', '-c', script, 'setup-probe', str(self.repo)],
                               env=self.env, text=True, capture_output=True)
            self.assertNotEqual(p.returncode, 0, name + p.stdout + p.stderr)
            self.assertNotIn('SUCCESS', p.stdout)

    def test_old_macos_system_python_gets_parallel_brew_install(self):
        (self.repo / 'scripts/dev-tools.tsv').write_text('core\tall\tformula\tpython\tpython3\t--version\n')
        # Shell-level doubles model the absolute OS path without changing /usr/bin.
        # The real provider path and ledger logic still run against fake Homebrew.
        startup = self.root / 'system-python.sh'
        startup.write_text('''command() {
    if [ "$1" = -v ] && [ "$2" = python3 ]; then
        echo /usr/bin/python3
    else
        builtin command "$@"
    fi
}
python3() {
    if [ "$1" = --version ]; then echo Python-3.9; return 0; fi
    [ -f "$TEST_BIN/tool-python" ]
}
''')
        self.env['BASH_ENV'] = str(startup)
        p = self.run_tools('apply')
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        self.assertIn('install --formula python', self.log())
        self.assertIn('formula\tpython', self.ledger())
        self.assertNotIn('uninstall', self.log())
        self.assertNotIn('upgrade', self.log())

    def test_old_user_python_blocks_without_replacing_it(self):
        (self.repo / 'scripts/dev-tools.tsv').write_text('core\tall\tformula\tpython\tpython3\t--version\n')
        python = self.bin / 'python3'
        python.write_text('#!/bin/sh\n[ "$1" = --version ] && { echo Python-3.9; exit 0; }; exit 1\n')
        python.chmod(0o755)
        before = python.read_bytes()
        self.assertEqual(self.run_tools('apply').returncode, 1)
        self.assertEqual(python.read_bytes(), before)
        self.assertNotIn('install ', self.log())

    def test_real_codex_contract_keeps_cask_and_single_install(self):
        row = next(row for row in (ROOT / 'scripts/dev-tools.tsv').read_text().splitlines()
                   if row.split('\t')[3:4] == ['codex'])
        (self.repo / 'scripts/dev-tools.tsv').write_text(row + '\n')
        # Hide host-installed CLI, preserving a fully isolated package fixture.
        (self.repo / 'shell/environment.sh').write_text('export PATH="$TEST_BIN:/usr/bin:/bin"\n')
        self.env['TEST_INSTALL_EXE'] = 'codex'
        p = self.run_tools('apply')
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        self.assertIn('cask\tcodex', self.ledger())
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertEqual(self.log().splitlines().count('install --cask codex'), 1)

    def test_legacy_tools_are_opt_in_and_never_new_installs(self):
        manifest = self.repo / 'scripts/dev-tools.tsv'
        with manifest.open('a') as f:
            f.write('legacy\tall\tcask\told-ai\ttool-old-ai\t--version\n')
        self.assertEqual(self.run_tools('apply', '--profile', 'workstation').returncode, 0)
        self.assertNotIn('old-ai', self.log())
        local = self.tool('old-ai')
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertTrue(local.exists())
        self.assertNotIn('old-ai', self.ledger())

    def test_only_owned_failed_capability_can_upgrade(self):
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.tool('alpha', broken=True)
        local = self.tool('personal')
        before = local.read_bytes()
        self.assertEqual(self.run_tools('apply').returncode, 0)
        self.assertIn('upgrade --formula alpha', self.log())
        self.assertEqual(local.read_bytes(), before)
        self.assertNotIn('upgrade --formula personal', self.log())

    def test_new_binary_supersedes_cached_old_fallback(self):
        fallback = self.root / 'fallback'
        fallback.mkdir()
        (fallback / 'tool-alpha').write_text('#!/bin/sh\nexit 1\n')
        (fallback / 'tool-alpha').chmod(0o755)
        self.env['PATH'] = str(self.bin) + ':' + str(fallback) + ':/usr/bin:/bin'
        ledger = self.home / '.local/state/dotfiles/tools.tsv'
        ledger.parent.mkdir(parents=True)
        ledger.write_text('formula\talpha\n')
        p = self.run_tools('apply')
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        self.assertTrue((fallback / 'tool-alpha').exists())
        self.assertEqual(self.run_tools('check').returncode, 0)

    def test_unknown_adoption_and_bad_profile_no_mutation(self):
        self.assertEqual(self.run_tools('apply', '--adopt', 'unknown').returncode, 2)
        self.assertEqual(self.run_tools('apply', '--profile', 'typo').returncode, 2)
        self.assertEqual(self.log(), '')


class Environment(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='shell-env-test-')
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        (self.home / '.dotfiles/shell').mkdir(parents=True)
        shutil.copy(ROOT / 'shell/environment.sh', self.home / '.dotfiles/shell/environment.sh')
        self.env = dict(os.environ, HOME=str(self.home), ZDOTDIR=str(self.home),
                        PATH='/project/venv/bin:/usr/bin:/bin:/project/venv/bin')
        spec = importlib.util.spec_from_file_location('shell_env', ROOT / 'scripts/ensure-shell-env.py')
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def migrate(self, mode):
        return subprocess.run([sys.executable, str(ROOT / 'scripts/ensure-shell-env.py'), mode],
                              env=self.env, text=True, capture_output=True)

    def test_plan_apply_idempotence_preserves_personal_content(self):
        old = '# personal\nexport PERSONAL=keep\ncase $- in *i*) ;; *) return ;; esac\n'
        (self.home / '.bashrc').write_text(old)
        self.assertEqual(self.migrate('plan').returncode, 0)
        self.assertEqual((self.home / '.bashrc').read_text(), old)
        self.assertEqual(self.migrate('check').returncode, 1)
        self.assertEqual(self.migrate('apply').returncode, 0)
        self.assertTrue((self.home / '.bashrc').read_text().endswith(old))
        backups = list(self.home.glob('*.dotfiles-backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), old)
        self.assertEqual(self.migrate('apply').returncode, 0)
        self.assertEqual(self.migrate('check').returncode, 0)
        self.assertEqual(list(self.home.glob('*.dotfiles-backup-*')), backups)

    def test_symlink_and_modified_marker_fail_before_write(self):
        target = self.home / 'personal'
        target.write_text('keep')
        (self.home / '.bashrc').symlink_to(target)
        self.assertNotEqual(self.migrate('apply').returncode, 0)
        self.assertEqual(target.read_text(), 'keep')
        self.assertFalse((self.home / '.zshenv').exists())
        (self.home / '.bashrc').unlink()
        (self.home / '.bashrc').write_text(self.module.START + '\nlocal edit\n' + self.module.END)
        self.assertNotEqual(self.migrate('apply').returncode, 0)
        self.assertFalse((self.home / '.zshenv').exists())

    def test_bash_zsh_noninteractive_same_path_and_silent_rerun(self):
        source = self.home / '.dotfiles/shell/environment.sh'
        results = []
        for shell in ('bash', 'zsh'):
            binary = shutil.which(shell)
            if not binary:
                self.skipTest(shell + ' unavailable')
            p = subprocess.run([binary, '-f', '-c', '. "$1"; . "$1"; printf "%s" "$PATH"', 'probe', str(source)],
                               env=self.env, capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            paths = p.stdout.split(':')
            self.assertEqual(paths[0], '/project/venv/bin')
            self.assertEqual(len(paths), len(set(paths)))
            self.assertIn(str(self.home / '.local/bin'), paths)
            results.append(p.stdout)
        self.assertEqual(results[0], results[1])

    def test_missing_shared_source_blocks_shell_changes(self):
        (self.home / '.dotfiles/shell/environment.sh').unlink()
        self.assertEqual(self.migrate('apply').returncode, 1)
        self.assertFalse((self.home / '.bashrc').exists())

    def test_setup_generated_environment_matches_migration(self):
        self.assertEqual(self.migrate('apply').returncode, 0)
        for name, shell in [('setup-mac-env.sh', 'zsh'), ('setup-linux-env.sh', 'bash')]:
            binary = shutil.which(shell)
            if not binary:
                self.skipTest(shell + ' unavailable')
            setup = (ROOT / name).read_text()
            # Execute the real generated source block, not a reimplemented fixture.
            block = re.search(r'# dotfiles:environment:start\n.*?# dotfiles:environment:end\n', setup, re.S).group()
            self.assertEqual(block, self.module.BLOCK)
            p = subprocess.run([binary, '-f', '-c', block + 'printf "%s" "$PATH"'],
                               env=self.env, text=True, capture_output=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(p.stdout.split(':')[0], '/project/venv/bin')
            self.assertIn(str(self.home / '.local/bin'), p.stdout.split(':'))

    def test_actual_bashrc_early_return_and_zshenv_startup(self):
        (self.home / '.bashrc').write_text('return\n')
        self.assertEqual(self.migrate('apply').returncode, 0)
        for shell, script in [('bash', '. "$HOME/.bashrc"; printf "%s" "$PATH"'),
                              ('zsh', 'printf "%s" "$PATH"')]:
            binary = shutil.which(shell)
            if not binary:
                self.skipTest(shell + ' unavailable')
            p = subprocess.run([binary, '-c', script], env=self.env, capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertIn(str(self.home / '.local/bin'), p.stdout.split(':'))


if __name__ == '__main__':
    unittest.main()
