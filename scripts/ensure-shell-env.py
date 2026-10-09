#!/usr/bin/env python3
"""Attach shared environment without replacing personal or legacy shell content.

A managed source block goes before the first noninteractive return in .bashrc,
and at the end of .zshenv. New setup emits the same block. Backups are retained;
unknown/duplicate markers, symlinks and concurrent edits fail closed.
"""
import argparse
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile

START = '# dotfiles:environment:start'
END = '# dotfiles:environment:end'
BLOCK = START + '\n[ ! -f "$HOME/.dotfiles/shell/environment.sh" ] || . "$HOME/.dotfiles/shell/environment.sh"\n' + END + '\n'


def render(text, name):
    if START in text or END in text:
        if text.count(START) != 1 or text.count(END) != 1:
            raise ValueError('ambiguous managed environment markers')
        a, b = text.index(START), text.index(END) + len(END)
        if b < a:
            raise ValueError('reversed managed environment markers')
        if text[a:b + 1] != BLOCK:
            raise ValueError('managed block locally modified; review before replacing')
        return text
    # Prepend to bashrc so even user-specific early returns cannot skip it.
    # Environment preserves existing project PATH precedence.
    return BLOCK + text if name == '.bashrc' else text + ('\n' if text else '') + BLOCK


def run(mode, home):
    source = home / ".dotfiles/shell/environment.sh"
    if not source.is_file():
        raise ValueError("missing shared environment: " + str(source))
    changes = []
    for name in ('.zshenv', '.bashrc'):
        path = home / name
        if path.is_symlink() or (path.exists() and not path.is_file()):
            raise ValueError('not a regular shell file: ' + str(path))
        before = path.read_bytes() if path.exists() else None
        text = before.decode() if before is not None else ''
        after = render(text, name).encode()
        if before != after:
            shell = 'zsh' if name == '.zshenv' else 'bash'
            # Linux hosts need not have Zsh installed, but Bash can validate the
            # new POSIX block; existing Zsh files require the actual interpreter.
            interpreter = shutil.which(shell)
            if interpreter:
                check = subprocess.run([interpreter, '-f', '-n'], input=after, capture_output=True)
                if check.returncode:
                    raise ValueError('shell syntax check failed: ' + str(path))
            elif before:
                raise ValueError('cannot validate existing ' + name + ': missing ' + shell)
            changes.append((path, before, after))
    for path, before, after in changes:
        print('shell-env: ' + mode + ' ' + str(path))
        if mode != 'apply':
            continue
        # mkstemp backup preserves every previous byte and original file mode.
        current = path.read_bytes() if path.exists() else None
        if path.is_symlink() or current != before:
            raise ValueError('shell file changed during planning: ' + str(path))
        permissions = stat.S_IMODE(path.stat().st_mode) if before is not None else 0o644
        if before is not None:
            fd, backup = tempfile.mkstemp(prefix=path.name + '.dotfiles-backup-', dir=home)
            with os.fdopen(fd, 'wb') as stream:
                stream.write(before)
            os.chmod(backup, permissions)
            print('shell-env: backup ' + backup)
        fd, temporary = tempfile.mkstemp(prefix=path.name + '.dotfiles-', dir=home)
        try:
            with os.fdopen(fd, 'wb') as stream:
                stream.write(after)
            os.chmod(temporary, permissions)
            if path.is_symlink() or (path.read_bytes() if path.exists() else None) != before:
                raise ValueError('shell file changed before replacement: ' + str(path))
            os.replace(temporary, path)
        finally:
            Path(temporary).unlink(missing_ok=True)
    print('shell-env: ' + ('unchanged' if not changes else str(len(changes)) + ' files'))
    return 1 if mode == 'check' and changes else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('plan', 'apply', 'check'), default='plan', nargs='?')
    args = parser.parse_args()
    try:
        return run(args.mode, Path.home())
    except (OSError, ValueError, UnicodeError) as error:
        print('shell-env: BLOCKED: ' + str(error))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
