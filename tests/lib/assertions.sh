#!/usr/bin/env bash
# Shared counters and diagnostics; callers initialize PASS and FAIL.
ok()   { PASS=$((PASS + 1)); echo "  ✅ $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }

# assert_eq <名稱> <期望> <實際>
assert_eq() {
    if [ "$2" = "$3" ]; then ok "$1"; else
        bad "$1"
        echo "     expected: $(printf '%q' "$2")"
        echo "     actual:   $(printf '%q' "$3")"
    fi
}
# assert_rc <名稱> <期望exit> <實際exit>
assert_rc() {
    if [ "$2" -eq "$3" ]; then ok "$1"; else bad "$1（期望 exit=$2，實際 exit=$3）"; fi
}

