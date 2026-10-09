#!/usr/bin/env bash
# shellcheck disable=SC2154
shellcheck -x -P "SCRIPTDIR:$ROOT/scripts" "${SHELL_GATE_FILES[@]}"
assert_rc "ShellCheck" 0 $?
