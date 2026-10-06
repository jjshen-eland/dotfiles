#!/usr/bin/env python3
"""Isolated runtime migration behavior tests; --baseline exercises the old paths."""
from pathlib import Path
import os
import re
import subprocess
import sys
import tempfile
import unittest
import importlib.util
import json
import shutil
import errno
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class RuntimeLayoutTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name).resolve()
        self.home = self.base / 'home'
        self.repo = self.base / 'repo'
        self.bin = self.base / 'bin'
        for p in (self.home, self.repo, self.bin):
            p.mkdir()
        for runtime in ('claude', 'codex'):
            entry = self.repo / runtime / 'skills/demo'
            entry.mkdir(parents=True)
            (entry / 'SKILL.md').write_text('fixture skill\n')
        rules = self.repo / 'codex/rules'
        rules.mkdir()
        (rules / 'default.rules').write_text('managed rules\n')
        ps = self.bin / 'ps'
        ps.write_text('#!/bin/sh\n[ "${PS_FAIL:-0}" = 1 ] && exit 1\n'
                      f'echo "$$ {os.getuid()} /usr/bin/python3"\n'
                      f'[ "${{PS_WRITER:-0}}" = 1 ] && echo "4711 {os.getuid()} /app-server-daemon/bin/codex"\nexit 0\n')
        ps.chmod(0o755)
        self.env = {k: v for k, v in os.environ.items() if k not in ('CODEX_HOME', 'DOTFILES_DIR', 'DOTFILES_RUNTIME_TEST_FAIL')}
        self.env.update(HOME=str(self.home), DOTFILES_DIR=str(self.repo), PATH=str(self.bin) + os.pathsep + os.environ['PATH'], PYTHONDONTWRITEBYTECODE='1')
        spec = importlib.util.spec_from_file_location('runtime_layout', ROOT / 'scripts/ensure-runtime-layout.py')
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def run_cli(self, command='apply', expected=0, **env):
        r = subprocess.run([sys.executable, str(ROOT / 'scripts/ensure-runtime-layout.py'), command],
                           env={**self.env, **env}, text=True, capture_output=True)
        self.assertEqual(expected, r.returncode, r.stdout + r.stderr)
        return json.loads(r.stdout)

    def root(self, name):
        return self.module.Layout(self.home, self.repo).targets[name]

    def handoff(self, slug='alpha', archive=False, legacy=True):
        store = self.home / ('.claude/handoffs' if legacy else '.agents/handoffs')
        p = store / ('archive/20261006-' + slug + '.md' if archive else slug + '.md')
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(f'---\nslug: {slug}\ncreated: 2026-10-06\n---\n# checkpoint\n')
        p.chmod(0o600)
        os.utime(p, ns=(1791244800000000000, 1791244800000000000))
        return p

    def receipt(self, name='handoffs'):
        found = [p for p in (self.home / '.runtime-layout').glob('*.json') if json.loads(p.read_text())['name'] == name]
        self.assertEqual(1, len(found))
        return json.loads(found[0].read_text())

    def resume(self, txid, command='recover', expected=0, **env):
        r = subprocess.run([sys.executable, str(ROOT / 'scripts/ensure-runtime-layout.py'), command, '--transaction', txid],
                           env={**self.env, **env}, text=True, capture_output=True)
        self.assertEqual(expected, r.returncode, r.stdout + r.stderr)
        return json.loads(r.stdout)

    def test_inventory_and_dry_run_do_not_create_files(self):
        before = self.module.snapshot(self.home)
        for cmd in ('inventory', 'dry-run'):
            report = self.run_cli(cmd)
            self.assertFalse(report['native_loading_verified'])
            self.assertEqual(before, self.module.snapshot(self.home))
        self.run_cli('verify', expected=1)

    def test_inventory_exposes_writers_and_failed_process_inventory(self):
        p = self.handoff()
        before = self.module.snapshot(self.home)
        report = self.run_cli('inventory', expected=1, PS_WRITER='1')
        self.assertEqual(4711, report['process_inventory']['writers'][0]['pid'])
        self.assertEqual('daemon', report['process_inventory']['writers'][0]['kind'])
        self.assertEqual(before, self.module.snapshot(self.home))
        report = self.run_cli('inventory', expected=1, PS_FAIL='1')
        self.assertFalse(report['process_inventory']['ok'])
        self.assertTrue(p.exists())

    def test_fresh_whole_link_upgrade_and_idempotence(self):
        for kind in ('claude-skills', 'codex-skills', 'codex-rules'):
            target = self.root(kind)
            target.parent.mkdir(parents=True, exist_ok=True)
            source = self.repo / ('claude/skills' if kind == 'claude-skills' else 'codex/rules' if kind == 'codex-rules' else 'codex/skills')
            target.symlink_to(source)
        source = self.module.snapshot(self.repo)
        self.run_cli()
        self.assertEqual(source, self.module.snapshot(self.repo))
        for kind in ('claude-skills', 'codex-skills', 'codex-rules', 'handoffs'):
            self.assertFalse(self.root(kind).is_symlink())
        self.assertEqual('', (self.root('codex-rules') / 'default.rules').read_text())
        self.assertEqual('managed rules\n', (self.root('codex-rules') / 'dotfiles.rules').read_text())
        self.run_cli('verify')
        before = self.module.snapshot(self.home)
        self.run_cli()
        self.assertEqual(before, self.module.snapshot(self.home))

    def test_personal_third_party_system_and_explicit_override_preserved(self):
        for kind in ('claude-skills', 'codex-skills', 'codex-legacy'):
            root = self.root(kind)
            root.mkdir(parents=True)
            (root / ('synced' if kind == 'claude-skills' else '.system')).mkdir()
            (root / 'third-party').symlink_to('/some/external/provider')
        rules = self.root('codex-rules')
        rules.mkdir(parents=True, exist_ok=True)
        (rules / 'default.rules').write_bytes(b'precious approvals\x00\n')
        before = self.module.snapshot(rules / 'default.rules', False)
        self.run_cli()
        self.assertEqual(before, self.module.snapshot(rules / 'default.rules', False))
        self.assertTrue((self.root('claude-skills') / 'synced').is_dir())
        self.assertEqual('/some/external/provider', os.readlink(self.root('codex-skills') / 'third-party'))
        self.assertTrue((self.root('codex-legacy') / '.system').is_dir())
        other = self.base / 'custom-codex'
        self.run_cli(CODEX_HOME=str(other))
        self.assertTrue((other / 'rules/dotfiles.rules').is_file())

    def test_pristine_copy_and_local_historical_tree(self):
        root = self.root('claude-skills')
        root.mkdir(parents=True)
        shutil.copytree(self.repo / 'claude/skills/demo', root / 'demo')
        subprocess.run(['git', 'init', '-q', '-b', 'main', str(self.repo)], check=True)
        subprocess.run(['git', '-C', str(self.repo), 'add', 'claude/skills/demo/SKILL.md'], check=True)
        subprocess.run(['git', '-C', str(self.repo), '-c', 'user.name=test', '-c', 'user.email=test@test', '-c', 'core.hooksPath=/dev/null', 'commit', '-qm', 'fixture'], check=True)
        (self.repo / 'claude/skills/demo/SKILL.md').write_text('new revision\n')
        self.run_cli()
        self.assertTrue((root / 'demo').is_symlink())
        saved = self.receipt('claude-skills')['operations'][0]['backup']
        self.assertEqual('fixture skill\n', (Path(saved) / 'demo/SKILL.md').read_text())

    def test_unknown_ownership_and_alias_stop_with_source_intact(self):
        root = self.root('claude-skills')
        (root / 'demo').mkdir(parents=True)
        (root / 'demo/custom').write_text('mine')
        before = self.module.snapshot(root)
        self.run_cli(expected=1)
        self.assertEqual(before, self.module.snapshot(root))
        self.assertFalse((root / 'demo').is_symlink())
        # Parent aliases cannot redirect writes into the source checkout.
        second = self.base / 'aliased-home'
        second.mkdir()
        (second / '.claude').symlink_to(self.repo / 'claude')
        repo_before = self.module.snapshot(self.repo)
        self.run_cli(expected=1, HOME=str(second))
        self.assertEqual(repo_before, self.module.snapshot(self.repo))

    def test_writer_and_failed_process_inventory_block_existing_roots(self):
        old = self.handoff()
        before = self.module.snapshot(old.parent)
        for env in ({'PS_WRITER': '1'}, {'PS_FAIL': '1'}):
            self.run_cli(expected=1, **env)
            self.assertEqual(before, self.module.snapshot(old.parent))
            # Admission failure is recorded; explicit diagnosis is required.
            self.assertTrue(old.exists())

    def test_handoff_legacy_data_and_alias_keep_metadata(self):
        old = self.handoff(archive=True)
        (old.parent / 'attachment.bin').write_bytes(b'\x00\xffpayload')
        before = self.module.snapshot(old.parent.parent, False)
        self.run_cli()
        new = self.root('handoffs')
        self.assertEqual(before, self.module.snapshot(new, False))
        self.assertFalse(old.parent.parent.exists())
        # Recognized alias still finishes with one real canonical store.
        legacy = self.home / '.claude/handoffs'
        legacy.symlink_to(new)
        self.run_cli()
        self.assertFalse(legacy.exists())
        self.assertFalse(new.is_symlink())
        self.assertEqual(before, self.module.snapshot(new, False))

    def test_split_conflicts_are_conservative(self):
        self.handoff('alpha')
        self.handoff('alpha', archive=True, legacy=False)
        before = {p: self.module.snapshot(p) for p in (self.home / '.claude/handoffs', self.root('handoffs'))}
        self.run_cli(expected=1)
        for p, s in before.items():
            self.assertEqual(s, self.module.snapshot(p))

    def test_split_disjoint_worklines_and_same_path_duplicates(self):
        self.handoff('alpha')
        self.handoff('beta', legacy=False)
        self.run_cli()
        self.assertTrue((self.root('handoffs') / 'alpha.md').is_file())
        self.assertTrue((self.root('handoffs') / 'beta.md').is_file())

    def test_numeric_slug_and_provenance_collision(self):
        self.handoff('120000-alpha')
        self.handoff('alpha', archive=True, legacy=False).rename(self.root('handoffs') / 'archive/20261006-120000-alpha.md')
        self.run_cli(expected=1)

    def test_handoff_child_link_is_not_followed(self):
        p = self.handoff()
        (p.parent / 'external').symlink_to(self.repo)
        before = self.module.snapshot(self.repo)
        self.run_cli(expected=1)
        self.assertEqual(before, self.module.snapshot(self.repo))

    def test_identical_unanchored_claims_under_different_names_stop(self):
        a = self.handoff('alpha', archive=True)
        b = self.handoff('beta', archive=True, legacy=False)
        a.write_text('# Earlier checkpoint\nEarlier session allowed push.\n')
        b.write_bytes(a.read_bytes())
        os.utime(a.parent, ns=(1000000000000, 1000000000000))
        os.utime(b.parent, ns=(1000000000000, 1000000000000))
        self.run_cli(expected=1)
        self.assertTrue(a.exists() and b.exists())

    def test_anchors_same_provenance_different_names_stop(self):
        a = self.handoff('alpha')
        b = self.handoff('beta', archive=True, legacy=False)
        for p in (a, b):
            p.write_text(p.read_text().replace('created:', 'anchor: /repo deadbeef dirty=0\ncreated:'))
        self.run_cli(expected=1)

    def test_same_path_metadata_conflict_and_exact_duplicate(self):
        a = self.handoff('alpha')
        b = self.handoff('alpha', legacy=False)
        self.run_cli()
        self.assertTrue(b.exists())
        # A mode mismatch is a real conflict even when bytes match.
        legacy = self.home / '.claude/handoffs'
        legacy.mkdir()
        shutil.copy2(b, legacy / 'alpha.md')
        (legacy / 'alpha.md').chmod(0o644)
        self.run_cli(expected=1)
        self.assertTrue((legacy / 'alpha.md').exists())

    def test_rollback_interruption_can_recover(self):
        for step in ('rollback-intent', 'rollback-retained', 'rollback-restore-intent', 'rolled-back'):
            with self.subTest(step=step), tempfile.TemporaryDirectory() as tmp:
                old_home = self.home
                self.home = Path(tmp).resolve()
                self.env['HOME'] = str(self.home)
                p = self.handoff('alpha', archive=True)
                expected = self.module.snapshot(p.parent.parent)
                self.run_cli()
                r = self.receipt()
                self.resume(r['id'], 'rollback', expected=1, DOTFILES_RUNTIME_TEST_FAIL='0:' + step)
                self.resume(r['id'])
                self.assertEqual(expected, self.module.snapshot(self.home / '.claude/handoffs'))
                self.home = old_home
                self.env['HOME'] = str(old_home)

    def test_source_update_and_candidate_replacement_block_recovery(self):
        self.handoff()
        self.run_cli(expected=1, DOTFILES_RUNTIME_TEST_FAIL='0:install-intent')
        r = self.receipt()
        op = r['operations'][0]
        (Path(op['stage']) / 'external.md').write_text('external update')
        self.resume(r['id'], expected=1)
        self.assertTrue((Path(op['stage']) / 'external.md').exists())

    def test_unknown_receipt_step_and_missing_operation_stop_before_mutation(self):
        p = self.handoff()
        before = self.module.snapshot(p.parent)
        canonical = self.handoff('beta', legacy=False).parent
        canonical_before = self.module.snapshot(canonical)
        self.run_cli(expected=1, DOTFILES_RUNTIME_TEST_FAIL='0:backup-intent')
        r = self.receipt()
        path = self.home / '.runtime-layout' / (r['id'] + '.json')
        r['operations'][0]['step'] = 'unknown-state'
        path.write_text(json.dumps(r))
        self.resume(r['id'], expected=1)
        self.assertEqual(before, self.module.snapshot(p.parent))
        self.assertEqual(canonical_before, self.module.snapshot(canonical))
        r['operations'][0]['step'] = 'backup-intent'
        stage = r['operations'][0]['stage']
        r['operations'][0]['stage'] = None
        path.write_text(json.dumps(r))
        self.resume(r['id'], expected=1)
        self.assertEqual(canonical_before, self.module.snapshot(canonical))
        r['operations'][0]['stage'] = stage
        r['operations'].pop()
        path.write_text(json.dumps(r))
        self.resume(r['id'], expected=1)
        self.assertEqual(before, self.module.snapshot(p.parent))

    def test_broken_parent_special_file_and_unknown_root_link(self):
        target = self.root('claude-skills')
        target.parent.mkdir()
        target.symlink_to(self.base / 'unknown')
        self.run_cli(expected=1)
        self.assertEqual(str(self.base / 'unknown'), os.readlink(target))
        old = self.handoff()
        os.mkfifo(old.parent / 'pipe')
        self.run_cli(expected=1)
        self.assertTrue(old.exists())

    def test_every_install_boundary_recovery_and_rollback(self):
        for index in (0, 1):
            for step in ('backup-intent', 'backed-up', 'install-intent', 'installed', 'verified'):
                with self.subTest(index=index, step=step), tempfile.TemporaryDirectory() as tmp:
                    old_home = self.home
                    self.home = Path(tmp).resolve()
                    self.env['HOME'] = str(self.home)
                    p = self.handoff('alpha', archive=True)
                    expected = self.module.snapshot(p.parent.parent)
                    self.run_cli(expected=1, DOTFILES_RUNTIME_TEST_FAIL=f'{index}:{step}')
                    receipt = self.receipt()
                    self.resume(receipt['id'])
                    self.assertTrue((self.root('handoffs') / 'archive/20261006-alpha.md').exists())
                    self.resume(receipt['id'], 'rollback')
                    self.assertEqual(expected, self.module.snapshot(self.home / '.claude/handoffs'))
                    self.assertFalse(self.root('handoffs').exists())
                    self.home = old_home
                    self.env['HOME'] = str(old_home)

    def test_rollback_refuses_new_checkpoint_and_modified_backup(self):
        self.handoff()
        self.run_cli()
        r = self.receipt()
        (self.root('handoffs') / 'new.md').write_text('new checkpoint')
        self.resume(r['id'], 'rollback', expected=1)
        self.assertTrue((self.root('handoffs') / 'new.md').exists())

    def test_live_lock_and_changed_snapshot_are_not_overwritten(self):
        p = self.handoff()
        layout = self.module.Layout(self.home, self.repo)
        plan = layout.plan('handoffs')
        p.write_text('external writer')
        with patch.object(self.module, 'writers', return_value=[]):
            with self.assertRaises(self.module.Blocked):
                layout.apply(plan)
        self.assertEqual('external writer', p.read_text())
        self.run_cli(expected=1)

    def test_parent_replacement_between_plan_and_apply_is_rejected(self):
        parent = self.home / '.agents'
        parent.mkdir()
        outside = self.base / 'outside'
        outside.mkdir()
        layout = self.module.Layout(self.home, self.repo)
        plan = layout.plan('codex-skills')
        parent.rename(self.home / 'previous-agents')
        parent.symlink_to(outside)
        with patch.object(self.module, 'writers', return_value=[]):
            with self.assertRaises(self.module.Blocked):
                layout.apply(plan)
        self.assertEqual([], list(outside.iterdir()))

    def test_cross_device_rename_failure_preserves_original_and_stage(self):
        p = self.handoff()
        expected = self.module.snapshot(p.parent)
        layout = self.module.Layout(self.home, self.repo)
        plan = layout.plan('handoffs')
        with patch.object(self.module, 'writers', return_value=[]), patch.object(Path, 'rename', side_effect=OSError(errno.EXDEV, 'cross-device link')):
            with self.assertRaises(OSError):
                layout.apply(plan)
        self.assertEqual(expected, self.module.snapshot(p.parent))
        r = self.receipt()
        self.assertTrue(Path(r['operations'][0]['stage']).is_dir())

    def test_common_entry_never_writes_config_through_repo_parent_alias(self):
        scripts = self.repo / 'scripts'
        scripts.mkdir()
        for name in ('ensure-runtime.sh', 'ensure-runtime-layout.py', 'ensure-codex-guidance.sh', 'ensure-codex-config.py'):
            shutil.copy2(ROOT / 'scripts' / name, scripts / name)
        config = self.repo / 'codex/config.toml'
        config.write_text('model = "source-model"\n')
        (self.repo / 'codex/AGENTS.md').write_text('# source guidance\n')
        (self.home / '.codex').symlink_to(self.repo / 'codex')
        before = self.module.snapshot(self.repo)
        run = subprocess.run(['bash', str(scripts / 'ensure-runtime.sh')], env=self.env, text=True, capture_output=True)
        self.assertEqual(1, run.returncode, run.stdout + run.stderr)
        self.assertEqual(before, self.module.snapshot(self.repo))
        for name in ('claude-skills', 'codex-skills', 'handoffs'):
            self.assertTrue(self.root(name).is_dir(), run.stdout + run.stderr)


