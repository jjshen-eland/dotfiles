"""Offline regression checks for the trace normalizer, with no model calls."""

import hashlib
import importlib.util
import json
import shlex
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "reference_metrics", Path(__file__).with_name("project-reference-metrics.py")
)
normalizer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(normalizer)


class MetricsTests(unittest.TestCase):
    def test_host_transport_cuts_only_one_reader_result(self):
        root = Path(__file__).resolve().parent.parent
        helper = root / "shared/skills/project/scripts/read-reference.py"
        command = f"{shlex.quote(sys.executable)} {shlex.quote(str(helper))} workflow.md --start 1"
        requests = [
            {
                "jsonrpc": "2.0",
                "id": n,
                "method": "tools/call",
                "params": {"name": "bash", "arguments": {"command": command}},
            }
            for n in [1, 2]
        ]
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory) / "work"
            work.mkdir()
            proc = subprocess.run(
                [
                    sys.executable,
                    str(root / "tests/project-reference-host-mcp.py"),
                    str(work),
                ],
                input="\n".join(json.dumps(r) for r in requests) + "\n",
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0)
            replies = [json.loads(line) for line in proc.stdout.splitlines()]
            first, second = [r["result"]["content"][0]["text"] for r in replies]
            self.assertIn("L000010\t", first)
            self.assertNotIn("END\n", first)
            self.assertIn("END\nNEXT\t", second)
            raw = [
                json.loads(line)
                for line in (Path(directory) / "host-transport.jsonl")
                .read_text()
                .splitlines()
            ]
            self.assertEqual(raw[0]["raw"], second)
            self.assertEqual(raw[1]["sent"], second)

    def score(self, chunks, truncate=False):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            refs = source / "shared/skills/project/references"
            refs.mkdir(parents=True)
            (refs / "workflow.md").write_text("first line\ncomplete last line\n")
            digest = hashlib.sha256((refs / "workflow.md").read_bytes()).hexdigest()
            events = []
            for number, (start, body) in enumerate(chunks):
                out = f"REFERENCE\tworkflow.md\nSHA256\t{digest}\nTOTAL\t2\nRANGE\t{start}\t2\nBEGIN\n{body}"
                ident = str(number)
                for kind, elapsed in [
                    ("item.started", number * 2),
                    ("item.completed", number * 2 + 1),
                ]:
                    events.append(
                        {
                            "elapsed_s": elapsed,
                            "event": {
                                "type": kind,
                                "item": {
                                    "id": ident,
                                    "type": "command_execution",
                                    "command": f"python3 read-reference.py workflow.md --start {start}",
                                    "aggregated_output": out,
                                },
                            },
                        }
                    )
            (source / "first.timed.jsonl").write_text(
                "\n".join(json.dumps(e) for e in events)
            )
            (source / "first.summary.json").write_text(
                json.dumps(
                    {
                        "model": "gpt-6.1-sol",
                        "runtime": "codex",
                        "incremental_usage": {
                            "input_tokens": 1000,
                            "cached_input_tokens": 800,
                            "output_tokens": 100,
                        },
                    }
                )
            )
            if truncate:
                (source / "inject-truncation").touch()
            return normalizer.metrics(source, "first", source)

    def test_stripped_final_newline_counts_complete_row(self):
        m = self.score(
            [
                (1, "L000001\tfirst line"),
                (2, "L000002\tcomplete last line\nEND\nEOF\t2"),
            ],
            True,
        )
        self.assertEqual(m["reader_protocol_errors"], [])
        self.assertEqual(m["host_truncation_protocol"], "PASS")

    def test_partial_row_is_not_complete(self):
        m = self.score(
            [
                (1, "L000001\tfirst line\nL000002\tcomplete last"),
                (2, "L000002\tcomplete last line\nEND\nEOF\t2"),
            ]
        )
        self.assertEqual(m["calls"][0]["visible_lines"], [1])
        self.assertEqual(m["reader_protocol_errors"], [])

    def test_restart_from_first_row_fails(self):
        m = self.score(
            [
                (1, "L000001\tfirst line"),
                (1, "L000001\tfirst line\nL000002\tcomplete last line\nEND\nEOF\t2"),
            ]
        )
        self.assertTrue(m["reader_protocol_errors"])

    def test_unobserved_truncation_is_inconclusive(self):
        m = self.score(
            [(1, "L000001\tfirst line\nL000002\tcomplete last line\nEND\nEOF\t2")], True
        )
        self.assertIn("INCONCLUSIVE", m["host_truncation_protocol"])

    def test_cached_input_is_not_charged_twice(self):
        m = self.score(
            [(1, "L000001\tfirst line\nL000002\tcomplete last line\nEND\nEOF\t2")]
        )
        self.assertAlmostEqual(m["credits_equivalent"], 0.037)


if __name__ == "__main__":
    unittest.main()
