#!/usr/bin/env python3
"""Own isolated shard process groups and reap them on any interrupted/failed run."""
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def signal_group(process, signum):
    try:
        os.killpg(process.pid, signum)
    except ProcessLookupError:
        pass


def main():
    root, results = map(Path, sys.argv[1:3])
    shards = sys.argv[3:]
    processes = {}
    logs = []
    interrupted = 0

    def interrupt(signum, _frame):
        nonlocal interrupted
        interrupted = 128 + signum

    for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(signum, interrupt)
    try:
        for name in shards:
            if interrupted:
                break
            log = (results / f'{name}.log').open('wb')
            logs.append(log)
            processes[name] = subprocess.Popen([str(root / 'tests/run.sh')],
                env=dict(os.environ, DOTFILES_TEST_SHARD=name), stdout=log, stderr=subprocess.STDOUT,
                stdin=subprocess.DEVNULL, start_new_session=True)
        pending = set(processes)
        while pending and not interrupted:
            for name in list(pending):
                rc = processes[name].poll()
                if rc is None:
                    continue
                (results / f'{name}.rc').write_text(str(rc if rc >= 0 else 128 - rc) + '\n')
                pending.remove(name)
                if rc != 0:
                    interrupted = 128 + signal.SIGTERM
                    break
            if pending and not interrupted:
                time.sleep(.02)
    finally:
        # Do not let repeated signals interrupt cleanup. Groups belong only to this invocation.
        for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            signal.signal(signum, signal.SIG_IGN)
        if interrupted or any(p.poll() is None for p in processes.values()):
            for process in processes.values():
                signal_group(process, signal.SIGTERM)
            # Descendants may remain after the leader exits; give the whole group a bounded grace.
            time.sleep(.2)
        for process in processes.values():
            signal_group(process, signal.SIGKILL)
            process.wait()
        for log in logs:
            log.close()
    return interrupted


if __name__ == '__main__':
    raise SystemExit(main())
