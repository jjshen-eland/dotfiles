#!/usr/bin/env python3
"""Behavior tests for the fail-closed test-shard result aggregator."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AGGREGATOR = ROOT / "tests" / "shard-aggregate.py"
SHARDS = {"core": 2, "ship_state": 1, "integration": 3}


class ShardAggregateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.results = self.root / "results"
        self.results.mkdir()
        self.manifest = self.root / "manifest.tsv"
        self.manifest.write_text(
            "".join(f"{name}\t{count}\n" for name, count in SHARDS.items()),
            encoding="utf-8",
        )
        for name, count in SHARDS.items():
            self.write_result(name, rc=0, passed=count, failed=0)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_result(
        self,
        name: str,
        *,
        rc: int,
        passed: int,
        failed: int,
        summary_name: str | None = None,
    ) -> None:
        (self.results / f"{name}.rc").write_text(f"{rc}\n", encoding="utf-8")
        (self.results / f"{name}.log").write_text(
            "fixture output\n"
            f"SHARD_RESULT name={summary_name or name} pass={passed} "
            f"fail={failed} elapsed_s=1\n",
            encoding="utf-8",
        )

    def run_aggregator(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(AGGREGATOR),
                "--manifest",
                str(self.manifest),
                "--results",
                str(self.results),
            ],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_accepts_exact_complete_success_set(self) -> None:
        result = self.run_aggregator()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("SHARD_AGGREGATE pass=6 fail=0 shards=3", result.stdout)

    def test_rejects_nonzero_child_exit(self) -> None:
        self.write_result("ship_state", rc=1, passed=1, failed=0)
        result = self.run_aggregator()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ship_state", result.stderr)

    def test_rejects_signal_like_child_exit(self) -> None:
        self.write_result("integration", rc=143, passed=3, failed=0)
        result = self.run_aggregator()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("integration", result.stderr)

    def test_rejects_missing_completion_artifact(self) -> None:
        (self.results / "core.rc").unlink()
        result = self.run_aggregator()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("core", result.stderr)

    def test_rejects_missing_or_duplicate_summary(self) -> None:
        log = self.results / "core.log"
        log.write_text("fixture output\n", encoding="utf-8")
        missing = self.run_aggregator()
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn("core", missing.stderr)

        self.write_result("core", rc=0, passed=2, failed=0)
        with log.open("a", encoding="utf-8") as stream:
            stream.write("SHARD_RESULT name=core pass=2 fail=0 elapsed_s=2\n")
        duplicate = self.run_aggregator()
        self.assertNotEqual(duplicate.returncode, 0)
        self.assertIn("core", duplicate.stderr)

    def test_rejects_wrong_identity_or_assertion_count(self) -> None:
        self.write_result(
            "ship_state", rc=0, passed=1, failed=0, summary_name="integration"
        )
        identity = self.run_aggregator()
        self.assertNotEqual(identity.returncode, 0)
        self.assertIn("ship_state", identity.stderr)

        self.write_result("ship_state", rc=0, passed=2, failed=0)
        count = self.run_aggregator()
        self.assertNotEqual(count.returncode, 0)
        self.assertIn("ship_state", count.stderr)


if __name__ == "__main__":
    unittest.main()