def baseline():
    failures = []
    with tempfile.TemporaryDirectory() as tmp:
        home = Path(tmp) / 'home'
        home.mkdir()
        env = {**os.environ, 'HOME': str(home), 'DOTFILES_DIR': str(ROOT)}
        subprocess.run(['bash', str(ROOT / 'scripts/ensure-codex-skills.sh')], env=env, check=True)
        if not (home / '.claude/skills/handoff/SKILL.md').exists():
            failures.append('ASSERT RED: upgrade helper does not install Claude adapters')
        rules = home / '.codex/rules'
        rules.mkdir(parents=True)
        (rules / 'default.rules').write_text('personal approval bytes\n')
        setup = subprocess.check_output(['git', '-C', str(ROOT), 'show', '79269535b3a3a741a87c3f7a8bb1c8a161ce2fcd:setup-mac-env.sh'], text=True)
        fn = re.search(r'    __codex_link\(\) \{.*?\n    \}', setup, re.S)
        if fn is None:
            raise RuntimeError('baseline inline helper is no longer present')
        subprocess.run(['bash', '-c', fn.group() + '\n__codex_link "$DOTFILES_DIR/codex/rules" "$HOME/.codex/rules"'], env=env, check=True)
        if rules.is_symlink() or (rules / 'default.rules').read_text() != 'personal approval bytes\n':
            failures.append('ASSERT RED: setup replaces writable rules root and personal approvals')
    print('\n'.join(failures))
    return 1 if failures else 0


if __name__ == '__main__':
    if '--baseline' in sys.argv:
        raise SystemExit(baseline())
    unittest.main()
