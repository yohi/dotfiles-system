#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$HERE/../_bin/herdr-oauth-remote"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/herdr-oauth-test.XXXXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/bin" "$ROOT/runtime"
cat >"$ROOT/bin/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$MOCK_SSH_LOG"
a=("$@"); socket="" op=""
for ((i=0;i<${#a[@]};i++)); do
  [[ "${a[i]}" != -S ]] || socket="${a[i+1]}"
  [[ "${a[i]}" != -O ]] || op="${a[i+1]}"
done
if [[ "$op" == exit ]]; then
  [[ -z "$socket" ]] || rm -f -- "$socket"
  exit 0
fi
[[ "${MOCK_SSH_FAIL:-0}" != 1 ]] || exit 23
[[ -n "$socket" ]] || exit 24
: > "$socket"
EOF
cat >"$ROOT/bin/herdr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_HERDR_LOG"
exit "${MOCK_HERDR_STATUS:-0}"
EOF
chmod +x "$ROOT/bin/"*
export PATH="$ROOT/bin:$PATH" XDG_RUNTIME_DIR="$ROOT/runtime"
export MOCK_SSH_LOG="$ROOT/ssh.log" MOCK_HERDR_LOG="$ROOT/herdr.log"
: > "$MOCK_SSH_LOG"; : > "$MOCK_HERDR_LOG"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reset() { : > "$MOCK_SSH_LOG"; : > "$MOCK_HERDR_LOG"; }
clean_check() {
  [[ -z "$(find "$ROOT/runtime" -mindepth 1 -print -quit)" ]] ||
    fail "temporary SSH socket leaked"
}
bash "$APP" --port 1455 workbox >/dev/null
grep -Fq -- '-L 127.0.0.1:1455:127.0.0.1:1455' "$MOCK_SSH_LOG" || fail "forward not loopback"
grep -Fq -- '-O exit' "$MOCK_SSH_LOG" || fail "tunnel not closed"
grep -Fxq -- '--remote workbox' "$MOCK_HERDR_LOG" || fail "wrong Herdr args"
clean_check; echo 'ok - forwarding and cleanup'
reset
bash "$APP" workbox --port 1455 --session agents >/dev/null
grep -Fxq -- '--remote workbox --session agents' "$MOCK_HERDR_LOG" || fail "session not passed"
clean_check; echo 'ok - named session'
reset
for p in 0 65536 abc 999999; do
  if bash "$APP" --port "$p" workbox >/dev/null 2>&1; then fail "accepted invalid $p"; fi
done
if bash "$APP" --port 1455 -oProxyCommand=bad >/dev/null 2>&1; then
  fail "accepted SSH option as target"
fi
[[ ! -s "$MOCK_SSH_LOG" ]] || fail "SSH called on invalid input"
echo 'ok - invalid input fails before SSH'
reset
if MOCK_SSH_FAIL=1 bash "$APP" --port 1455 workbox >/dev/null 2>&1; then
  fail "ignored SSH error"
fi
[[ ! -s "$MOCK_HERDR_LOG" ]] || fail "Herdr started after tunnel failure"
clean_check; echo 'ok - SSH failure prevents launch'
reset
if MOCK_HERDR_STATUS=17 bash "$APP" --port 1455 workbox >/dev/null 2>&1; then
  fail "ignored Herdr error"
else
  [[ "$?" == 17 ]] || fail "unexpected Herdr exit status"
fi
grep -Fq -- '-O exit' "$MOCK_SSH_LOG" || fail "tunnel survived Herdr error"
clean_check; echo 'ok - Herdr error cleanup'
