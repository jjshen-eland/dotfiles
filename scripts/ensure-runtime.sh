#!/usr/bin/env bash
# Shared runtime deployment entry; layout failures stay visible to every caller.
set -uo pipefail
# dotfiles-gen2 owns the agent runtime once it has deployed here (it records this file and deletes it on
# rollback). Every caller — brewup, dotsync, setup — would otherwise put gen1's skills, Codex guidance and
# hooks back over gen2's deployment (2026-10-16).
if [ -f "$HOME/.local/state/dotfiles-gen2/deploy.json" ]; then
    echo 'ℹ agent runtime 由 dotfiles-gen2 管理，略過 gen1 的 runtime 部署'
    exit 0
fi
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export DOTFILES_DIR
runtime_rc=0
if ! python3 "$DOTFILES_DIR/scripts/ensure-runtime-layout.py" apply --summary; then
    echo '⚠️  Runtime layout blocked; inspect the report/receipt before retrying'
    runtime_rc=1
fi
# Guidance/config retain their backup/merge contracts, after native-home safety.
if python3 "$DOTFILES_DIR/scripts/ensure-runtime-layout.py" guard-config-home --summary; then
    if ! bash "$DOTFILES_DIR/scripts/ensure-codex-guidance.sh"; then
        runtime_rc=1
    fi
    if ! python3 "$DOTFILES_DIR/scripts/ensure-codex-config.py"; then
        runtime_rc=1
    fi
else
    echo '⚠️  Codex home blocked; guidance and config deployment skipped'
    runtime_rc=1
fi
exit "$runtime_rc"
