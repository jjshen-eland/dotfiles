"""Behavior controls for the module runner and impact selection."""
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Selection(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('suite', ROOT / 'tests/suite.py')
        cls.suite = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.suite)
        cls.manifest = cls.suite.load_manifest(ROOT)

    def test_unknown_and_shared_inputs_run_full(self):
        for path in ['unknown.py', 'tests/suite.py', '.github/workflows/test.yml', 'shell/functions.sh']:
            with self.subTest(path=path):
                names, _ = self.suite.select_paths(self.manifest, [path])
                self.assertEqual(set(names), set(self.manifest['modules']))

    def test_small_script_selects_its_behavior_and_content(self):
        names, _ = self.suite.select_paths(self.manifest, ['scripts/brewup.sh'])
        self.assertIn('deployment', names)
        self.assertIn('content', names)
        self.assertIn('lint', names)
        self.assertNotIn('deep-plan', names)
        self.assertNotIn('review-controller', names)

    def test_script_with_its_regression_test_keeps_module_scope(self):
        names,_=self.suite.select_paths(self.manifest,['scripts/brewup.sh','tests/modules/deployment.sh','README.md'])
        self.assertIn('deployment',names)
        self.assertNotIn('deep-plan',names)
        self.assertNotIn('review-controller',names)

    def test_mixed_batch_is_union_not_last_file(self):
        paths = ['scripts/brewup.sh', 'shared/skills/check-crawl-quality/scripts/crawl-quality-scan.py']
        actual, _ = self.suite.select_paths(self.manifest, paths)
        expected = set()
        for path in paths:
            expected.update(self.suite.select_paths(self.manifest, [path])[0])
        self.assertEqual(set(actual), expected)
        self.assertIn('crawl-quality', actual)

    def select(self, *paths):
        return set(self.suite.select_paths(self.manifest, list(paths))[0])

    def test_module_scripts_select_modules_that_read_them(self):
        # ci-regression reads these module bodies; platform greps every module body.
        for path in ['tests/modules/lint.sh', 'tests/modules/platform.sh', 'tests/modules/shell-contract.sh']:
            with self.subTest(path=path):
                self.assertIn('ci-regression', self.select(path))
        for path in ['tests/modules/deployment.sh', 'tests/modules/hooks.sh']:
            with self.subTest(path=path):
                self.assertLessEqual({'platform', 'shell-contract'}, self.select(path))

    def test_brewup_selects_hooks_that_inspect_it(self):
        # hooks asserts brewup.sh still invokes the auto-mode drift check.
        self.assertIn('hooks', self.select('scripts/brewup.sh'))

    def test_runner_contract_and_shared_shell_inputs_stay_full(self):
        for path in ['tests/suites.json', 'tests/run-ci.py', 'tests/module-shell.sh', 'tests/shell-gate-files.py',
                     'AGENTS.md', 'claude/CLAUDE.md', 'shell/environment.sh']:
            with self.subTest(path=path):
                self.assertEqual(self.select(path), set(self.manifest['modules']))

    def test_owned_inputs_skip_unrelated_controllers(self):
        heavy = {'deep-plan', 'review-controller', 'ship-state', 'turbo'}
        cases = {
            'docs/testing-contract.md': {'content', 'document-contract'},
            'tests/test_dev_environment.py': {'dev-environment'},
            'scripts/dev-tools.sh': {'dev-environment'},
            'tests/runtime-layout.py': {'runtime-layout'},
            'tests/test_mac_metadata.py': {'mac-metadata'},
            'claude/known-hazards.md': {'content', 'guidance'},
        }
        for path, required in cases.items():
            with self.subTest(path=path):
                names = self.select(path)
                self.assertLessEqual(required, names)
                self.assertFalse(heavy & names, sorted(heavy & names))

    def test_manifest_rejects_unowned_shell_modules(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/'tests/modules').mkdir(parents=True)
            (root/'tests/modules/unlisted.sh').write_text(':\n')
            (root/'tests/suites.json').write_text(json.dumps({'modules':{},'routes':[]}))
            with self.assertRaises(ValueError): self.suite.load_manifest(root)

    def test_manifest_rejects_invalid_ci_platforms(self):
        for value in ([], ['Windows'], 'Linux', ['Linux', 'Linux']):
            with self.subTest(value=value), tempfile.TemporaryDirectory() as tmp:
                root=Path(tmp); (root/'tests/modules').mkdir(parents=True)
                (root/'tests/suites.json').write_text(json.dumps({'modules':{'m':{'command':['true'],
                    'ci_platforms':value}},'routes':[]}))
                with self.assertRaises(ValueError): self.suite.load_manifest(root)

    def test_ci_platform_restrictions_follow_recorded_evidence(self):
        # D-20261010-ci-controller-platform-evidence: deep-plan has macOS-only launcher defects.
        restricted = {n: e['ci_platforms'] for n, e in self.manifest['modules'].items() if 'ci_platforms' in e}
        self.assertEqual(restricted, {'review-controller': ['Linux'], 'turbo': ['Linux'], 'ship-state': ['Linux']})
        workflow = (ROOT/'.github/workflows/test.yml').read_text()
        matrix = re.search(r'^\s*os: \[(.*)\]$', workflow, re.M).group(1).split(', ')
        systems = {{'ubuntu': 'Linux', 'macos': 'Darwin'}[os_name.split('-')[0]] for os_name in matrix}
        self.assertEqual(systems, {'Linux', 'Darwin'})
        for name, platforms in restricted.items():
            self.assertLessEqual(set(platforms), systems, name)

    def test_local_runner_ignores_ci_platforms(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/'tests/modules').mkdir(parents=True)
            (root/'tests/suites.json').write_text(json.dumps({'modules':{'m':{'command':['{python}','-c','pass'],
                'ci_platforms':['Linux' if sys.platform == 'darwin' else 'Darwin']}},'routes':[]}))
            result=subprocess.run([sys.executable,'-B',str(ROOT/'tests/suite.py'),'--root',str(root)],
                                  capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn('"name": "m"',result.stdout)

    def test_local_impact_includes_commits_index_worktree_and_aliases(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            def git(*args):
                return subprocess.check_output(['git','-C',str(root),*args],text=True,
                    env={**os.environ,'DOTFILES_PRECOMMIT_OFF':'1'})
            git('init','-q','-b','test/impact');git('config','user.name','test');git('config','user.email','test@example.invalid')
            for name in ('a','b','c'): (root/name).write_text('before')
            (root/'alias').symlink_to('c')
            git('add','a','b','c','alias');git('commit','-qm','base');base=git('rev-parse','HEAD').strip()
            (root/'a').write_text('committed');git('add','a');git('commit','-qm','change')
            (root/'b').write_text('index');git('add','b')
            (root/'c').write_text('worktree')
            self.assertEqual(set(self.suite.local_paths(root,base)),{'a','b','c','alias'})
            (root/'d').write_text('added');git('add','d');git('rm','-q','a')
            self.assertEqual(set(self.suite.local_paths(root,base)),{'a','b','c','d','alias'})
            (root/'b').chmod(0o755)
            with self.assertRaises(ValueError): self.suite.local_paths(root,base)


class Execution(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);(self.root/'tests/modules').mkdir(parents=True)

    def run_fixture(self, bodies, *args):
        modules={}
        for name, body in bodies.items():
            script=self.root/'tests'/f'{name}.py';script.write_text(body)
            modules[name]={'command':['{python}', str(script)]}
        (self.root/'tests/suites.json').write_text(json.dumps({'modules':modules,'routes':[]}))
        return subprocess.run([sys.executable,str(ROOT/'tests/suite.py'),'--root',str(self.root),*args],capture_output=True,text=True,timeout=10)

    def test_failed_module_cannot_be_hidden_by_later_success(self):
        r=self.run_fixture({'bad':'raise SystemExit(7)','good':'print("done")'},'--jobs','1')
        self.assertNotEqual(r.returncode,0,r.stdout+r.stderr)
        self.assertIn('"passed": false',r.stdout)

    def test_unknown_empty_and_duplicate_selection_are_not_success(self):
        for args in [('--module','absent'),('--module','ok','--module','ok')]:
            r=self.run_fixture({'ok':'print("done")'},*args)
            self.assertNotEqual(r.returncode,0)
        r=self.run_fixture({})
        self.assertNotEqual(r.returncode,0)

    def test_each_selected_module_runs_once_and_reports_time(self):
        r=self.run_fixture({'one':'print("one")','two':'print("two")'},'--jobs','2')
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        rows=[json.loads(s.partition(' ')[2]) for s in r.stdout.splitlines() if s.startswith('TEST_MODULE ')]
        self.assertEqual({x['name'] for x in rows},{'one','two'})
        self.assertEqual(len(rows),2)
        self.assertTrue(all(x['passed'] and x['seconds'] >= 0 for x in rows))


    def test_shell_completion_and_source_failure_are_enforced(self):
        import shutil
        shutil.copy(ROOT/'tests/module-shell.sh',self.root/'tests/module-shell.sh')
        catalog={'modules':{'probe':{'shell':True,'command':['bash','tests/module-shell.sh','probe']}},'routes':[]}
        (self.root/'tests/suites.json').write_text(json.dumps(catalog))
        for body,success in [('exit 0\n',False),('ok started; return 2\n',False),
                             ('ok started; bad failure\n',False),('ok finished\n',True)]:
            with self.subTest(body=body):
                (self.root/'tests/modules/probe.sh').write_text(body)
                result=subprocess.run([sys.executable,str(ROOT/'tests/suite.py'),'--root',str(self.root)],
                    capture_output=True,text=True,timeout=5)
                self.assertEqual(result.returncode==0,success,result.stdout+result.stderr)

    def test_completed_process_group_is_not_signalled_again(self):
        from unittest import mock
        spec=importlib.util.spec_from_file_location('runner',ROOT/'tests/suite.py')
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        seen=set();real=module.kill_group
        def once(process,sig):
            if process.pid in seen:
                raise PermissionError('completed process group no longer belongs to this run')
            seen.add(process.pid);real(process,sig)
        manifest={'modules':{'ok':{'command':['{python}','-c','pass']}}}
        with mock.patch.object(module,'kill_group',side_effect=once):
            self.assertEqual(module.execute(self.root,manifest,['ok']),0)

    def test_cancellation_and_normal_exit_clean_descendants(self):
        for mode in ('term', 'int', 'normal', 'failure'):
            with self.subTest(mode=mode):
                pidfile=self.root/'pid'; pidfile.unlink(missing_ok=True)
                script=self.root/'tests/child.py'
                script.write_text("import subprocess,sys,time\n"
                    + "subprocess.Popen([sys.executable,'-c', "
                    + repr("import os,signal,time; from pathlib import Path; signal.signal(signal.SIGTERM,signal.SIG_IGN); Path("+repr(str(pidfile))+").write_text(str(os.getpid())); time.sleep(30)") + "])\n"
                    + "from pathlib import Path\n"
                    + "while not Path("+repr(str(pidfile))+").exists(): time.sleep(.01)\n"
                    + ("time.sleep(30)\n" if mode in ('term','int') else "raise SystemExit("+str(7 if mode=='failure' else 0)+")\n"))
                manifest={'modules':{'child':{'command':['{python}',str(script)]}},'routes':[]}
                (self.root/'tests/suites.json').write_text(json.dumps(manifest))
                process=subprocess.Popen([sys.executable,str(ROOT/'tests/suite.py'),'--root',str(self.root)],
                    stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
                try:
                    deadline=time.monotonic()+5
                    while not pidfile.exists() and time.monotonic()<deadline: time.sleep(.01)
                    self.assertTrue(pidfile.exists())
                    if mode in ('term','int'): process.send_signal(signal.SIGTERM if mode=='term' else signal.SIGINT)
                    out,err=process.communicate(timeout=5)
                    self.assertEqual(process.returncode==0,mode=='normal',out+err)
                    state=subprocess.run(['ps','-o','stat=','-p',pidfile.read_text()],capture_output=True,text=True).stdout.strip()
                    self.assertTrue(not state or state.startswith('Z'),state)
                finally:
                    if process.poll() is None: process.kill();process.wait()
                    if pidfile.exists():
                        try: os.kill(int(pidfile.read_text()),signal.SIGKILL)
                        except ProcessLookupError: pass

    def test_interrupt_inside_spawn_registers_child_before_cleanup(self):
        script=self.root/'tests/child.py'; script.write_text('import time;time.sleep(30)')
        pidfile=self.root/'pid'
        (self.root/'tests/suites.json').write_text(json.dumps({'modules':{'child':{
            'command':['{python}',str(script)]}},'routes':[]}))
        probe="""import os,runpy,signal,subprocess,sys
from pathlib import Path
real=subprocess.Popen
pidfile=Path(sys.argv[1])
def spawn(*args,**kwargs):
    process=real(*args,**kwargs)
    pidfile.write_text(str(process.pid))
    os.kill(os.getpid(),signal.SIGTERM)
    return process
subprocess.Popen=spawn
sys.argv=[sys.argv[2], '--root', sys.argv[3]]
runpy.run_path(sys.argv[0],run_name='__main__')
"""
        result=subprocess.run([sys.executable,'-c',probe,str(pidfile),str(ROOT/'tests/suite.py'),str(self.root)],
            capture_output=True,text=True,timeout=5)
        self.assertNotEqual(result.returncode,0,result.stdout+result.stderr)
        state=subprocess.run(['ps','-o','stat=','-p',pidfile.read_text()],capture_output=True,text=True).stdout.strip()
        self.assertTrue(not state or state.startswith('Z'),state)


if __name__=='__main__': unittest.main(verbosity=2)
