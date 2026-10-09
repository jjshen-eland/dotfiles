#!/usr/bin/env bash
# New setup and existing hosts share an ownership-scoped tool contract.
# plan/check never mutate; apply reconciles selected tools and recorded ownership.
# Bash 3.2 treats declared empty arrays as unset under nounset.
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-plan}"
[ "$#" -gt 0 ] && shift
profile=''
local_tools=()
adopt=()
keep=()
state_dir="$HOME/.local/state/dotfiles"
ledger="$state_dir/tools.tsv"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_AUTOREMOVE=1
while [ "$#" -gt 0 ]; do
    case "$1" in
        --adopt) [ "$#" -ge 2 ] || exit 2; adopt+=("$2"); shift 2 ;;
        --keep) [ "$#" -ge 2 ] || exit 2; keep+=("$2"); shift 2 ;;
        --profile) [ "$#" -ge 2 ] || exit 2; profile="$2"; shift 2 ;;
        *) echo "Usage: $0 {plan|apply|check} [--profile core|workstation] [--adopt package] [--keep package]" >&2; exit 2 ;;
    esac
done
case "$mode" in
    plan|apply|check) ;;
    *) echo 'Invalid mode/profile' >&2; exit 2 ;;
esac
os="$(uname -s)"
case "$os" in Darwin|Linux) ;; *) echo "Unsupported OS: $os" >&2; exit 2 ;; esac
# shellcheck source=../shell/environment.sh
source "$ROOT/shell/environment.sh"
[ -r "$ROOT/scripts/dev-tools.tsv" ] || exit 2
# Do not infer ownership from command presence. Only explicit adoption or a
# successful installation by this helper adds a managed package.
contains() {
    local needle="$1" value
    shift
    for value in "$@"; do [ "$needle" != "$value" ] || return 0; done
    return 1
}
owned=()
providers=()
if [ -L "$HOME/.local" ] || [ -L "$HOME/.local/state" ] || [ -L "$state_dir" ] || [ -L "$ledger" ]; then echo 'Unsafe tool state symlink' >&2; exit 2; fi
if [ "$mode" = apply ]; then
    mkdir -p "$state_dir" || exit 1
    mkdir "$state_dir/tools.lock" 2>/dev/null || { echo 'Tool update already locked' >&2; exit 1; }
    trap 'rmdir "$state_dir/tools.lock"' EXIT
    [ ! -e "$ledger.tmp" ] && [ ! -L "$ledger.tmp" ] || { echo 'Unresolved tool state temporary file' >&2; exit 1; }
fi
if [ -e "$ledger" ]; then
    awk -F '\t' '
        NF != 2 || $1 !~ /^(profile|local|formula|cask|native)$/ ||
        $2 !~ /^[a-zA-Z0-9][a-zA-Z0-9@+_.\/-]*$/ {bad=1}
        $1 == "profile" {if (++profiles > 1 || $2 !~ /^(core|workstation)$/) bad=1; next}
        seen[$2]++ {bad=1}
        END {exit bad}
    ' "$ledger" || { echo 'Invalid tool ledger' >&2; exit 2; }
    while IFS=$'\t' read -r owner_provider owner_package; do
        case "$owner_provider" in
            profile) [ -n "$profile" ] || profile="$owner_package"; continue ;;
            local) local_tools+=("$owner_package"); continue ;;
            formula|cask|native) ;; *) echo 'Invalid tool ledger' >&2; exit 2 ;; esac
        case "$owner_package" in ''|-*|*[!a-zA-Z0-9@+_./-]*) echo 'Invalid tool ledger package' >&2; exit 2 ;; esac
        owned+=("$owner_package"); providers+=("$owner_provider")
    done < "$ledger"
fi
profile="${profile:-core}"
case "$profile" in core|workstation) ;; *) echo 'Invalid profile' >&2; exit 2 ;; esac
# Validate the whole manifest before performing any package operation.
awk -F '\t' '
    /^#/ || NF == 0 {next}
    NF != 6 || $1 !~ /^(core|workstation|legacy)$/ || $2 !~ /^(all|Darwin|Linux)$/ ||
    $3 !~ /^(formula|cask|native)$/ || $4 !~ /^[a-zA-Z0-9][a-zA-Z0-9@+_.\/-]*$/ ||
    $5 !~ /^[a-zA-Z0-9][a-zA-Z0-9_.-]*$/ || $6 !~ /^[-a-zA-Z0-9]+$/ {bad=1}
    seen[$4]++ {bad=1}
    END {exit bad}
