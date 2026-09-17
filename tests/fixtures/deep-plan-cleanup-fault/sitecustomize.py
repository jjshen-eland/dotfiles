"""Inject the macOS stale process-group cleanup failure deterministically."""

import os
import signal


_original_killpg = os.killpg
_signals_by_group = {}


def guarded_killpg(process_group, chosen_signal):
    calls = _signals_by_group.get(process_group, 0) + 1
    _signals_by_group[process_group] = calls
    if chosen_signal == signal.SIGKILL and calls >= 2:
        raise PermissionError(1, "simulated stale process-group permission race")
    return _original_killpg(process_group, chosen_signal)


os.killpg = guarded_killpg
