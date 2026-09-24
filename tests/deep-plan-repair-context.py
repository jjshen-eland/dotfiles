"""Focused repair prompt transport; no model calls."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

SOURCE = Path(sys.argv.pop(1)).resolve()
spec = importlib.util.spec_from_file_location("launcher", SOURCE)
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)
refs = SOURCE.parent.parent / "references"


class RepairContextTests(unittest.TestCase):
    def test_initial_prompt_remains_blind(self):
        prompt = launcher.reviewer_prompt(Path("/plan.md"), [Path("/repo")], refs / "planner-brief.md", refs / "reviewer-prompt.txt", refs / "criteria-impact-prompt.txt", False)
        self.assertNotIn("修後驗證資料", prompt)
        self.assertNotIn("{REVIEW_SCOPE_PARAGRAPH}", prompt)

    def test_focused_prompt_requires_independent_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            packet = Path(tmp) / "repair.md"
            packet.write_text("F1: caller and callee mismatch\n")
            prompt = launcher.reviewer_prompt(Path("/plan.md"), [Path("/repo")], refs / "planner-brief.md", refs / "reviewer-prompt.txt", refs / "criteria-impact-prompt.txt", True, packet)
            self.assertIn(str(packet), prompt)
            self.assertIn("修後驗證資料", prompt)
            self.assertIn("不是通過證明", prompt)
            self.assertNotIn("F1: caller", prompt)
            self.assertNotIn("{REVIEW_SCOPE_PARAGRAPH}", prompt)


unittest.main()
