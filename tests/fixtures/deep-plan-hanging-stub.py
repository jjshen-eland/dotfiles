#!/usr/bin/env python3
"""Spawn a pipe-inheriting descendant and wait for launcher cleanup tests."""

import os
from pathlib import Path
import subprocess
import sys
import time


child = subprocess.Popen(
    [sys.executable, "-c", "import time; time.sleep(60)"],
    stdout=sys.stdout,
    stderr=sys.stderr,
)
pid_dir = Path(os.environ["DEEP_PLAN_DESCENDANT_PID_DIR"])
(pid_dir / f"{os.getpid()}.pid").write_text(str(child.pid), encoding="utf-8")
time.sleep(60)
