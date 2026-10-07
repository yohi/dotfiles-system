#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${TAILSCALE_WIFI_CONFIG:-/etc/default/tailscale-wifi-routing}"
if [[ -r "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

WIFI_IFACE="${WIFI_IFACE:-wlo1}"
ROUTE_TABLE="${ROUTE_TABLE:-200}"
RULE_PRIORITY="${RULE_PRIORITY:-5000}"
TAILSCALE_MARK="${TAILSCALE_MARK:-0x80000/0xff0000}"
PROBE_IPV4="${PROBE_IPV4:-1.1.1.1}"
IP_BIN="${TAILSCALE_WIFI_IP_BIN:-ip}"
MODE="${1:-apply}"

require_root() {
    if [[ "${TAILSCALE_WIFI_ALLOW_NON_ROOT:-0}" != "1" && "${EUID}" -ne 0 ]]; then
        echo "❌ root 権限が必要です" >&2
        exit 1
    fi
}

delete_policy_rule() {
    while "$IP_BIN" -4 rule del pref "$RULE_PRIORITY" 2>/dev/null; do
        :
    done
}

flush_policy_table() {
    # 未作成の routing table に対する flush は非0になるため許容する。
    "$IP_BIN" -4 route flush table "$ROUTE_TABLE" 2>/dev/null || true
}

disable_policy() {
    delete_policy_rule
    flush_policy_table
    "$IP_BIN" -4 route flush cache 2>/dev/null || true
}

discover_wifi_route() {
    WIFI_SRC="$("$IP_BIN" -4 -o addr show dev "$WIFI_IFACE" scope global 2>/dev/null | awk 'NR == 1 {split($4,a,"/"); print a[1]}' || true)"
    WIFI_GW="$("$IP_BIN" -4 route show default dev "$WIFI_IFACE" 2>/dev/null | awk 'NR == 1 {print $3}' || true)"
    WIFI_LINK="$("$IP_BIN" -4 route show dev "$WIFI_IFACE" scope link 2>/dev/null | awk '$1 != "default" {print $1; exit}' || true)"
}

apply_policy() {
    require_root
    discover_wifi_route

    if [[ -z "$WIFI_SRC" || -z "$WIFI_GW" || -z "$WIFI_LINK" ]]; then
        disable_policy
        echo "ℹ️  $WIFI_IFACE に完全な IPv4 経路がないため、Tailscale 標準ルーティングへ戻しました"
        return 0
    fi

    # rule を先に外し、table の更新途中に Tailscale を閉じ込めない。
    delete_policy_rule
    flush_policy_table

    if ! "$IP_BIN" -4 route replace table "$ROUTE_TABLE"         "$WIFI_LINK" dev "$WIFI_IFACE" src "$WIFI_SRC"; then
        disable_policy
        echo "❌ Wi-Fi link route の作成に失敗しました" >&2
        return 1
    fi

    if ! "$IP_BIN" -4 route replace table "$ROUTE_TABLE"         default via "$WIFI_GW" dev "$WIFI_IFACE" src "$WIFI_SRC"; then
        disable_policy
        echo "❌ Wi-Fi default route の作成に失敗しました" >&2
        return 1
    fi

    # routing table が完成した後でのみ policy rule を公開する。
    if ! "$IP_BIN" -4 rule add pref "$RULE_PRIORITY"         fwmark "$TAILSCALE_MARK" lookup "$ROUTE_TABLE"; then
        disable_policy
        echo "❌ Tailscale Wi-Fi policy rule の作成に失敗しました" >&2
        return 1
    fi

    "$IP_BIN" -4 route flush cache 2>/dev/null || true

    local resolved
    resolved="$("$IP_BIN" -4 route get "$PROBE_IPV4" mark 0x80000 2>/dev/null || true)"
    if [[ "$resolved" != *" dev $WIFI_IFACE "* && "$resolved" != *" dev $WIFI_IFACE" ]]; then
        disable_policy
        echo "❌ mark 0x80000 の経路が $WIFI_IFACE を使用していないためロールバックしました" >&2
        return 1
    fi

    echo "✅ Tailscale 外向き通信を $WIFI_IFACE 経由へ設定しました"
    echo "   $resolved"
}

remove_policy() {
    require_root
    disable_policy
    echo "✅ Tailscale Wi-Fi policy を撤去しました"
}

show_status() {
    echo "=== configuration ==="
    printf 'WIFI_IFACE=%s\nROUTE_TABLE=%s\nRULE_PRIORITY=%s\nTAILSCALE_MARK=%s\n'         "$WIFI_IFACE" "$ROUTE_TABLE" "$RULE_PRIORITY" "$TAILSCALE_MARK"
    echo "=== rules ==="
    "$IP_BIN" -4 rule show
    echo "=== table $ROUTE_TABLE ==="
    "$IP_BIN" -4 route show table "$ROUTE_TABLE" 2>/dev/null || true
    echo "=== marked route ==="
    "$IP_BIN" -4 route get "$PROBE_IPV4" mark 0x80000 2>/dev/null || true
}

case "$MODE" in
    apply)
        apply_policy
        ;;
    remove)
        remove_policy
        ;;
    status)
        show_status
        ;;
    *)
        echo "使用方法: $0 {apply|remove|status}" >&2
        exit 2
        ;;
esac
