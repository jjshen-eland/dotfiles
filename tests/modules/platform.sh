#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 25. cross-platform contract（CI、Ubuntu preflight、plugin hints）"
CI_FILE="$ROOT/.github/workflows/test.yml"
ci_contract_out="$(python3 "$ROOT/tests/ci-contract.py" "$CI_FILE" 2>&1)"
ci_contract_rc=$?
if [ "$ci_contract_rc" -eq 0 ]; then
    ok "GitHub Actions 結構：PR-only、唯讀、雙 OS 與完整 suite"
else
    bad "GitHub Actions contract 失敗（exit ${ci_contract_rc}）"
    printf '%s\n' "$ci_contract_out"
fi

# GitHub runners 的 init.defaultBranch 未必與開發機一致。bare fixture 若不明示 HEAD，
# 後續 push main 再 clone 會得到 unborn checkout，造成 Git 行為測試大量連鎖假紅。
bare_init_without_branch="$(grep -nE '[g]it init [^#]*--bare' "$ROOT/tests/modules/"*.sh \
    | grep -vE -- '(^|[[:space:]])-b[[:space:]]' || true)"
if [ -z "$bare_init_without_branch" ]; then
    ok "bare Git fixtures 明示 initial branch，不依賴 host init.defaultBranch"
else
    bad "bare Git fixtures 仍依賴 host init.defaultBranch（${bare_init_without_branch}）"
fi

PLATFORM_CHECK="$ROOT/scripts/check-supported-platform.sh"
mkdir -p "$TMP/platform"
printf 'ID=ubuntu\nVERSION_ID="24.04"\nPRETTY_NAME="Ubuntu 24.04"\n' > "$TMP/platform/ubuntu-24"
printf 'ID=ubuntu\nVERSION_ID="22.04"\nPRETTY_NAME="Ubuntu 22.04"\n' > "$TMP/platform/ubuntu-22"
printf 'ID=fedora\nVERSION_ID="42"\nPRETTY_NAME="Fedora 42"\n' > "$TMP/platform/fedora"
out=$(DOTFILES_UNAME=Linux DOTFILES_OS_RELEASE="$TMP/platform/ubuntu-24" bash "$PLATFORM_CHECK" 2>&1); rc=$?
assert_rc "Ubuntu 24.04 preflight → exit 0" 0 "$rc"
out=$(DOTFILES_UNAME=Linux DOTFILES_OS_RELEASE="$TMP/platform/ubuntu-22" bash "$PLATFORM_CHECK" 2>&1); rc=$?
assert_rc "Ubuntu 22.04 preflight → exit 2" 2 "$rc"
if grep -q 'Ubuntu 24.04+' <<< "$out"; then ok "舊 Ubuntu 錯誤訊息列出支援下限"; else bad "舊 Ubuntu 錯誤訊息未列支援下限"; fi
out=$(DOTFILES_UNAME=Linux DOTFILES_OS_RELEASE="$TMP/platform/fedora" bash "$PLATFORM_CHECK" 2>&1); rc=$?
assert_rc "非 Ubuntu Linux preflight → exit 2" 2 "$rc"
out=$(DOTFILES_UNAME=Darwin bash "$PLATFORM_CHECK" 2>&1); rc=$?
assert_rc "Darwin preflight → exit 0" 0 "$rc"
out=$(DOTFILES_UNAME=Linux DOTFILES_OS_RELEASE="$TMP/platform/ubuntu-24" bash "$ROOT/bootstrap.sh" --check-platform 2>&1); rc=$?
assert_rc "bootstrap Ubuntu 24.04 preflight → exit 0 且不進 mutation" 0 "$rc"
out=$(DOTFILES_UNAME=Linux DOTFILES_OS_RELEASE="$TMP/platform/fedora" bash "$ROOT/bootstrap.sh" --check-platform 2>&1); rc=$?
assert_rc "bootstrap 非 Ubuntu preflight → exit 2 且不進 mutation" 2 "$rc"
platform_line=$(grep -n 'scripts/check-supported-platform.sh' "$ROOT/setup-linux-env.sh" | head -1 | cut -d: -f1)
first_mutation_line=$(grep -nE 'apt (update|install)|brew install' "$ROOT/setup-linux-env.sh" | head -1 | cut -d: -f1)
if [ -n "$platform_line" ] && [ -n "$first_mutation_line" ] && [ "$platform_line" -lt "$first_mutation_line" ]; then
    ok "Linux setup 在第一個 package mutation 前執行 platform preflight"
else
    bad "Linux setup 的 platform preflight 太晚，可能先改 unsupported host"
fi

PLUGIN_HINTS="$ROOT/scripts/claude-plugin-install-hints.sh"
cat > "$TMP/platform/settings.json" <<'PLUGINEOF'
{"enabledPlugins":{"zeta@example":true,"alpha@example":true,"disabled@example":false}}
PLUGINEOF
out=$(CLAUDE_SETTINGS="$TMP/platform/settings.json" bash "$PLUGIN_HINTS" 2>&1); rc=$?
assert_rc "plugin hints 可讀 settings → exit 0" 0 "$rc"
assert_eq "plugin hints 只列 enabled 且排序穩定" \
    $'claude plugins install alpha@example\nclaude plugins install zeta@example' "$out"
for setup_file in setup-mac-env.sh setup-linux-env.sh; do
    if grep -q 'scripts/claude-plugin-install-hints.sh' "$ROOT/$setup_file"; then
        ok "$setup_file 使用共用 plugin hints helper"
    else
        bad "$setup_file 未使用共用 plugin hints helper"
    fi
done
