#!/usr/bin/env bash
# Run the complete tests/run.sh assertion set as isolated parallel processes.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS="$(mktemp -d)" || { echo "mktemp -d failed" >&2; exit 1; }
[ -n "$RESULTS" ] && [ -d "$RESULTS" ] || { echo "invalid results directory" >&2; exit 1; }
RESULTS="$(cd "$RESULTS" && pwd -P)"
SHARDS=(core ship_state integration)
child_pids=()

cleanup() {
    local pid
    if [ "${#child_pids[@]}" -gt 0 ]; then
        for pid in "${child_pids[@]}"; do
            kill -0 "$pid" >/dev/null 2>&1 && kill "$pid" >/dev/null 2>&1
            wait "$pid" >/dev/null 2>&1 || true
        done
    fi
    rm -rf "$RESULTS"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

for shard in "${SHARDS[@]}"; do
    (
        DOTFILES_TEST_SHARD="$shard" "$ROOT/tests/run.sh" >"$RESULTS/$shard.log" 2>&1
        child_rc=$?
        printf '%s\n' "$child_rc" >"$RESULTS/$shard.rc.tmp"
        mv "$RESULTS/$shard.rc.tmp" "$RESULTS/$shard.rc"
    ) &
    child_pids+=("$!")
done

for pid in "${child_pids[@]}"; do
    wait "$pid" >/dev/null 2>&1 || true
done
child_pids=()

for shard in "${SHARDS[@]}"; do
    echo "════════ SHARD ${shard} ════════"
    if [ -f "$RESULTS/$shard.log" ]; then
        sed "s/^/[${shard}] /" "$RESULTS/$shard.log"
    else
        echo "[${shard}] missing diagnostic log" >&2
    fi
done

python3 "$ROOT/tests/shard-aggregate.py" \
    --manifest "$ROOT/tests/shard-manifest.tsv" \
    --results "$RESULTS"
