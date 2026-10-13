#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$SCRIPT_DIR/../_bin/herdr-oauth-forward"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/herdr-oauth-forward-test.XXXXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/ssh" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_SSH_LOG"
exit "${MOCK_SSH_STATUS:-0}"
MOCK
chmod +x "$TEST_ROOT/bin/ssh"
export PATH="$TEST_ROOT/bin:$PATH" MOCK_SSH_LOG="$TEST_ROOT/ssh-args"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

bash "$APP" --port 1455 workbox >/dev/null
printf '%s\n' '-L' '127.0.0.1:1455:127.0.0.1:1455' | while IFS= read -r item; do
  grep -Fxq -- "$item" "$MOCK_SSH_LOG" || fail "missing argument $item"
done
grep -Fxq -- '-S' "$MOCK_SSH_LOG" || fail 'missing SSH multiplex isolation'
grep -Fxq -- 'none' "$MOCK_SSH_LOG" || fail 'missing isolated connection'
echo 'ok - loopback forwarding only'

for value in 0 65536 abc 999999; do
  : > "$MOCK_SSH_LOG"
  if bash "$APP" --port "$value" workbox >/dev/null 2>&1; then
    fail "accepted invalid port $value"
  fi
  [[ ! -s "$MOCK_SSH_LOG" ]] || fail 'SSH called on invalid port'
done
echo 'ok - invalid ports denied before SSH'

: > "$MOCK_SSH_LOG"
if bash "$APP" --port 1455 --ProxyCommand=evil >/dev/null 2>&1; then
  fail 'accepted SSH option injection'
fi
[[ ! -s "$MOCK_SSH_LOG" ]] || fail 'SSH called on invalid target'
echo 'ok - SSH option injection denied'

if MOCK_SSH_STATUS=23 bash "$APP" --port 1455 workbox >/dev/null 2>&1; then
  fail 'swallowed SSH setup failure'
else
  [[ "$?" -eq 23 ]] || fail 'did not preserve SSH exit status'
fi
echo 'ok - SSH error propagated'

bash "$APP" --port 01455 workbox >/dev/null
grep -Fxq -- '127.0.0.1:1455:127.0.0.1:1455' "$MOCK_SSH_LOG" ||
  fail 'did not normalize a decimal port'
echo 'ok - decimal port normalized'
