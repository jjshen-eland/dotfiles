"""Offline checks for eval containment; never starts a model."""

import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

SERVER = pathlib.Path(__file__).with_name("session-skills-host-mcp.py")


class TransportTest(unittest.TestCase):
    def call(self, work, command):
        request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {"name": "bash", "arguments": {"command": command}},
        }
        proc = subprocess.run(
            [sys.executable, str(SERVER), str(work)],
            input=json.dumps(request) + "\n",
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(proc.stdout)["result"]

    def test_private_probe_preempts_entire_batch(self):
        with tempfile.TemporaryDirectory() as tmp:
            work = pathlib.Path(tmp) / "work"
            work.mkdir()
            for path in [
                "~/.claude/CLAUDE.md",
                "$HOME/.codex/memory",
                "/Users/fixture/.claude/projects/x",
                "/home/fixture/.agents/handoffs",
            ]:
                with self.subTest(path=path):
                    result = self.call(work, f"touch canary; ls {path}")
                    self.assertTrue(result["isError"])
                    self.assertFalse((work / "canary").exists())
            logs = [
                json.loads(x)
                for x in (work.parent / "host-transport.jsonl").read_text().splitlines()
            ]
            self.assertTrue(all(x["blocked"] for x in logs))

    def test_fixture_skill_path_and_output_are_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            work = pathlib.Path(tmp) / "work"
            (work / ".claude/skills").mkdir(parents=True)
            (work / ".claude/skills/entry.md").write_text(
                "REFERENCE\tfixture\nBEGIN\nL000001\tcomplete\nEND\n"
            )
            result = self.call(work, "cat .claude/skills/entry.md")
            self.assertFalse(result["isError"])
            self.assertEqual(
                result["content"][0]["text"],
                (work / ".claude/skills/entry.md").read_text(),
            )
            log = json.loads((work.parent / "host-transport.jsonl").read_text())
            self.assertFalse(log["blocked"])
            self.assertEqual(log["raw"], log["sent"])

    def test_nonzero_exit_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            work = pathlib.Path(tmp) / "work"
            work.mkdir()
            result = self.call(work, "printf failed; exit 7")
            self.assertTrue(result["isError"])
            log = json.loads((work.parent / "host-transport.jsonl").read_text())
            self.assertEqual(log["exit"], 7)
            self.assertEqual(log["sent"], "failed")


if __name__ == "__main__":
    unittest.main()
