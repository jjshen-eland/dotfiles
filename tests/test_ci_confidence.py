"""Isolated regressions for CI gates and fleet-script failure contracts."""
import os
import json
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Sandbox(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='ci-confidence-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.home = self.base / 'home'
        self.bin = self.base / 'bin'
        self.home.mkdir(); self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        self.env.pop('BASH_ENV', None)
        self.env.pop('ENV', None)

    def stub(self, name, body):
        p = self.bin / name
        p.write_text('#!/bin/bash\n' + body)
        p.chmod(0o755)
        return p

    def call(self, script, *args, **env):
        return subprocess.run(['bash', str(ROOT / 'scripts' / script), *map(str, args)],
                              env={**self.env, **env}, capture_output=True, text=True, timeout=10)


class HostsTests(Sandbox):
    def test_bad_markers_preserve_file(self):
        for payload in ['# pilot-infra-start\nold\n', '# pilot-infra-end\n',
                        '# pilot-infra-start\n# pilot-infra-start\n# pilot-infra-end\n',
                        '# pilot-infra-end\n# pilot-infra-start\n']:
            with self.subTest(payload=payload):
                p = self.base / 'hosts'; p.write_text('127.0.0.1 localhost\n' + payload + '192.0.2.9 preserve\n')
                before = p.read_bytes()
                r = self.call('render-etc-hosts.sh', '--apply', p, INVENTORY_FILE=str(ROOT / 'tests/fixtures/inventory.conf'))
                self.assertNotEqual(r.returncode, 0, r.stdout)
                self.assertEqual(p.read_bytes(), before)

    def test_valid_blocks_are_idempotent_and_preserve_unmanaged_lines(self):
        p = self.base / 'hosts'
        p.write_text('127.0.0.1 localhost\n# pilot-infra-start\nold\n# pilot-infra-end\n192.0.2.9 preserve\n')
        for _ in range(2):
            r = self.call('render-etc-hosts.sh', '--apply', p, INVENTORY_FILE=str(ROOT / 'tests/fixtures/inventory.conf'))
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('192.0.2.9 preserve', p.read_text())
            self.assertNotIn('\nold\n', p.read_text())
            if _ == 0: once = p.read_bytes()
            else: self.assertEqual(p.read_bytes(), once)

    def test_remote_payload_uses_same_guard_and_render(self):
        p = self.base / 'hosts'; p.write_text('localhost\n# pilot-infra-start\nunmanaged\n')
        self.stub('ssh', 'cat > "$PAYLOAD"\n')
        payload = self.base / 'remote.sh'
        r = self.call('render-etc-hosts.sh', '--remote', 'fixture', INVENTORY_FILE=str(ROOT / 'tests/fixtures/inventory.conf'), PAYLOAD=str(payload))
        self.assertEqual(r.returncode, 0, r.stderr)
        # Execute the actual transported script, redirecting only its system target.
        body = payload.read_text().replace('TARGET=/etc/hosts', 'TARGET=' + str(p))
        r = subprocess.run(['bash', '-s'], input=body, env=self.env, text=True, capture_output=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(p.read_text(), 'localhost\n# pilot-infra-start\nunmanaged\n')
        p.write_text('localhost\n# pilot-infra-start\nold\n# pilot-infra-end\npreserve\n')
        r = subprocess.run(['bash', '-s'], input=body, env=self.env, text=True, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('10.0.0.10', p.read_text()); self.assertIn('preserve', p.read_text())


class AllUpTests(Sandbox):
    def test_stage_failures_and_platform_controls(self):
        scripts = self.home / '.dotfiles/scripts'; scripts.mkdir(parents=True)
        log = self.base / 'calls'
        for name in ['brewup', 'sysup']:
            p = scripts / (name + '.sh')
            p.write_text('#!/bin/bash\necho ' + name + ' >> "$CALLS"\nexit "${' + name.upper() + '_RC:-0}"\n')
            p.chmod(0o755)
        self.stub('uname', 'echo "$OS"\n')
        self.stub('sudo', 'exit "${SUDO_RC:-0}"\n')
        self.stub('ssh', 'last="${!#}"\nif [ "$last" = "uname -s" ]; then echo "$OS"; else echo target >> "$CALLS"; exec bash -c "$last"; fi\n')
        for os_name, brew, sysup, sudo, expected in [('Linux',42,0,0,1),('Linux',42,0,1,1),
                ('Linux',0,43,0,1),('Linux',0,0,0,0),('Linux',0,43,1,0),('Darwin',42,0,0,1),('Darwin',0,43,0,0)]:
            with self.subTest(os=os_name,brew=brew,sysup=sysup,sudo=sudo):
                log.write_text('')
                r = self.call('all-up.sh','one','two',OS=os_name,BREWUP_RC=str(brew),SYSUP_RC=str(sysup),SUDO_RC=str(sudo),CALLS=str(log))
                self.assertEqual(r.returncode, expected, r.stdout + r.stderr)
                self.assertEqual(log.read_text().splitlines().count('target'), 2)
                self.assertEqual(log.read_text().splitlines().count('sysup'), 2 if os_name == 'Linux' and sudo == 0 else 0)
        self.stub('ssh', 'for arg in "$@"; do [ "$arg" != bad ] || exit 1; done\nlast="${!#}"\nif [ "$last" = "uname -s" ]; then echo "$OS"; else echo target >> "$CALLS"; exec bash -c "$last"; fi\n')
        log.write_text('')
        r = self.call('all-up.sh','bad','good',OS='Linux',BREWUP_RC='0',SYSUP_RC='0',SUDO_RC='0',CALLS=str(log))
        self.assertEqual(r.returncode,1,r.stdout+r.stderr)
        self.assertIn('1 成功',r.stdout); self.assertIn('1 失敗',r.stdout)
        self.assertEqual(log.read_text().splitlines(),['target','brewup','sysup'])
        self.stub('ssh', 'exit 1\n')
        r = self.call('all-up.sh','one','two',OS='Linux',CALLS=str(log))
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('2 失敗', r.stdout)


class SigningTests(Sandbox):
    def test_partial_and_total_failures_and_success(self):
        fixture = self.base / 'repo'; shutil.copytree(ROOT / 'scripts', fixture / 'scripts')
        (fixture / 'ssh').mkdir(); (fixture / 'ssh/user_ca.pub').write_text('fixture-only')
        for key in ['hostca/host_ca_key','userca/user_ca_key']:
            p = self.home / 'Documents/shell/security/ssh/sshca' / key
            p.parent.mkdir(parents=True, exist_ok=True); p.write_text('fixture-only')
        self.stub('ssh-keygen', 'case "$FAIL_STAGE" in sign) exit 1;; esac\nlast="${!#}"; echo fixture-cert > "${last%.pub}-cert.pub"\n')
        self.stub('scp', '''echo "scp $*" >> "$CALLS"
case "$FAIL_STAGE:$*" in retrieve:*:~/.ssh/id_autogen.pub*) exit 1;; upload:*cert.pub*) exit 1;; user-ca:*/tmp/user_ca.pub*) exit 1;; esac
case "$1" in *:*) echo fixture-public > "$2";; esac
exit 0
''')
        self.stub('ssh', '''echo "ssh $*" >> "$CALLS"
if [ "$1" = -G ]; then echo "hostname fixture"; exit 0; fi
host="$1"; cmd="$2"
[ "$FAIL_STAGE" = connect ] && exit 1
[ "$host" = bad ] && exit 1
case "$cmd" in
  'cat /etc/ssh/'*) echo fixture-public;;
  'echo y | ssh-keygen'*) [ "$FAIL_STAGE" != generate ] || exit 1;;
  chmod*) [ "$FAIL_STAGE" != permissions ] || exit 1;;
  *) printf '%s\n' "$cmd" > "$PAYLOAD"; [ "$FAIL_STAGE" != deploy ] || exit 1; echo OK;;
esac
''')
        log = self.base / 'calls'
        for name, stages in [('sign-host-keys.sh',['connect','sign','upload','user-ca','deploy']),
                             ('sign-user-key.sh',['connect','generate','retrieve','sign','upload','permissions'])]:
            for stage, hosts, expected, count in [('none',['good','good2'],0,'成功 2 / 失敗 0'),
                    ('none',['bad','good'],1,'成功 1 / 失敗 1')] + [(s,['good','good2'],1,'成功 0 / 失敗 2') for s in stages]:
                with self.subTest(script=name,stage=stage,hosts=hosts):
                    log.write_text('')
                    r = subprocess.run(['bash',str(fixture/'scripts'/name),*hosts],env={**self.env,'FAIL_STAGE':stage,'CALLS':str(log),'PAYLOAD':str(self.base/'deploy.sh')},capture_output=True,text=True,timeout=10)
                    self.assertEqual(r.returncode, expected, r.stdout + r.stderr)
                    self.assertIn(count, r.stdout)
                    self.assertIn('good2' if hosts[-1]=='good2' else 'good', log.read_text())


        # Run the actual transported deployment body. Every privileged operation is a stub.
        config = self.base/'sshd'; config.mkdir(); (config/'sshd_config').write_text('')
        user_ca = self.base/'user_ca.pub'; user_ca.write_text('fixture')
        body = (self.base/'deploy.sh').read_text().replace('/etc/ssh',str(config)).replace('/tmp/user_ca.pub',str(user_ca))
        self.stub('systemctl', ':\n')
        self.stub('sudo', '[ "$1" != "$FAIL_SUDO" ] || exit 42\nexit 0\n')
        for failed in ['none','cp','mv','chown','chmod','systemctl']:
            with self.subTest(remote_deploy_stage=failed):
                r = subprocess.run(['bash','-c',body],env={**self.env,'FAIL_SUDO':failed},capture_output=True,text=True,timeout=10)
                self.assertEqual(r.returncode==0,failed=='none',r.stdout+r.stderr)
                self.assertEqual('OK' in r.stdout,failed=='none',r.stdout)



        (self.home/'.ssh').mkdir()
        self.stub('ssh-keygen', """if [ "$1" = -s ]; then
  last="${!#}"
  [ "$last:$FAIL_STAGE" != "$HOME/.ssh/id_autogen.pub:local-sign" ] || exit 1
  echo cert > "${last%.pub}-cert.pub"
else
  [ "$FAIL_STAGE" != local-generate ] || exit 1
  while [ "$1" != -f ]; do shift; done
  echo private > "$2"; echo public > "$2.pub"
fi
""")
        self.stub('chmod', 'case "$FAIL_STAGE:$1" in local-mode600:600|local-mode644:644) exit 1;; esac\nexit 0\n')
        for stage in ['none','local-generate','local-sign','local-mode600','local-mode644']:
            with self.subTest(local_signing_stage=stage):
                log.write_text('')
                r = subprocess.run(['bash',str(fixture/'scripts/sign-user-key.sh'),'localhost','good'],
                    env={**self.env,'FAIL_STAGE':stage,'CALLS':str(log),'PAYLOAD':str(self.base/'unused.sh')},
                    capture_output=True,text=True,timeout=10)
                self.assertEqual(r.returncode,0 if stage=='none' else 1,r.stdout+r.stderr)
                self.assertIn('成功 2 / 失敗 0' if stage=='none' else '成功 1 / 失敗 1',r.stdout)
                self.assertIn('ssh good',log.read_text())



class GateTests(Sandbox):
    def test_lint_inputs_cover_original_files_once(self):
        source = (ROOT/'tests/run.sh').read_text()
        prefix = source[source.index('ROOT="$(cd'):source.index('FIX="$ROOT/tests/fixtures"')]
        command = source[source.index('shellcheck -x '):source.index('shellcheck_pid=$!')]
        capture = self.base/'argv.json'
        self.stub("shellcheck", "exec python3 -c 'import json,os,sys; open(os.environ[\"CAPTURE\"],\"w\").write(json.dumps(sys.argv[1:]))' \"$@\"\n")
        r = subprocess.run(['bash','-c',prefix+'\nTMP="$1"; shellcheck_out="$TMP/lint.out"\n'+command+'wait\n',str(ROOT/'tests/run.sh'),str(self.base)],
                           env={**self.env,'CAPTURE':str(capture)},capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stderr)
        args = json.loads(capture.read_text())[3:]
        actual = [str(Path(p).resolve()) for p in args]
        patterns = ['scripts/*.sh','scripts/lib/inventory.sh','claude/scripts/*.sh',
                    'shared/skills/*/scripts/*.sh','shared/skills/*/scripts/lib/*.sh',
                    'claude/skills/*/scripts/*.sh','claude/skills/*/scripts/lib/*.sh',
                    'codex/skills/*/scripts/*.sh','.githooks/dispatcher','shell/functions.sh',
                    'setup-mac-env.sh','setup-linux-env.sh','write-mac-defaults.sh','claude/evals/*.sh','tests/*.sh']
        expected = {str(p.resolve()) for pattern in patterns for p in ROOT.glob(pattern)}
        self.assertEqual(set(actual),expected,'dedup dropped a script or a runtime-specific wrapper')
        self.assertEqual(len(actual),len(set(actual)),'same canonical script scanned repeatedly')

    def test_ci_comment_cannot_replace_active_matrix(self):
        repo = self.base / 'repo'; (repo/'.github/workflows').mkdir(parents=True); (repo/'tests').mkdir()
        for name in ['run-parallel.sh','ci-contract.py']:
            if (ROOT/'tests'/name).exists(): shutil.copy(ROOT/'tests'/name,repo/'tests'/name)
        yaml=(ROOT/'.github/workflows/test.yml').read_text()
        source=(ROOT/'tests/run.sh').read_text()
        block=source[source.index('CI_FILE="$ROOT/.github/workflows/test.yml"'):source.index('# GitHub runners', source.index('CI_FILE="$ROOT/.github/workflows/test.yml"'))]
        for mutation, invalid in [(yaml,False),(yaml.replace('run: ./tests/run-parallel.sh','shell: bash\n        run: ./tests/run-parallel.sh'),False),
                (yaml.replace('run: ./tests/run-parallel.sh','shell: echo {0}\n        run: ./tests/run-parallel.sh'),True),
                (yaml.replace('  suite:\n','  suite:\n    defaults:\n      run:\n        shell: echo {0}\n'),True),
                (yaml.replace('jobs:\n','defaults:\n  run:\n    shell: echo {0}\njobs:\n'),True),
                (yaml.replace('jobs:\n','defaults:\n  run:\n    shell: echo {0}\njobs:\n').replace('  suite:\n','  suite:\n    defaults:\n      run:\n        shell: bash\n'),False),
                (yaml.replace('os: [macos-15, ubuntu-24.04]','os: [ubuntu-24.04, macos-15]'),False),
                (yaml.replace('os: [macos-15, ubuntu-24.04]','os: [ubuntu-24.04] # macos-15'),True),
                (yaml.replace('run: ./tests/run-parallel.sh','if: false\n        run: ./tests/run-parallel.sh'),True),
                (yaml.replace('contents: read','contents: write # contents: read'),True),
                (yaml.replace('run: brew install shellcheck ripgrep yq zsh','run: echo "brew install shellcheck ripgrep yq zsh"'),True),
                (yaml.replace('run: brew install shellcheck ripgrep yq zsh','continue-on-error: true\n        run: brew install shellcheck ripgrep yq zsh'),True)]:
            with self.subTest(invalid=invalid,mutation=mutation):
                (repo/'.github/workflows/test.yml').write_text(mutation)
                r=subprocess.run(['bash','-c','ROOT="$1"\nok(){ echo PASS; }; bad(){ echo FAIL; };\n'+block,'probe',str(repo)],env=self.env,capture_output=True,text=True)
                self.assertEqual('FAIL' in r.stdout,invalid,r.stdout+r.stderr)

    def test_heredoc_scanner_failure_fails_gate(self):
        actual=shutil.which('awk')
        self.stub('awk', 'for arg in "$@"; do case "$arg" in "$CI_ROOT"/scripts/*) exit 2;; esac; done\nexec "'+actual+'" "$@"\n')
        source=(ROOT/'tests/run.sh').read_text()
        block=source[source.index('HD_GATE="$ROOT/tests/heredoc-gate.awk"'):source.index('echo "▶ 1cc.')]
        r=subprocess.run(['bash','-c','shopt -s nullglob\nROOT="$1"; TMP="$2"\nok(){ echo PASS; }; bad(){ echo FAIL; };\n'+block,'probe',str(ROOT),str(self.base)],env={**self.env,'CI_ROOT':str(ROOT)},capture_output=True,text=True)
        self.assertIn('FAIL',r.stdout,r.stdout+r.stderr)

    def test_delimiter_indentation_matches_bash(self):
        for opener, body, finding in [('<<EOF','  EOF\n`printf EXECUTED`\nEOF\n',True),
                ('<<-EOF','  EOF\n`printf EXECUTED`\nEOF\n',True),
                ('<<-EOF','\tEOF\necho "`printf OUTSIDE`"\n',False),
                ("<<'EOF'",'`printf LITERAL`\nEOF\n',False)]:
            with self.subTest(opener=opener):
                p=self.base/'heredoc.sh'; p.write_text('cat '+opener+'\n'+body)
                r=subprocess.run(['awk','-f',str(ROOT/'tests/heredoc-gate.awk'),str(p)],capture_output=True,text=True)
                self.assertEqual(r.returncode,0,r.stderr)
                self.assertEqual(bool(r.stdout),finding,r.stdout)


class ParallelTests(Sandbox):
    def alive(self,pid):
        r=subprocess.run(['ps','-o','stat=','-p',str(pid)],capture_output=True,text=True)
        return r.returncode==0 and bool(r.stdout.strip()) and not r.stdout.strip().startswith('Z')

    def test_supervisor_signal_during_spawn_does_not_orphan_shard(self):
        fixture = self.base/'startup'; (fixture/'tests').mkdir(parents=True)
        results = fixture/'results'; results.mkdir()
        script = fixture/'tests/run.sh'; script.write_text('#!/bin/bash\nexec sleep 30\n'); script.chmod(0o755)
        pidfile = fixture/'pid'
        # Deliver TERM after the OS creates the child, before Popen returns to its caller.
        probe = """import os,runpy,signal,subprocess
from pathlib import Path
real = subprocess.Popen
def spawn(*args,**kwargs):
    process = real(*args,**kwargs)
    Path(os.environ['PIDFILE']).write_text(str(process.pid))
    os.kill(os.getpid(),signal.SIGTERM)
    return process
subprocess.Popen = spawn
runpy.run_path(os.environ['SUPERVISOR'],run_name='__main__')
"""
        try:
            r = subprocess.run(['python3','-c',probe,str(fixture),str(results),'core'],
                env={**self.env,'PIDFILE':str(pidfile),'SUPERVISOR':str(ROOT/'tests/shard-supervisor.py')},
                capture_output=True,text=True,timeout=4)
            self.assertNotEqual(r.returncode,0)
            self.assertFalse(self.alive(int(pidfile.read_text())),'signal during spawn orphaned shard')
        finally:
            if pidfile.exists():
                try: os.killpg(int(pidfile.read_text()),signal.SIGKILL)
                except ProcessLookupError: pass

    def test_actual_runner_cleans_process_trees(self):
        shards = {line.split('\t')[0] for line in (ROOT/'tests/shard-manifest.tsv').read_text().splitlines()
                  if line.strip() and not line.startswith('#')}
        for trigger in [signal.SIGTERM,signal.SIGINT,'child']:
            with self.subTest(trigger=trigger):
                fixture=self.base/str(trigger); (fixture/'tests').mkdir(parents=True)
                for name in ['run-parallel.sh','shard-supervisor.py','shard-aggregate.py','shard-manifest.tsv']:
                    if (ROOT/'tests'/name).exists(): shutil.copy(ROOT/'tests'/name,fixture/'tests'/name)
                script=fixture/'tests/run.sh'
                script.write_text('''#!/bin/bash
python3 -c 'import os,signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); open(os.environ["PID_DIR"]+"/"+os.environ["DOTFILES_TEST_SHARD"],"w").write(str(os.getpid())); time.sleep(30)' &
if [ "$TRIGGER" = child ] && [ "$DOTFILES_TEST_SHARD" = core ]; then
  while [ "$(ls "$PID_DIR" | wc -l | tr -d ' ')" -lt "$EXPECTED_SHARDS" ]; do sleep 0.02; done
  kill -TERM "$$"
fi
wait
'''); script.chmod(0o755)
                pids=fixture/'pids'; pids.mkdir()
                proc=subprocess.Popen(['bash',str(fixture/'tests/run-parallel.sh')],env={**self.env,'PID_DIR':str(pids),'TRIGGER':str(trigger),'EXPECTED_SHARDS':str(len(shards))},stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
                try:
                    deadline=time.monotonic()+8
                    while len(list(pids.iterdir()))<len(shards) and time.monotonic()<deadline: time.sleep(.02)
                    self.assertEqual({p.name for p in pids.iterdir()},shards)
                    if trigger!='child': os.kill(proc.pid,trigger)
                    proc.wait(timeout=6)
                    self.assertNotEqual(proc.returncode,0)
                    live=[int(p.read_text()) for p in pids.iterdir() if self.alive(int(p.read_text()))]
                    self.assertEqual(live,[],'runner left live descendants')
                finally:
                    # Only fixture-owned pids/groups are touched, even on the RED baseline.
                    if proc.poll() is None: proc.kill(); proc.wait()
                    for p in pids.iterdir():
                        pid=int(p.read_text())
                        try: os.kill(pid,signal.SIGKILL)
                        except ProcessLookupError: pass
                    try: os.killpg(proc.pid,signal.SIGKILL)
                    except ProcessLookupError: pass


if __name__=='__main__':
    unittest.main()
