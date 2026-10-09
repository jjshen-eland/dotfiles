#!/usr/bin/env bash
# Sourced by module-shell.sh; ROOT, TMP and assertions are supplied by the harness.
# shellcheck disable=SC2154,SC2034
echo "▶ 16c. check-network-isolation-collisions.py（OrbStack PF isolation table）"
NIC="$ROOT/scripts/check-network-isolation-collisions.py"
nic_fix="$TMP/network-isolation-collisions"
mkdir -p "$nic_fix"
cat > "$nic_fix/ifconfig" <<'EOF'
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
    inet 10.10.12.140 netmask 0xffffff00 broadcast 10.10.12.255
bridge100: flags=8a63<UP,BROADCAST,SMART,RUNNING,ALLMULTI,SIMPLEX,MULTICAST> mtu 1500
    inet 192.168.139.3 netmask 0xfffffe00 broadcast 192.168.139.255
EOF
cat > "$nic_fix/rules" <<'EOF'
pass quick on bridge100 inet from 192.168.138.0/23 to 192.168.138.0/23 flags any keep state
block drop quick inet from <network_isolation_table_v4> to <network_isolation_table_v4>
EOF
cat > "$nic_fix/table-collision" <<'EOF'
   10.10.12.0/24
   192.168.138.0/23
EOF
cat > "$nic_fix/table-clean" <<'EOF'
   10.77.91.0/24
   192.168.138.0/23
EOF
cat > "$nic_fix/table-supernet" <<'EOF'
   10.10.0.0/16
EOF
cat > "$nic_fix/routes-clean" <<'EOF'
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            10.10.12.253       UGScg                 en0
10.10.12/24        link#22            UCSc                  en0      !
192.168.138/23     link#34            UC              bridge100      !
EOF
# 每一種介面型態各一：實體 NIC（shorthand 路由）、設定好但未 UP 的 NIC、
# loopback、point-to-point。後三者本來就沒有直連網段路由，誤報它們會讓整個檢查失去可信度。
cat > "$nic_fix/ifconfig-routes" <<'EOF'
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
    inet 10.10.12.140 netmask 0xffffff00 broadcast 10.10.12.255
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
    inet 192.168.20.120 netmask 0xffffff00 broadcast 192.168.20.255
en2: flags=8863<BROADCAST,SMART,SIMPLEX,MULTICAST> mtu 1500
    inet 172.16.9.5 netmask 0xffffff00 broadcast 172.16.9.255
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
    inet 127.0.0.1 netmask 0xff000000
utun10: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1280
    inet 100.98.139.6 --> 100.98.139.6 netmask 0xffffffff
bridge100: flags=8a63<UP,BROADCAST,SMART,RUNNING,ALLMULTI,SIMPLEX,MULTICAST> mtu 1500
    inet 192.168.139.3 netmask 0xfffffe00 broadcast 192.168.139.255
EOF
cat > "$nic_fix/routes-shorthand" <<'EOF'
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            10.10.12.253       UGScg                 en0
10.10.12/24        link#22            UCSc                  en0      !
192.168.20         link#24            UCS                   en1      !
127                127.0.0.1          UCS                   lo0
192.168.138/23     link#34            UC              bridge100      !
EOF
# 2026-09-02 實機故障的形狀：en0 的 /24 整條消失，只剩兩條 /32 host route。
cat > "$nic_fix/routes-missing" <<'EOF'
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            10.10.12.253       UGScg                 en0
10.10.12.140/32    link#22            UCS                   en0      !
10.10.12.253/32    link#22            UCS                   en0      !
192.168.20         link#24            UCS                   en1      !
127                127.0.0.1          UCS                   lo0
192.168.138/23     link#34            UC              bridge100      !
EOF
# 網段還在路由表裡，但綁在容器 bridge 上——同樣不可達，且比整條消失更難目視發現。
cat > "$nic_fix/routes-hijacked" <<'EOF'
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            10.10.12.253       UGScg                 en0
10.10.12/24        link#47            UC              bridge104      !
192.168.20         link#24            UCS                   en1      !
127                127.0.0.1          UCS                   lo0
192.168.138/23     link#34            UC              bridge100      !
EOF

