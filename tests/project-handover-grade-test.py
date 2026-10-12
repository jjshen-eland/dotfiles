"""Deterministic checks for the handover acceptance grader."""

import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

GRADER = pathlib.Path(__file__).resolve().parent.parent / "shared/skills/project/scripts/grade-handover.py"


class GradeHandoverTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = pathlib.Path(self.tmp.name)
        self.clone = root / "clone"
        (self.clone / "deploy").mkdir(parents=True)
        (self.clone / "deploy/crontab").write_text("0 2 * * * run-sync\n")
        self.spec_path = root / "spec.json"
        self.answers_path = root / "answers.json"
        self.spec = {
            "schema": 1,
            "questions": [
                {"id": "Q1", "kind": "command", "stdout_contains": "ok"},
                {"id": "Q2", "kind": "answer", "contains": ["02:00"], "paths": ["deploy/crontab"],
                 "ids": ["D-20261001-sync-schedule"]},
            ],
        }
        self.answers = {
            "Q1": "echo ok",
            "Q2": "Nightly sync runs at 02:00 from deploy/crontab, chosen in D-20261001-sync-schedule.",
        }

    def tearDown(self):
        self.tmp.cleanup()

    def grade(self, *extra, allow_exec=True, env=None):
        self.spec_path.write_text(json.dumps(self.spec))
        self.answers_path.write_text(json.dumps(self.answers))
        flags = ["--allow-exec"] if allow_exec else []
        return subprocess.run(
            [sys.executable, "-B", str(GRADER), "--spec", str(self.spec_path),
             "--answers", str(self.answers_path), "--clone", str(self.clone), *flags, *extra],
            capture_output=True, text=True, env=env)

    def test_all_questions_pass(self):
        result = self.grade()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Q1: PASS", result.stdout)
        self.assertIn("Q2: PASS", result.stdout)
        self.assertIn("verdict: PASS", result.stdout)

    def test_missing_required_text_fails(self):
        self.answers["Q2"] = "Nightly sync from deploy/crontab, chosen in D-20261001-sync-schedule."
        result = self.grade()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Q2: FAIL", result.stdout)
        self.assertIn("verdict: FAIL", result.stdout)

    def test_missing_id_fails(self):
        self.answers["Q2"] = "Nightly sync runs at 02:00 from deploy/crontab."
        self.assertEqual(self.grade().returncode, 1)

    def test_path_must_appear_and_exist(self):
        self.spec["questions"][1]["paths"] = ["deploy/missing"]
        self.answers["Q2"] += " See deploy/missing."
        self.assertEqual(self.grade().returncode, 1)
        self.spec["questions"][1]["paths"] = ["deploy/crontab"]
        self.answers["Q2"] = "Nightly sync runs at 02:00, chosen in D-20261001-sync-schedule."
        self.assertEqual(self.grade().returncode, 1)

    def test_failing_command_or_missing_output_fails(self):
        self.answers["Q1"] = "exit 3"
        self.assertEqual(self.grade().returncode, 1)
        self.answers["Q1"] = "echo nope"
        self.assertEqual(self.grade().returncode, 1)

    def test_command_runs_inside_clone(self):
        self.answers["Q1"] = "test -f deploy/crontab && echo ok"
        self.assertEqual(self.grade().returncode, 0)

    def test_commands_need_explicit_confirmation(self):
        self.answers["Q1"] = "touch executed-marker && echo ok"
        result = self.grade(allow_exec=False)
        self.assertEqual(result.returncode, 3, result.stdout)
        self.assertIn("touch executed-marker && echo ok", result.stdout)
        self.assertIn("verdict: NEEDS_CONFIRMATION", result.stdout)
        self.assertFalse((self.clone / "executed-marker").exists())

    def test_command_does_not_inherit_caller_environment(self):
        env = dict(os.environ, HANDOVER_TEST_SECRET="leak")
        self.answers["Q1"] = 'test -z "$HANDOVER_TEST_SECRET" && test "$HOME" != "%s" && echo ok' % os.path.expanduser("~")
        result = self.grade(env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_command_times_out(self):
        self.answers["Q1"] = "sleep 5; echo ok"
        result = self.grade("--timeout", "1")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("timed out", result.stdout)

    def test_command_reads_no_stdin(self):
        self.answers["Q1"] = "cat; echo ok"
        self.assertEqual(self.grade("--timeout", "5").returncode, 0)

    def test_non_utf8_output_is_graded_not_crashed(self):
        self.answers["Q1"] = "printf '\\377 ok'"
        result = self.grade()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("verdict: PASS", result.stdout)

    def test_paths_outside_clone_are_broken(self):
        for bad in ("../escape", "/etc/hosts"):
            self.spec["questions"][1]["paths"] = [bad]
            self.assertEqual(self.grade().returncode, 2, bad)

    def test_command_question_requires_expected_output(self):
        self.spec["questions"][0] = {"id": "Q1", "kind": "command"}
        self.assertEqual(self.grade().returncode, 2)

    def test_unanswered_question_fails(self):
        del self.answers["Q2"]
        result = self.grade()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Q2: FAIL", result.stdout)

    def test_malformed_spec_is_broken(self):
        self.spec = {"schema": 1, "questions": [{"id": "Q1", "kind": "guess"}]}
        result = self.grade()
        self.assertEqual(result.returncode, 2)
        self.assertIn("verdict: BROKEN", result.stdout)

    def test_duplicate_ids_are_broken(self):
        self.spec["questions"].append({"id": "Q1", "kind": "answer", "contains": ["x"]})
        self.assertEqual(self.grade().returncode, 2)


if __name__ == "__main__":
    unittest.main()
