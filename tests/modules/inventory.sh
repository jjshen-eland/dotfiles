#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 3. inventory.sh 解析"
# 在子 shell 內 source，避免污染本 shell
inv() { (INVENTORY_FILE="$1" && export INVENTORY_FILE && shift && source "$ROOT/scripts/lib/inventory.sh" && "$@"); }

assert_eq "inventory_hosts 忽略註解/空行、保序" \
    "$(printf 'alpha\nbeta\ngamma')" \
    "$(inv "$FIX/inventory.conf" inventory_hosts)"

assert_eq "inventory_ip 查得到" "10.0.0.10" "$(inv "$FIX/inventory.conf" inventory_ip beta)"

inv "$FIX/inventory.conf" inventory_ip nonexistent >/dev/null 2>&1
assert_rc "inventory_ip 查不到 → exit 1" 1 $?

inv "$FIX/inventory.conf" inventory_has alpha
assert_rc "inventory_has 存在 → exit 0" 0 $?

inv "$FIX/inventory.conf" inventory_has zz
assert_rc "inventory_has 不存在 → exit 1" 1 $?

assert_eq "inventory_entries tab 分隔" \
    "$(printf 'alpha\t10.0.0.2\nbeta\t10.0.0.10\ngamma\t172.16.1.1')" \
    "$(inv "$FIX/inventory.conf" inventory_entries)"

INVENTORY_FILE="/nonexistent/path.conf" bash -c \
    'source "'"$ROOT"'/scripts/lib/inventory.sh"; inventory_hosts' >/dev/null 2>&1
assert_rc "inventory 檔不存在 → exit 1" 1 $?

echo "▶ 4. inventory_append"
cp "$FIX/inventory.conf" "$TMP/inv-append.conf"
inv "$TMP/inv-append.conf" inventory_append delta 10.0.0.99
assert_rc "append 新 alias → exit 0" 0 $?
assert_eq "append 後可查回 IP" "10.0.0.99" "$(inv "$TMP/inv-append.conf" inventory_ip delta)"

inv "$TMP/inv-append.conf" inventory_append alpha 1.1.1.1 2>/dev/null
assert_rc "append 重複 alias 被拒 → exit 1" 1 $?

inv "$TMP/inv-append.conf" inventory_append onlyalias "" 2>/dev/null
assert_rc "append 缺 IP 被拒 → exit 1" 1 $?

echo "▶ 5. render-etc-hosts.sh"
expected_block="$(
    echo "# pilot-infra-start"
    printf '%-14s %s\n' 10.0.0.2 alpha 10.0.0.10 beta 172.16.1.1 gamma
    echo "# pilot-infra-end"
)"
actual_block="$(INVENTORY_FILE="$FIX/inventory.conf" "$ROOT/scripts/render-etc-hosts.sh" --stdout)"
assert_eq "--stdout 區塊內容 + IP 數值排序（10.0.0.2 < 10.0.0.10）" "$expected_block" "$actual_block"

cp "$FIX/etc-hosts-before" "$TMP/hosts"
INVENTORY_FILE="$FIX/inventory.conf" "$ROOT/scripts/render-etc-hosts.sh" --apply "$TMP/hosts" >/dev/null
if grep -q "stale-entry" "$TMP/hosts"; then bad "--apply 未移除舊區塊"; else ok "--apply 移除舊區塊"; fi
if grep -q "^127.0.0.1 localhost$" "$TMP/hosts"; then ok "--apply 保留區塊外內容"; else bad "--apply 弄丟區塊外內容"; fi

cp "$TMP/hosts" "$TMP/hosts.once"
INVENTORY_FILE="$FIX/inventory.conf" "$ROOT/scripts/render-etc-hosts.sh" --apply "$TMP/hosts" >/dev/null
if diff -q "$TMP/hosts" "$TMP/hosts.once" >/dev/null; then ok "--apply 冪等（跑兩次內容不變）"; else bad "--apply 不冪等"; fi

INVENTORY_FILE="$FIX/inventory.conf" "$ROOT/scripts/render-etc-hosts.sh" --apply "$TMP/no-such-file" >/dev/null 2>&1
assert_rc "--apply 目標不存在 → exit 1" 1 $?

echo "▶ 6. render-ssh-config.sh"
cp "$FIX/ssh-config-before" "$TMP/sshconf"
out="$(INVENTORY_FILE="$FIX/inventory.conf" SSH_CONFIG_FILE="$TMP/sshconf" "$ROOT/scripts/render-ssh-config.sh" --stdout)"
if echo "$out" | grep -q "HostName 10.0.0.10"; then ok "--stdout 含渲染的 host"; else bad "--stdout 缺渲染的 host"; fi
if echo "$out" | grep -q "stale-host"; then bad "--stdout 未替換舊區塊"; else ok "--stdout 替換舊區塊"; fi
if echo "$out" | grep -q "^Include config.local$"; then ok "--stdout 保留區塊前內容"; else bad "--stdout 弄丟區塊前內容"; fi
if echo "$out" | grep -q "IdentityFile ~/.ssh/id_github"; then ok "--stdout 保留區塊後內容"; else bad "--stdout 弄丟區塊後內容"; fi

INVENTORY_FILE="$FIX/inventory.conf" SSH_CONFIG_FILE="$TMP/sshconf" "$ROOT/scripts/render-ssh-config.sh" --check >/dev/null 2>&1
assert_rc "--check 不同步 → exit 1" 1 $?

INVENTORY_FILE="$FIX/inventory.conf" SSH_CONFIG_FILE="$TMP/sshconf" "$ROOT/scripts/render-ssh-config.sh" >/dev/null
INVENTORY_FILE="$FIX/inventory.conf" SSH_CONFIG_FILE="$TMP/sshconf" "$ROOT/scripts/render-ssh-config.sh" --check >/dev/null 2>&1
assert_rc "write 後 --check 同步 → exit 0" 0 $?

cp "$TMP/sshconf" "$TMP/sshconf.once"
INVENTORY_FILE="$FIX/inventory.conf" SSH_CONFIG_FILE="$TMP/sshconf" "$ROOT/scripts/render-ssh-config.sh" >/dev/null
if diff -q "$TMP/sshconf" "$TMP/sshconf.once" >/dev/null; then ok "write 冪等"; else bad "write 不冪等"; fi

# marker 防呆：兩組 BEGIN → 必須拒絕
{ cat "$FIX/ssh-config-before"; echo "# BEGIN inventory hosts (dup)"; } > "$TMP/sshconf-dup"
INVENTORY_FILE="$FIX/inventory.conf" SSH_CONFIG_FILE="$TMP/sshconf-dup" "$ROOT/scripts/render-ssh-config.sh" --stdout >/dev/null 2>&1
assert_rc "marker 數量異常 → exit 1" 1 $?

echo "▶ 7. add-new-host.sh --dry-run 煙霧測試"
before_status="$(git -C "$ROOT" status --porcelain -- scripts/inventory.conf ssh/config)"
"$ROOT/scripts/add-new-host.sh" --dry-run zzeval-smoke 10.99.99.99 >/dev/null 2>&1
assert_rc "dry-run 新 alias → exit 0" 0 $?
after_status="$(git -C "$ROOT" status --porcelain -- scripts/inventory.conf ssh/config)"
assert_eq "dry-run 不動 inventory.conf / ssh/config" "$before_status" "$after_status"

"$ROOT/scripts/add-new-host.sh" --dry-run eagle03 1.2.3.4 >/dev/null 2>&1
assert_rc "dry-run 重複 alias 被拒 → exit 1" 1 $?
