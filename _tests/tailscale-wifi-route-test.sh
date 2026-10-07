#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/tailscale-wifi-route-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

FAKE_IP="$TMP/ip"
LOG="$TMP/ip.log"

cat > "$FAKE_IP" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FAKE_IP_LOG"

case "$*" in
    "-4 -o addr show dev wlo1 scope global")
        [[ "${FAKE_WIFI_DOWN:-0}" == "1" ]] || echo "3: wlo1    inet 10.50.25.163/22 brd 10.50.27.255 scope global wlo1"
        ;;
    "-4 route show default dev wlo1")
        [[ "${FAKE_WIFI_DOWN:-0}" == "1" ]] || echo "default via 10.50.27.250 dev wlo1 proto dhcp src 10.50.25.163 metric 600"
        ;;
    "-4 route show dev wlo1 scope link")
        [[ "${FAKE_WIFI_DOWN:-0}" == "1" ]] || echo "10.50.24.0/22 dev wlo1 proto kernel scope link src 10.50.25.163 metric 600"
        ;;
    "-4 rule del pref 5000")
        exit 2
        ;;
    "-4 route flush table 200")
        [[ "${FAKE_FLUSH_FAIL:-0}" == "1" ]] && exit 2
        ;;
    "-4 route replace table 200 10.50.24.0/22 dev wlo1 src 10.50.25.163")
        ;;
    "-4 route replace table 200 default via 10.50.27.250 dev wlo1 src 10.50.25.163")
        ;;
    "-4 rule add pref 5000 fwmark 0x80000/0xff0000 lookup 200")
        ;;
    "-4 route flush cache")
        ;;
    "-4 route get 1.1.1.1 mark 0x80000")
        echo "1.1.1.1 via 10.50.27.250 dev wlo1 src 10.50.25.163 mark 0x80000"
        ;;
    "-4 rule show")
        echo "5210: from all fwmark 0x80000/0xff0000 lookup main"
        ;;
    "-4 route show table 200")
        echo "default via 10.50.27.250 dev wlo1 src 10.50.25.163"
        ;;
    *)
        echo "unexpected fake ip call: $*" >&2
        exit 1
        ;;
esac
FAKE
chmod +x "$FAKE_IP"

export TAILSCALE_WIFI_IP_BIN="$FAKE_IP"
export TAILSCALE_WIFI_ALLOW_NON_ROOT=1
export TAILSCALE_WIFI_CONFIG="$TMP/nonexistent"
export WIFI_IFACE=wlo1
export ROUTE_TABLE=200
export RULE_PRIORITY=5000
export TAILSCALE_MARK=0x80000/0xff0000
export FAKE_IP_LOG="$LOG"

# Regression: an absent table 200 makes "ip route flush" fail. The helper must
# continue, build the table, and only then publish the policy rule.
: > "$LOG"
FAKE_FLUSH_FAIL=1 bash "$ROOT/_scripts/network/tailscale-wifi-route.sh" apply >/dev/null

replace_line="$(grep -n -- '-4 route replace table 200 default' "$LOG" | head -n1 | cut -d: -f1)"
rule_line="$(grep -n -- '-4 rule add pref 5000' "$LOG" | head -n1 | cut -d: -f1)"
[[ -n "$replace_line" && -n "$rule_line" && "$replace_line" -lt "$rule_line" ]]

if grep -q 'pref 5010' "$LOG"; then
    echo "fail-closed 5010 rule must not be created" >&2
    exit 1
fi

# When Wi-Fi is unavailable the custom rule is removed/left absent, allowing
# the stock Tailscale 5210 rule to handle traffic instead of locking it out.
: > "$LOG"
FAKE_WIFI_DOWN=1 bash "$ROOT/_scripts/network/tailscale-wifi-route.sh" apply >/dev/null
if grep -q -- '-4 rule add pref 5000' "$LOG"; then
    echo "policy rule must not be added without a complete Wi-Fi route" >&2
    exit 1
fi

grep -q -- '-4 route flush table 200' "$LOG"

printf 'Tailscale Wi-Fi routing tests passed\n'
