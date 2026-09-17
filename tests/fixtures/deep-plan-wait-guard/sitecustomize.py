"""Make repeated main-thread waits on one Popen deterministic for signal tests."""

import subprocess
import threading
import weakref


_original_wait = subprocess.Popen.wait
_main_wait_counts = weakref.WeakKeyDictionary()


def is_reviewer_process(process):
    args = process.args
    if isinstance(args, (list, tuple)):
        return any("deep-plan-hanging-stub.py" in str(arg) for arg in args)
    return "deep-plan-hanging-stub.py" in str(args)


def guarded_wait(self, *args, **kwargs):
    if (
        threading.current_thread() is threading.main_thread()
        and is_reviewer_process(self)
    ):
        count = _main_wait_counts.get(self, 0) + 1
        _main_wait_counts[self] = count
        if count > 2:
            raise RuntimeError("repeated main-thread cleanup wait")
    return _original_wait(self, *args, **kwargs)


subprocess.Popen.wait = guarded_wait
