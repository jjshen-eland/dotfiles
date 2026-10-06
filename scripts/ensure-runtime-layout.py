#!/usr/bin/env python3
"""Converge managed runtime roots without replacing unknown content.

Inventory/dry-run are read-only. Receipts and retained sibling backups support
explicit recovery/rollback; this tool never stops runtime processes itself.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import uuid


class Blocked(RuntimeError):
    pass


def exists(path):
    return os.path.lexists(path)


def snapshot(path, identity=True):
    """Do not follow links. Compare identity as well as bytes across mutations."""
    result = {}
    if not exists(path):
        return result

    def visit(p, rel):
        s = p.lstat()
        row = {'mode': stat.S_IMODE(s.st_mode), 'mtime_ns': s.st_mtime_ns}
        if identity:
            row.update(dev=s.st_dev, ino=s.st_ino)
        if stat.S_ISLNK(s.st_mode):
            row.update(kind='link', link=os.readlink(p))
        elif stat.S_ISREG(s.st_mode):
            row.update(kind='file', sha256=hashlib.sha256(p.read_bytes()).hexdigest())
        elif stat.S_ISDIR(s.st_mode):
            row['kind'] = 'dir'
        else:
            raise Blocked(f'special file: {p}')
        result[rel] = row
        if row['kind'] == 'dir':
            for child in sorted(p.iterdir()):
                visit(child, f'{rel}/{child.name}' if rel else child.name)
        after = p.lstat()
        if any(getattr(after, k) != getattr(s, k) for k in ('st_dev', 'st_ino', 'st_mode', 'st_size', 'st_mtime_ns', 'st_ctime_ns')):
            raise Blocked(f'changed while reading: {p}')

    visit(path, '')
    return result


def content_manifest(path):
    return {name: {k: v for k, v in row.items() if k in ('kind', 'link', 'sha256')}
            for name, row in snapshot(path).items()}


def pristine(path, source, repo):
    actual = content_manifest(path)
    if actual == content_manifest(source):
        return True
    rel = source.relative_to(repo).as_posix()
    log = subprocess.run(['git', '-C', str(repo), 'log', '--format=%H', '--', rel],
                         text=True, capture_output=True)
    if log.returncode:
        return False
    # Local history only: absent historical blobs remain unknown; never fetch.
    for commit in log.stdout.splitlines():
        tree = subprocess.run(['git', '-C', str(repo), 'ls-tree', '-rz', commit, '--', rel],
                              capture_output=True)
        if tree.returncode or not tree.stdout:
            continue
        candidate = {'': {'kind': 'dir'}} if source.is_dir() else {}
        valid = True
        for entry in tree.stdout.split(b'\0'):
            if not entry:
                continue
            meta, name = entry.split(b'\t', 1)
            mode, kind, oid = meta.split()
            name = os.fsdecode(name)
            suffix = name[len(rel):].lstrip('/')
            if kind != b'blob':
                valid = False
                break
            blob = subprocess.run(['git', '-C', str(repo), 'cat-file', 'blob', oid.decode()],
                                  capture_output=True)
            if blob.returncode:
                valid = False
                break
            if mode == b'120000':
                candidate[suffix] = {'kind': 'link', 'link': os.fsdecode(blob.stdout)}
            else:
                candidate[suffix] = {'kind': 'file', 'sha256': hashlib.sha256(blob.stdout).hexdigest()}
            parent = Path(suffix).parent
            while str(parent) != '.':
                candidate[parent.as_posix()] = {'kind': 'dir'}
                parent = parent.parent
        if valid and candidate == actual:
            return True
    return False


def safe_parents(path, home, repo):
    if not path.is_relative_to(home) or path == home:
        raise Blocked(f'target outside home: {path}')
    for parent in [path.parent, *path.parent.parents]:
        if exists(parent) and (parent.is_symlink() or not parent.is_dir()):
            raise Blocked(f'non-directory or aliased parent: {parent}')
        if parent.resolve().is_relative_to(repo):
            raise Blocked(f'parent enters source repository: {parent}')
        if parent == home:
            break


def same_source(path, source):
    return path.is_symlink() and path.resolve() == source.resolve() and source.exists()


def writers():
    ps = subprocess.run(['ps', '-axo', 'pid=,uid=,comm='], text=True, capture_output=True)
    if ps.returncode:
        raise Blocked('process inventory failed; close runtimes and retry from ordinary terminal')
    if not ps.stdout.strip():
        raise Blocked('empty process inventory')
    found = []
    for line in ps.stdout.splitlines():
        fields = line.strip().split(None, 2)
        if len(fields) != 3 or not fields[0].isdigit() or not re.fullmatch(r'-?\d+', fields[1]):
            raise Blocked('unparseable process inventory')
        pid, uid, command = fields
        if int(uid) == os.getuid() and re.match(r'^(codex|claude)(?:\b|[- ])', Path(command).name, re.I):
            found.append({'pid': int(pid), 'command': command,
                          'kind': 'daemon' if 'app-server-daemon' in command else 'runtime'})
    return found


def offline():
    found = writers()
    if found:
        raise Blocked('runtime writers present: ' + json.dumps(found, ensure_ascii=False) +
                      '; exit/stop their owning app normally, then inventory again from ordinary terminal')


def identities(path, rel):
    if not rel.endswith('.md'):
        return set(), None
    stem = Path(rel).stem
    slugs = {stem}
    if Path(rel).parts[0] == 'archive':
        match = re.match(r'^\d{8}-(.+)$', stem)
        if match:
            slugs = {match[1]}
            seconds = re.match(r'^\d{6}-(.+)$', match[1])
            if seconds:
                slugs.add(seconds[1])
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()
    if lines and lines[0] == '---':
        try:
            fm = lines[1:lines.index('---', 1)]
        except ValueError:
            raise Blocked(f'incomplete frontmatter: {path}')
        slugs.update(line[5:].strip() for line in fm if line.startswith('slug:'))
        anchors = tuple(line for line in fm if line.startswith('anchor:'))
        provenance = anchors + tuple(line for line in fm if line.startswith('created:')) if anchors else ()
    else:
        provenance = ()
    # Keep every filename interpretation: frontmatter cannot raise trust.
    return slugs, provenance or None


class Layout:
    def __init__(self, home, repo, codex_home=None):
        self.home, self.repo = home.resolve(), repo.resolve()
        self.codex = Path(codex_home).absolute() if codex_home else self.home / '.codex'
        # Config helper retains CODEX_HOME; layout does not silently redirect it.
        self.state = self.home / '.runtime-layout'
        self.targets = {'claude-skills': self.home / '.claude/skills',
                        'codex-skills': self.home / '.agents/skills',
                        'codex-rules': self.codex / 'rules',
                        'codex-legacy': self.codex / 'skills',
                        'handoffs': self.home / '.agents/handoffs'}
        self.legacy = self.home / '.claude/handoffs'

    def guard(self, path):
        # An explicit CODEX_HOME may be outside HOME; keep that configured boundary.
        anchor = self.home if path.is_relative_to(self.home) else self.codex.parent
        safe_parents(path, anchor, self.repo)
        if self.codex == self.repo or self.codex.is_relative_to(self.repo):
            raise Blocked('CODEX_HOME enters source repository')
        result = {}
        for parent in [path.parent, *path.parent.parents]:
            if exists(parent):
                s = parent.lstat()
                result[str(parent)] = [s.st_dev, s.st_ino, s.st_mode]
            else:
                result[str(parent)] = None
            if parent == anchor:
                break
        return result

    def plan(self, name):
        target = self.targets[name]
        parents = self.guard(target)
        before = snapshot(target)
        plan = {'name': name, 'target': str(target), 'inputs': {str(target): before},
                'links': {}, 'remove': [], 'empty': [], 'merge': [], 'replace': False,
                'legacy': None, 'parents': parents, 'changed': not before}
        if name == 'handoffs':
            return self.handoffs(plan)
        source = self.repo / ('claude/skills' if name == 'claude-skills' else
                              'codex/rules' if name == 'codex-rules' else 'codex/skills')
        if not source.is_dir() or source.is_symlink():
            raise Blocked(f'missing or aliased source root: {source}')
        plan['source'] = str(source)
        plan['inputs'][str(source)] = snapshot(source)
        if before and target.is_symlink():
            if not same_source(target, source):
                raise Blocked(f'unknown whole-root link: {target}')
            plan.update(replace=True, changed=True)
        elif before and not target.is_dir():
            raise Blocked(f'root is not a directory: {target}')
        if name == 'codex-legacy':
            plan['changed'] = plan['replace']
            if not before:
                return plan
            for entry in source.iterdir():
                old = target / entry.name
                if (entry / 'SKILL.md').is_file() and same_source(old, entry):
                    plan['remove'].append(entry.name)
            plan['changed'] |= bool(plan['remove'])
            return plan
        if name == 'codex-rules':
            entries = {('dotfiles.rules' if p.name == 'default.rules' else 'dotfiles-' + p.name): p
                       for p in source.iterdir() if p.is_file() and p.suffix == '.rules'}
            personal = target / 'default.rules'
            if not before or plan['replace']:
                plan['empty'].append('default.rules')
            elif exists(personal) and (personal.is_symlink() or not personal.is_file()):
                raise Blocked(f'personal rules must be writable regular file: {personal}')
            elif not exists(personal):
                plan['empty'].append('default.rules')
        else:
            entries = {p.name: p for p in source.iterdir() if p.is_dir() and (p / 'SKILL.md').is_file()}
        for key, entry in entries.items():
            current = target / key
            if not plan['replace'] and same_source(current, entry):
                continue
            if not plan['replace'] and exists(current):
                if current.is_symlink() or not pristine(current, entry, self.repo):
                    raise Blocked(f'unknown managed-name content: {current}')
            plan['links'][key] = str(entry)
        plan['changed'] |= bool(plan['links'] or plan['empty'])
        return plan

    def handoffs(self, plan):
        target = Path(plan['target'])
        safe_parents(self.legacy, self.home, self.repo)
        plan['parents'].update(self.guard(self.legacy))
        old = snapshot(self.legacy)
        plan['inputs'][str(self.legacy)] = old
        stores = []
        for p in (target, self.legacy):
            if exists(p):
                if p.is_symlink():
                    other = self.legacy if p == target else target
                    if not other.is_dir() or other.is_symlink() or p.resolve() != other.resolve():
                        raise Blocked(f'unknown handoff alias: {p}')
                elif not p.is_dir():
                    raise Blocked(f'handoff store is not a directory: {p}')
                stores.append(p.resolve())
        stores = list(dict.fromkeys(stores))
        plan['changed'] = not exists(target) or target.is_symlink() or bool(old)
        plan['replace'] = target.is_symlink()
        manifests = [snapshot(p, identity=False) for p in stores]
        for p, manifest in zip(stores, manifests):
            if any(row['kind'] == 'link' for row in manifest.values()):
                raise Blocked(f'handoff child symlink needs explicit safe mapping: {p}')
        if len(stores) == 2:
            left, right = manifests
            for rel in left.keys() & right.keys():
                if rel == '':
                    continue
                if left[rel] != right[rel]:
                    raise Blocked(f'handoff path conflict: {rel}')
            for a in (r for r in left if r.endswith('.md')):
                ai, ap = identities(stores[0] / a, a)
                for b in (r for r in right if r.endswith('.md') and r != a):
                    bi, bp = identities(stores[1] / b, b)
                    if ai & bi or (ap is not None and ap == bp) or left[a].get('sha256') == right[b].get('sha256'):
                        raise Blocked(f'handoff workline/provenance conflict: {a} / {b}')
        plan['merge'] = [str(p) for p in stores]
        if old:
            plan['legacy'] = str(self.legacy)
        return plan

    def state_dir(self):
        safe_parents(self.state / 'placeholder', self.home, self.repo)
        if exists(self.state) and (self.state.is_symlink() or not self.state.is_dir()):
            raise Blocked('aliased state directory')
        self.state.mkdir(mode=0o700, exist_ok=True)

    def apply(self, plan):
        if not plan['changed']:
            return {'status': 'unchanged', 'name': plan['name']}
        current_parents = self.guard(Path(plan['target']))
        if plan['name'] == 'handoffs':
            current_parents.update(self.guard(self.legacy))
        if current_parents != plan['parents']:
            raise Blocked('parent identity changed since inventory')
        if any(v for k, v in plan['inputs'].items() if k != plan.get('source')):
            offline()
        self.state_dir()
        lock = self.state / (plan['name'] + '.lock')
        if exists(self.state / (plan['name'] + '.maintenance.lock')):
            raise Blocked('recovery/rollback in progress')
        txid = uuid.uuid4().hex
        fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(fd, 'w') as stream:
            json.dump({'pid': os.getpid(), 'id': txid}, stream)
            stream.flush()
            os.fsync(stream.fileno())
        receipt = {'schema': 1, 'id': txid, 'name': plan['name'], 'pid': os.getpid(),
                   'home': str(self.home), 'repo': str(self.repo), 'status': 'preparing',
                   'inputs': plan['inputs'], 'parents': plan['parents'], 'operations': []}
        path = self.state / (txid + '.json')
        try:
            # Any replacement/removal of an existing root needs a measured offline state.
            if any(v for k, v in plan['inputs'].items() if k != plan.get('source')):
                offline()
            for p, expected in plan['inputs'].items():
                if snapshot(Path(p)) != expected:
                    raise Blocked(f'input changed: {p}')
            target = Path(plan['target'])
            target.parent.mkdir(parents=True, exist_ok=True)
            new_parents = self.guard(target)
            if plan['name'] == 'handoffs':
                new_parents.update(self.guard(self.legacy))
            if any(v is not None and new_parents.get(k) != v for k, v in plan['parents'].items()):
                raise Blocked('parent identity changed during directory creation')
            receipt['parents'] = new_parents
            stage = target.with_name('.' + target.name + '.runtime-stage-' + txid)
            if exists(stage):
                raise Blocked('stage collision')
            if exists(target) and not plan['replace']:
                shutil.copytree(target, stage, symlinks=True)
            else:
                stage.mkdir(mode=0o700)
            for p in plan['merge']:
                merge_tree(Path(p), stage)
            for key in [*plan['links'], *plan['remove']]:
                remove(stage / key)
            for key, source in plan['links'].items():
                (stage / key).symlink_to(source, target_is_directory=Path(source).is_dir())
            for key in plan['empty']:
                (stage / key).touch(mode=0o600, exist_ok=False)
            # A copied root keeps mode/mtime; ensure handoff metadata survives merging.
            if plan['merge']:
                shutil.copystat(Path(plan['merge'][0]), stage, follow_symlinks=False)
            elif exists(target) and not target.is_symlink():
                shutil.copystat(target, stage, follow_symlinks=False)
            receipt['operations'].append(operation(target, stage, txid))
            if plan['legacy']:
                receipt['operations'].append(operation(Path(plan['legacy']), None, txid))
            receipt['status'] = 'prepared'
            write_receipt(path, receipt)
            for p, expected in plan['inputs'].items():
                if snapshot(Path(p)) != expected:
                    raise Blocked(f'input changed while staging: {p}')
            if any(op['before'] for op in receipt['operations']):
                offline()
            current_parents = self.guard(target)
            if plan['name'] == 'handoffs':
                current_parents.update(self.guard(self.legacy))
            if current_parents != receipt['parents']:
                raise Blocked('parent identity changed while staging')
            advance(path, receipt)
            if plan.get('source') and snapshot(Path(plan['source'])) != plan['inputs'][plan['source']]:
                raise Blocked('source changed during commit; installed data retained for diagnosis')
            lock.unlink()
            return {'status': 'committed', 'name': plan['name'], 'transaction': txid,
                    'receipt': str(path), 'backups': [op['backup'] for op in receipt['operations'] if op['before']]}
        except BaseException:
            # Keep receipt/stage/lock for explicit diagnosis; no guessed rollback.
            if not path.exists():
                write_receipt(path, receipt)
            raise

    def receipt(self, txid):
        if not re.fullmatch(r'[0-9a-f]{32}', txid):
            raise Blocked('invalid transaction id')
        path = self.state / (txid + '.json')
        safe_parents(path, self.home, self.repo)
        if path.is_symlink() or not path.is_file():
            raise Blocked('receipt must be a regular file')
        r = json.loads(path.read_text())
        if not isinstance(r, dict) or r.get('schema') != 1 or r.get('id') != txid or r.get('home') != str(self.home) or r.get('repo') != str(self.repo) or r.get('name') not in self.targets:
            raise Blocked('receipt context mismatch')
        if type(r.get('pid')) is not int or r['pid'] <= 0 or not isinstance(r.get('inputs'), dict) or not isinstance(r.get('operations'), list):
            raise Blocked('receipt shape mismatch')
        if r.get('status') not in ('preparing', 'prepared', 'committed', 'rollback-prepared', 'rolled-back', 'aborted') or any(not isinstance(op, dict) for op in r['operations']):
            raise Blocked('receipt status or operation shape mismatch')
        allowed = [self.targets[r['name']]]
        if r['name'] == 'handoffs':
            allowed.append(self.legacy)
        source = self.repo / ('claude/skills' if r['name'] == 'claude-skills' else 'codex/rules' if r['name'] == 'codex-rules' else 'codex/skills')
        expected_inputs = {str(p) for p in allowed} if r['name'] == 'handoffs' else {str(allowed[0]), str(source)}
        if set(r['inputs']) != expected_inputs:
            raise Blocked('receipt input scope mismatch')
        expected_operations = [str(self.targets[r['name']])]
        if r['name'] == 'handoffs' and r['inputs'].get(str(self.legacy)):
            expected_operations.append(str(self.legacy))
        if r['status'] != 'preparing' and [op.get('target') for op in r['operations']] != expected_operations:
            raise Blocked('receipt operation set mismatch')
        current_parents = {}
        for target in allowed:
            current_parents.update(self.guard(target))
        if current_parents != r.get('parents'):
            raise Blocked('receipt parent identity changed')
        for index, op in enumerate(r['operations']):
            if not {'target', 'backup', 'stage', 'before', 'candidate', 'step'} <= op.keys():
                raise Blocked('receipt operation fields missing')
            p = Path(op['target'])
            expected_stage = str(p.with_name('.' + p.name + '.runtime-stage-' + txid)) if index == 0 else None
            if p not in allowed or op['backup'] != str(p.with_name('.' + p.name + '.runtime-backup-' + txid)) or op['stage'] != expected_stage:
                raise Blocked('receipt path mismatch')
            if not isinstance(op['before'], dict) or not isinstance(op['candidate'], dict) or op['before'] != r['inputs'][op['target']]:
                raise Blocked('receipt snapshot shape mismatch')
            if (index == 0 and op['candidate'].get('', {}).get('kind') != 'dir') or (index != 0 and op['candidate']):
                raise Blocked('receipt candidate shape mismatch')
            self.guard(p)
        return path, r

    def recover(self, txid, rollback=False):
        path, r = self.receipt(txid)
        offline()
        lock = self.state / (r['name'] + '.lock')
        if alive(r['pid']):
            raise Blocked('recorded transaction PID is still alive')
        if exists(lock):
            if lock.is_symlink():
                raise Blocked('aliased lock')
            owner = json.loads(lock.read_text())
            if owner['id'] != txid or alive(owner['pid']):
                raise Blocked('lock owner is alive or belongs to another transaction')
        elif r['status'] != 'committed':
            raise Blocked('missing transaction lock')
        maintenance = self.state / (r['name'] + '.maintenance.lock')
        fd = os.open(maintenance, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(fd, 'w') as stream:
            json.dump({'pid': os.getpid(), 'id': txid}, stream)
        try:
            # A committed receipt has no lock; claim it exclusively before mutation.
            if not exists(lock):
                fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
                with os.fdopen(fd, 'w') as stream:
                    json.dump({'pid': os.getpid(), 'id': txid}, stream)
            else:
                owner = json.loads(lock.read_text())
                if owner['id'] != txid or alive(owner['pid']):
                    raise Blocked('lock changed during recovery admission')
                write_receipt(lock, {'pid': os.getpid(), 'id': txid})
            operation_targets = {op['target'] for op in r['operations']}
            for p, expected in r['inputs'].items():
                if p not in operation_targets and snapshot(Path(p)) != expected:
                    raise Blocked('source changed since transaction')
            return self.resume(path, r, lock, rollback)
        finally:
            maintenance.unlink()

    def resume(self, path, r, lock, rollback):
        txid = r['id']
        if rollback:
            if r['status'] != 'committed':
                raise Blocked('rollback requires committed receipt; recover partial transaction first')
            for op in r['operations']:
                if snapshot(Path(op['target'])) != op['candidate'] or snapshot(Path(op['backup'])) != op['before']:
                    raise Blocked('installed target or backup changed; rollback refused')
            # Retain installed candidates too: never unlink checkpoint data during rollback.
            for op in reversed(r['operations']):
                target, stage, backup = Path(op['target']), Path(op['backup'] + '.rolled-forward'), Path(op['backup'])
                if exists(stage):
                    raise Blocked('rollback retention collision')
                op['rollback_retained'] = str(stage)
            r['status'] = 'rollback-prepared'
            write_receipt(path, r)
            reverse_transaction(path, r)
        else:
            if r['status'] == 'rollback-prepared':
                reverse_transaction(path, r)
            elif r['status'] == 'preparing' and not r['operations']:
                if any(snapshot(Path(p)) != expected for p, expected in r['inputs'].items()):
                    raise Blocked('input changed during incomplete staging')
                r['status'] = 'aborted'
                write_receipt(path, r)
            elif r['status'] not in ('prepared', 'committed'):
                raise Blocked('incomplete staging or rollback needs manual diagnosis')
            else:
                advance(path, r)
        if exists(lock):
            lock.unlink()
        return {'status': r['status'], 'transaction': txid}


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def remove(path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif exists(path):
        shutil.rmtree(path)


def merge_tree(source, target):
    for child in source.iterdir():
        dest = target / child.name
        if child.is_dir():
            if not exists(dest):
                shutil.copytree(child, dest)
            else:
                merge_tree(child, dest)
                shutil.copystat(child, dest)
        elif not exists(dest):
            shutil.copy2(child, dest)


def operation(target, stage, txid):
    backup = target.with_name('.' + target.name + '.runtime-backup-' + txid)
    if exists(backup):
        raise Blocked('backup collision')
    return {'target': str(target), 'stage': str(stage) if stage else None,
            'backup': str(backup), 'before': snapshot(target),
            'candidate': snapshot(stage) if stage else {}, 'step': 'pending'}


def write_receipt(path, value):
    tmp = path.with_suffix('.tmp')
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(tmp, path)
    fd = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def boundary(path, r, index, step):
    r['operations'][index]['step'] = step
    write_receipt(path, r)
    # Isolated fault-injection oracle; unset in normal deployment.
    if os.environ.get('DOTFILES_RUNTIME_TEST_FAIL') == f'{index}:{step}':
        raise Blocked(f'injected interruption: {index}:{step}')


def advance(path, r):
    known_steps = {'pending', 'backup-intent', 'backed-up', 'install-intent', 'installed', 'verified'}
    if not r['operations'] or any(op.get('step') not in known_steps for op in r['operations']):
        raise Blocked('unknown transaction step; no operation performed')
    for i, op in enumerate(r['operations']):
        target, backup = Path(op['target']), Path(op['backup'])
        stage = Path(op['stage']) if op['stage'] else None
        current, saved = snapshot(target), snapshot(backup)
        candidate, before = op['candidate'], op['before']
        if op['step'] in ('pending', 'backup-intent'):
            if current == before and not saved:
                if stage and snapshot(stage) != candidate:
                    raise Blocked('candidate changed')
                boundary(path, r, i, 'backup-intent')
                if before:
                    target.rename(backup)
            elif not current and saved == before and before:
                pass  # Rename happened but its completion receipt was interrupted.
            else:
                raise Blocked('unknown backup state')
            boundary(path, r, i, 'backed-up')
        if op['step'] in ('backed-up', 'install-intent'):
            if snapshot(backup) != before:
                raise Blocked('backup changed')
            current = snapshot(target)
            if not current:
                if stage and snapshot(stage) != candidate:
                    raise Blocked('candidate changed')
                boundary(path, r, i, 'install-intent')
                if stage:
                    stage.rename(target)
            elif current == candidate and stage and not exists(stage):
                pass
            else:
                raise Blocked('unknown install state')
            boundary(path, r, i, 'installed')
        if op['step'] in ('installed', 'verified'):
            if snapshot(target) != candidate or snapshot(backup) != before:
                raise Blocked('post-install verification failed')
            boundary(path, r, i, 'verified')
    r['status'] = 'committed'
    write_receipt(path, r)


def reverse_transaction(path, r):
    for i in reversed(range(len(r['operations']))):
        op = r['operations'][i]
        target, kept, backup = Path(op['target']), Path(op['rollback_retained']), Path(op['backup'])
        current, saved, retained = snapshot(target), snapshot(backup), snapshot(kept)
        before, candidate = op['before'], op['candidate']
        if current == candidate and saved == before and not retained:
            boundary(path, r, i, 'rollback-intent')
            if candidate:
                target.rename(kept)
            boundary(path, r, i, 'rollback-retained')
            current, retained = snapshot(target), snapshot(kept)
        if not current and saved == before and retained == candidate:
            boundary(path, r, i, 'rollback-restore-intent')
            if before:
                backup.rename(target)
        elif current == before and not saved and retained == candidate:
            pass
        else:
            raise Blocked('unknown rollback state')
        if snapshot(target) != before or snapshot(backup) or snapshot(kept) != candidate:
            raise Blocked('rollback verification failed')
        boundary(path, r, i, 'rolled-back')
    r['status'] = 'rolled-back'
    write_receipt(path, r)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', nargs='?', default='inventory', choices=['inventory', 'dry-run', 'apply', 'verify', 'recover', 'rollback', 'guard-config-home'])
    parser.add_argument('--home', default=os.environ.get('HOME'))
    parser.add_argument('--repo', default=os.environ.get('DOTFILES_DIR', str(Path(__file__).resolve().parents[1])))
    parser.add_argument('--transaction')
    args = parser.parse_args()
    try:
        if not args.home:
            raise Blocked('HOME is required')
        layout = Layout(Path(args.home), Path(args.repo), os.environ.get('CODEX_HOME'))
        if args.command == 'guard-config-home':
            # Shared entry must not let the independent helpers follow a rejected
            # native-home parent into the source repository.
            layout.guard(layout.codex / 'config.toml')
            print(json.dumps({'ok': True, 'command': args.command, 'target': str(layout.codex)}, ensure_ascii=False))
            return 0
        if args.command in ('recover', 'rollback'):
            if not args.transaction:
                raise Blocked('--transaction is required')
            result = layout.recover(args.transaction, args.command == 'rollback')
            print(json.dumps(result, ensure_ascii=False))
            return 0
        try:
            process_inventory = {'ok': True, 'writers': writers()}
        except Blocked as error:
            process_inventory = {'ok': False, 'writers': [], 'error': str(error)}
        results, failed = [], not process_inventory['ok']
        codex_ready = False
        for name in layout.targets:
            try:
                plan = layout.plan(name)
                moves_existing = plan['changed'] and any(v for k, v in plan['inputs'].items() if k != plan.get('source'))
                if moves_existing and (not process_inventory['ok'] or process_inventory['writers']):
                    raise Blocked('runtime writer inventory blocks migration; exit owning app normally and inventory again')
                if name == 'codex-legacy' and plan['changed'] and not codex_ready:
                    raise Blocked('new Codex adapters not verified; legacy links retained')
                result = {'name': name, 'target': plan['target'], 'status': 'needs-upgrade' if plan['changed'] else 'unchanged',
                          'actions': {'links': plan['links'], 'remove': plan['remove'], 'empty': plan['empty'], 'merge': plan['merge']}}
                if args.command == 'apply':
                    result = layout.apply(plan)
                elif args.command == 'verify' and plan['changed']:
                    failed = True
                if name == 'codex-skills':
                    codex_ready = (not plan['changed'] or args.command == 'apply')
                results.append(result)
            except (Blocked, OSError, ValueError) as error:
                results.append({'name': name, 'target': str(layout.targets[name]), 'status': 'blocked', 'reason': str(error)})
                failed = True
        print(json.dumps({'ok': not failed, 'command': args.command, 'roots': results,
                          'cli': {name: shutil.which(name) is not None for name in ('codex', 'claude')},
                          'process_inventory': process_inventory,
                          'native_loading_verified': False}, ensure_ascii=False, indent=2))
        return 1 if failed else 0
    except (Blocked, OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'ok': False, 'reason': str(error)}, ensure_ascii=False))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