' "$ROOT/scripts/dev-tools.tsv" || { echo 'Invalid tool manifest' >&2; exit 2; }
for owner_package in "${adopt[@]}" "${keep[@]}"; do
    if ! awk -F '\t' -v name="$owner_package" '$4 == name {found=1} END {exit !found}' "$ROOT/scripts/dev-tools.tsv"; then
        contains "$owner_package" "${owned[@]}" "${local_tools[@]}" || { echo "Unknown package: $owner_package" >&2; exit 2; }
    fi
    case "$owner_package" in ''|-*|*[!a-zA-Z0-9@+_./-]*) echo 'Invalid package argument' >&2; exit 2 ;; esac
done
for package in "${adopt[@]}"; do
    if contains "$package" "${keep[@]}" "${local_tools[@]}"; then
        echo "Cannot adopt a protected local tool: $package" >&2; exit 2
    fi
done
for package in "${keep[@]}"; do
    contains "$package" "${local_tools[@]}" || local_tools+=("$package")
done
save_ledger() {
    local n package
    printf 'profile\t%s\n' "$profile" > "$ledger.tmp" || return 1
    for package in "${local_tools[@]}"; do printf 'local\t%s\n' "$package" >> "$ledger.tmp"; done
    for ((n=0; n<${#owned[@]}; n++)); do
        [ -n "${owned[$n]}" ] && printf '%s\t%s\n' "${providers[$n]}" "${owned[$n]}" >> "$ledger.tmp"
    done
    mv "$ledger.tmp" "$ledger"
}
wanted=()
failed=0
selected=0
changed=0
tool_ok() {
    command -v "$exe" >/dev/null 2>&1 || return 1
    "$exe" "$flag" >/dev/null 2>&1 || return 1
    if [ "$exe" = python3 ]; then
        python3 -c 'import sys, tomllib; assert sys.version_info >= (3, 11)' >/dev/null 2>&1 || return 1
    fi
    # Require Mike Farah yq semantics, not an unrelated executable with this name.
    if [ "$exe" = yq ]; then
        [ "$(yq -n -o=json '.agent = true' 2>/dev/null)" = '{
  "agent": true
}' ] || return 1
    fi
}
unmanaged_conflict() {
    # Adding a Homebrew capability alongside an OS binary does not modify that
    # binary. A user-installed shadow or an existing package needs separate review.
    local resolved
    resolved="$(command -v "$exe" 2>/dev/null)"
    case "$resolved" in ''|/usr/bin/*|/bin/*|/usr/sbin/*|/sbin/*) ;; *) return 0 ;; esac
    [ "$provider" = native ] && return 1
    brew list "--$provider" --versions "$package" >/dev/null 2>&1
}
install_tool() {
    case "$provider" in
        formula|cask)
            command -v brew >/dev/null 2>&1 || return 1
            if [ "$package" = oven-sh/bun/bun ]; then
                brew tap oven-sh/bun || return 1
                # Older brew lacks trust; install itself remains authoritative.
                brew trust --formula oven-sh/bun/bun 2>/dev/null || true
            fi
            # Reject dependency upgrades before install: independently installed
            # tools/dependencies must not be changed as a side effect.
            local deps outdated dep runtime_deps runtime_present=1 has_bottle=0
            local bottle_args=()
            runtime_deps="$(brew deps "--$provider" "$package")" || return 1
            while IFS= read -r dep; do
                [ -n "$dep" ] || continue
                brew list --formula --versions "$dep" >/dev/null 2>&1 || runtime_present=0
            done <<< "$runtime_deps"
            if [ "$provider" = formula ] && [ "$runtime_present" -eq 1 ]; then
                has_bottle="$(brew info --json=v2 --formula "$package" | python3 -c '
import json, sys
value = json.load(sys.stdin)["formulae"][0]["versions"]["bottle"]
assert type(value) is bool
print(int(value))')" || return 1
            fi
            if [ "$has_bottle" -eq 1 ]; then
                # With runtime dependencies already installed, only their updates
                # matter. Force the target bottle so unused build tools stay unused.
                bottle_args=(--force-bottle)
                deps="$runtime_deps"
            else
                deps="$(brew deps --include-build --include-implicit "--$provider" "$package")" || return 1
            fi
            outdated="$(brew outdated --quiet --formula)" || return 1
            while IFS= read -r dep; do
                [ -n "$dep" ] || continue
                if awk -F / '{print $NF}' <<< "$outdated" | grep -Fx -- "${dep##*/}" >/dev/null; then
                    echo "BLOCKED: dependency needs an update: $dep; review separately" >&2
                    return 1
                fi
            done <<< "$deps"
            if contains "$package" "${owned[@]}" && brew list "--$provider" --versions "$package" >/dev/null 2>&1; then
                # Only an owned tool that failed its capability check may upgrade.
                brew upgrade "--$provider" "$package" "${bottle_args[@]}"
            else
                brew install "--$provider" "$package" "${bottle_args[@]}"
            fi
            ;;
        native)
            [ "$package" = claude ] || return 1
            local installer rc
            installer="$(mktemp)" || return 1
            rc=0
            curl -fsSL https://claude.ai/install.sh -o "$installer" && bash "$installer" || rc=1
            rm -f "$installer"
            return "$rc"
            ;;
        *) return 1 ;;
    esac
}
# Keep manifest input separate from installers and capability probes: either may
# consume stdin, which would otherwise skip subsequent tools and report success.
while IFS=$'\t' read -r group platform provider package exe flag <&3; do
    case "$group" in ''|'#'*) continue ;; core|workstation|legacy) ;; *) exit 2 ;; esac
    [ "$platform" = all ] || [ "$platform" = "$os" ] || continue
    if contains "$package" "${adopt[@]}" && ! contains "$package" "${owned[@]}"; then
        if { [ "$provider" = native ] && tool_ok; } || { [ "$provider" != native ] && brew list "--$provider" --versions "$package" >/dev/null 2>&1; }; then
            printf 'ADOPT\t%s\n' "$package"
            owned+=("$package"); providers+=("$provider")
        else
            echo "Cannot adopt absent/broken tool: $package" >&2; failed=$((failed + 1))
        fi
    fi
    if contains "$package" "${local_tools[@]}"; then
        printf 'KEEP_LOCAL\t%s\n' "$package"
        for ((n=0; n<${#owned[@]}; n++)); do
            [ "${owned[$n]}" != "$package" ] || owned[n]=""
        done
        if [ "$group" = core ] || { [ "$group" = workstation ] && [ "$profile" = workstation ]; }; then
            if ! tool_ok; then echo "BLOCKED: local tool unavailable: $package" >&2; failed=$((failed + 1)); fi
        fi
        continue
    fi
    # Inventory presence only; unselected executables may launch apps or hang.
    # Capability checks belong to the selected profile below.
    if [ "$mode" = plan ] && ! contains "$package" "${owned[@]}" && command -v "$exe" >/dev/null 2>&1; then
        printf 'UNMANAGED\t%s\t%s\n' "$package" "$(command -v "$exe")"
    fi
    [ "$group" = core ] || { [ "$group" = workstation ] && [ "$profile" = workstation ]; } || continue
    wanted+=("$package")
    selected=$((selected + 1))
    if tool_ok; then
        [ "$mode" = apply ] || printf 'OK\t%s\t%s\n' "$exe" "$(command -v "$exe")"
        continue
    fi
    printf 'MISSING_OR_BROKEN\t%s\t%s\n' "$exe" "$package"
    if [ "$mode" = apply ]; then
        if ! contains "$package" "${owned[@]}" && unmanaged_conflict; then
            echo "BLOCKED: existing unmanaged tool is broken/shadowed: $package" >&2
            failed=$((failed + 1))
            continue
        fi
        if install_tool; then
            hash -r
            # Preserve ownership even when the post-install capability check fails.
            if ! contains "$package" "${owned[@]}"; then owned+=("$package"); providers+=("$provider"); fi
            save_ledger || exit 1
            if tool_ok; then changed=$((changed + 1)); else
                printf 'FAILED\t%s (installed but unusable)\n' "$exe" >&2
                failed=$((failed + 1))
            fi
        else
            printf 'FAILED\t%s\n' "$exe" >&2
            failed=$((failed + 1))
        fi
    else
        failed=$((failed + 1))
    fi
done 3< "$ROOT/scripts/dev-tools.tsv" </dev/null
# Only ledger-owned packages absent from the desired definition may be removed.
# --keep releases ownership and preserves a locally needed tool.
for ((n=0; n<${#owned[@]}; n++)); do
    package="${owned[$n]}"; provider="${providers[$n]}"
    [ -n "$package" ] || continue
    contains "$package" "${wanted[@]}" && continue
    if contains "$package" "${local_tools[@]}"; then owned[n]=""; continue; fi
    printf 'REMOVE_MANAGED\t%s\n' "$package"
    if [ "$mode" = apply ] && [ "$failed" -eq 0 ]; then
        if [ "$provider" = native ]; then
            echo "BLOCKED: native removal requires manual handling: $package" >&2
            failed=$((failed + 1))
        elif ! brew list "--$provider" --versions "$package" >/dev/null 2>&1; then
            echo "BLOCKED: managed package absent or provider unavailable: $package" >&2
            failed=$((failed + 1))
        elif brew uninstall "--$provider" "$package"; then
            owned[n]=""
        else
            echo "BLOCKED: could not remove $package (check installed dependents)" >&2
            failed=$((failed + 1))
        fi
    elif [ "$mode" = check ]; then
        failed=$((failed + 1))
    fi
done
if [ "$mode" = apply ]; then save_ledger || exit 1; fi
printf 'tools: mode=%s profile=%s selected=%s installed=%s missing_or_failed=%s\n' "$mode" "$profile" "$selected" "$changed" "$failed"
[ "$mode" = plan ] || [ "$failed" -eq 0 ]