if [ -x "$NIC" ]; then
    ok "network isolation collision detector 存在且可執行"

    nic_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-collision" \
        --routes-file "$nic_fix/routes-clean" 2>&1)"
    nic_rc=$?
    assert_rc "實體 LAN 與 isolation CIDR 撞號 → exit 1" 1 "$nic_rc"
    if grep -q '^verdict: STOP$' <<< "$nic_out" \
        && grep -q '^reason: NETWORK_ISOLATION_COLLISION$' <<< "$nic_out" \
        && grep -q '^source: fixture (NOT live-host proof)$' <<< "$nic_out" \
        && grep -q 'collision: isolation=10.10.12.0/24 interface=en0 local=10.10.12.0/24 address=10.10.12.140' <<< "$nic_out"; then
        ok "碰撞告警交付 exact 證據，且 fixture 不冒充 live-host proof"
    else bad "碰撞告警缺 deterministic 證據：$nic_out"; fi
    if grep -q 'collision:.*interface=bridge100' <<< "$nic_out"; then
        bad "anchor 明示放行的 managed bridge 被誤報為 host collision"
    else ok "anchor 明示配對的 managed bridge 不誤報"; fi
    if grep -q '^action: STOP container attach/create' <<< "$nic_out" \
        && grep -q '^action: use auto allocation plus DNS/test config' <<< "$nic_out" \
        && grep -q '^action: NEVER auto-delete PF entries; request authorization before restart or firewall changes' <<< "$nic_out"; then
        ok "告警附 agent 必須採取的安全處置且禁止自動破壞 PF"
    else bad "碰撞告警沒有完整處置契約：$nic_out"; fi

    nic_clean_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" \
        --routes-file "$nic_fix/routes-clean" 2>&1)"
    assert_rc "只有 managed bridge／不相交 entry → exit 0" 0 $?
    if grep -q '^verdict: CLEAN$' <<< "$nic_clean_out" \
        && grep -q '^managed-exemptions: 1$' <<< "$nic_clean_out"; then
        ok "乾淨結果揭露 managed bridge exemption 數量"
    else bad "乾淨結果或 exemption evidence 不符：$nic_clean_out"; fi

    nic_super_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-supernet" \
        --routes-file "$nic_fix/routes-clean" 2>&1)"
    assert_rc "isolation supernet 包住 LAN → 仍判碰撞" 1 $?
    if grep -q 'collision: isolation=10.10.0.0/16 interface=en0 local=10.10.12.0/24' <<< "$nic_super_out"; then
        ok "CIDR overlap 用網段交集判斷，不只比字串相等"
    else bad "supernet overlap 未被正確揭露：$nic_super_out"; fi

    nic_unknown_out="$("$NIC" --ifconfig-file "$nic_fix/missing" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" \
        --routes-file "$nic_fix/routes-clean" 2>&1)"
    assert_rc "讀不到 proof input → exit 2" 2 $?
    if grep -q '^verdict: STOP$' <<< "$nic_unknown_out" \
        && grep -q '^reason: PROOF_INPUT_UNAVAILABLE$' <<< "$nic_unknown_out"; then
        ok "權限／讀取證據不足時 fail closed，不冒充 CLEAN"
    else bad "proof input 不可得未 fail closed：$nic_unknown_out"; fi

    # 殘留 B：PF 表可以完全乾淨，同時同網段主機根本連不進來。
    # 2026-09-02 實機即為此形狀——殘留 A 的檢查當下回報 CLEAN，SSH 卻已經斷了。
    nic_route_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig-routes" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" \
        --routes-file "$nic_fix/routes-missing" 2>&1)"
    assert_rc "PF 乾淨但實體介面缺直連路由 → exit 1" 1 $?
    if grep -q '^verdict: STOP$' <<< "$nic_route_out" \
        && grep -q '^reason: MISSING_INTERFACE_ROUTE$' <<< "$nic_route_out" \
        && grep -q 'missing-route: interface=en0 expected=10.10.12.0/24 address=10.10.12.140 claimed-by=none' <<< "$nic_route_out"; then
        ok "缺失直連路由被揭露且附 exact 介面／網段證據"
    else bad "缺失直連路由未被揭露：$nic_route_out"; fi
    if grep -q '^action: restoring requires explicit authorization: sudo route -n add -net 10.10.12.0/24 -interface en0$' <<< "$nic_route_out" \
        && grep -q '^action: NEVER auto-modify routes; request authorization before route or interface changes$' <<< "$nic_route_out"; then
        ok "缺失路由告警附可直接執行的修復指令且禁止自動改路由"
    else bad "缺失路由告警沒有完整處置契約：$nic_route_out"; fi
    if grep -q 'missing-route:.*interface=en2' <<< "$nic_route_out" \
        || grep -q 'missing-route:.*interface=lo0' <<< "$nic_route_out" \
        || grep -q 'missing-route:.*interface=utun10' <<< "$nic_route_out"; then
        bad "未 UP 的 NIC／loopback／point-to-point 被誤報缺路由：$nic_route_out"
    else ok "未 UP 的 NIC、loopback、point-to-point 不誤報"; fi
    if grep -q '^checked-direct-routes: 3$' <<< "$nic_route_out"; then
        ok "直連路由檢查涵蓋數揭露為 3（en0／en1／bridge100）"
    else bad "直連路由檢查涵蓋數不符：$nic_route_out"; fi

    nic_hijack_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig-routes" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" \
        --routes-file "$nic_fix/routes-hijacked" 2>&1)"
    assert_rc "網段路由被容器 bridge 接管 → exit 1" 1 $?
    if grep -q 'missing-route: interface=en0 expected=10.10.12.0/24 address=10.10.12.140 claimed-by=bridge104' <<< "$nic_hijack_out"; then
        ok "路由存在但綁錯介面時點名接管者，不因網段還在就放行"
    else bad "介面接管未被揭露：$nic_hijack_out"; fi

    nic_short_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig-routes" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" \
        --routes-file "$nic_fix/routes-shorthand" 2>&1)"
    assert_rc "netstat classful shorthand 完整覆蓋各介面 → exit 0" 0 $?
    if grep -q '^verdict: CLEAN$' <<< "$nic_short_out"; then
        ok "netstat 省略尾段的 shorthand（192.168.20＝/24）解析正確，不誤判為缺失"
    else bad "shorthand 路由被誤判：$nic_short_out"; fi

    nic_partial_out="$("$NIC" --ifconfig-file "$nic_fix/ifconfig" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" 2>&1)"
    assert_rc "fixture 缺 --routes-file → exit 2" 2 $?
    if grep -q '^reason: PROOF_INPUT_UNAVAILABLE$' <<< "$nic_partial_out" \
        && grep -q 'and --routes-file' <<< "$nic_partial_out"; then
        ok "證據不完整時 fail closed，不拿舊的三項證據冒充完整檢查"
    else bad "fixture 證據不完整未 fail closed：$nic_partial_out"; fi

    nic_noflags_fix="$nic_fix/ifconfig-noflags"
    printf 'en0:\n    inet 10.10.12.140 netmask 0xffffff00 broadcast 10.10.12.255\n' > "$nic_noflags_fix"
    nic_noflags_out="$("$NIC" --ifconfig-file "$nic_noflags_fix" \
        --rules-file "$nic_fix/rules" --table-file "$nic_fix/table-clean" \
        --routes-file "$nic_fix/routes-clean" 2>&1)"
    assert_rc "介面 flags 不可解析 → exit 2" 2 $?
    if grep -q '^reason: PROOF_INPUT_UNAVAILABLE$' <<< "$nic_noflags_out"; then
        ok "讀不到介面 flags 時不猜 UP／down，直接 fail closed"
    else bad "介面 flags 缺失未 fail closed：$nic_noflags_out"; fi
else
    bad "network isolation collision detector 不存在或不可執行：$NIC"
fi
