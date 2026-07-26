#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAKE_BIN="$(command -v make)"
BASE_PATH="/usr/bin:/bin"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-system-test.XXXXXX")"
LAST_OUTPUT=""
LAST_STATUS=0
TESTS_RUN=0
TESTS_FAILED=0

cleanup() {
	rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

fail() {
	printf '    %s\n' "$1" >&2
	return 1
}

assert_status() {
	local expected="$1"
	if [[ "$LAST_STATUS" -ne "$expected" ]]; then
		printf '    command output:\n%s\n' "$LAST_OUTPUT" >&2
		fail "expected status $expected, got $LAST_STATUS"
	fi
}

assert_success() {
	if [[ "$LAST_STATUS" -ne 0 ]]; then
		printf '    command output:\n%s\n' "$LAST_OUTPUT" >&2
		fail "expected success, got status $LAST_STATUS"
	fi
}

assert_failure() {
	if [[ "$LAST_STATUS" -eq 0 ]]; then
		printf '    command output:\n%s\n' "$LAST_OUTPUT" >&2
		fail "expected failure, got status 0"
	fi
}

assert_file() {
	[[ -f "$1" ]] || fail "expected regular file: $1"
}

assert_directory() {
	[[ -d "$1" ]] || fail "expected directory: $1"
}

assert_symlink() {
	[[ -L "$1" ]] || fail "expected symlink: $1"
}

assert_absent() {
	[[ ! -e "$1" && ! -L "$1" ]] || fail "expected path to be absent: $1"
}

assert_equal() {
	local expected="$1"
	local actual="$2"
	[[ "$actual" == "$expected" ]] || fail "expected '$expected', got '$actual'"
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	[[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_not_contains() {
	local haystack="$1"
	local needle="$2"
	[[ "$haystack" != *"$needle"* ]] || fail "output unexpectedly contained: $needle"
}

new_home() {
	local name="$1"
	local home="$TEMP_ROOT/$name"
	mkdir -p "$home"
	printf '%s\n' "$home"
}

run_make_target() {
	local home="$1"
	local target="$2"
	shift 2
	if LAST_OUTPUT="$(
		env HOME="$home" PATH="$BASE_PATH" \
			"$MAKE_BIN" --no-print-directory -C "$REPO_ROOT" \
			"HOME_DIR=$home" \
			"BREW_CANDIDATES=$home/.linuxbrew/bin/brew" \
			"$target" "$@" 2>&1
	)"; then
		LAST_STATUS=0
	else
		LAST_STATUS=$?
	fi
}

create_working_brew() {
	local home="$1"
	local prefix="$home/.linuxbrew"
	mkdir -p "$prefix/bin" "$prefix/lib/docker/cli-plugins"
	cat >"$prefix/bin/brew" <<'BREW'
#!/usr/bin/env bash
set -euo pipefail
prefix="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
	shellenv)
		printf 'PATH="%s/bin:$PATH"; export PATH\n' "$prefix"
		;;
	--prefix)
		printf '%s\n' "$prefix"
		;;
	*)
		exit 64
		;;
esac
BREW
	chmod 0755 "$prefix/bin/brew"
	printf '#!/bin/sh\nexit 0\n' >"$prefix/lib/docker/cli-plugins/docker-compose"
	printf '#!/bin/sh\nexit 0\n' >"$prefix/lib/docker/cli-plugins/docker-buildx"
	chmod 0755 "$prefix/lib/docker/cli-plugins/docker-compose" "$prefix/lib/docker/cli-plugins/docker-buildx"
}

run_test() {
	local name="$1"
	local function_name="$2"
	TESTS_RUN=$((TESTS_RUN + 1))
	if "$function_name"; then
		printf 'ok %d - %s\n' "$TESTS_RUN" "$name"
	else
		printf 'not ok %d - %s\n' "$TESTS_RUN" "$name"
		TESTS_FAILED=$((TESTS_FAILED + 1))
	fi
}

test_plugin_discovery_outside_path() {
	local home
	home="$(new_home plugin-discovery)"
	create_working_brew "$home"
	run_make_target "$home" setup-docker-cli-plugins
	assert_success || return
	assert_symlink "$home/.docker/cli-plugins/docker-compose" || return
	assert_symlink "$home/.docker/cli-plugins/docker-buildx" || return
	assert_equal "$home/.linuxbrew/lib/docker/cli-plugins/docker-compose" "$(readlink "$home/.docker/cli-plugins/docker-compose")" || return
	assert_equal "$home/.linuxbrew/lib/docker/cli-plugins/docker-buildx" "$(readlink "$home/.docker/cli-plugins/docker-buildx")" || return
}

test_repeated_plugin_setup() {
	local home
	home="$(new_home plugin-repeat)"
	create_working_brew "$home"
	run_make_target "$home" setup-docker-cli-plugins
	assert_success || return
	run_make_target "$home" setup-docker-cli-plugins
	assert_success || return
	assert_symlink "$home/.docker/cli-plugins/docker-compose" || return
	assert_symlink "$home/.docker/cli-plugins/docker-buildx" || return
	assert_equal "$home/.linuxbrew/lib/docker/cli-plugins/docker-compose" "$(readlink "$home/.docker/cli-plugins/docker-compose")" || return
	assert_equal "$home/.linuxbrew/lib/docker/cli-plugins/docker-buildx" "$(readlink "$home/.docker/cli-plugins/docker-buildx")" || return
}

test_absent_homebrew() {
	local home
	home="$(new_home brew-absent)"
	run_make_target "$home" setup-docker-cli-plugins
	assert_success || return
	assert_absent "$home/.docker/cli-plugins/docker-compose" || return
	assert_absent "$home/.docker/cli-plugins/docker-buildx" || return
}

test_broken_discovered_homebrew() {
	local home
	home="$(new_home brew-broken)"
	mkdir -p "$home/.linuxbrew/bin"
	cat >"$home/.linuxbrew/bin/brew" <<'BREW'
#!/bin/sh
if [ "${1:-}" = shellenv ]; then
	exit 23
fi
exit 64
BREW
	chmod 0755 "$home/.linuxbrew/bin/brew"
	run_make_target "$home" setup-docker-cli-plugins
	assert_failure || return
	assert_absent "$home/.docker/cli-plugins/docker-compose" || return
	assert_absent "$home/.docker/cli-plugins/docker-buildx" || return
}

test_plugin_discovery_with_space_in_home() {
	local home
	home="$(new_home "plugin home with spaces")"
	create_working_brew "$home"
	run_make_target "$home" setup-docker-cli-plugins
	assert_success || return
	assert_symlink "$home/.docker/cli-plugins/docker-compose" || return
	assert_symlink "$home/.docker/cli-plugins/docker-buildx" || return
	assert_equal "$home/.linuxbrew/lib/docker/cli-plugins/docker-compose" "$(readlink "$home/.docker/cli-plugins/docker-compose")" || return
	assert_equal "$home/.linuxbrew/lib/docker/cli-plugins/docker-buildx" "$(readlink "$home/.docker/cli-plugins/docker-buildx")" || return
}

test_existing_plugin_file_is_untouched() {
	local home destination sentinel mode_before
	home="$(new_home plugin-file)"
	create_working_brew "$home"
	destination="$home/.docker/cli-plugins/docker-compose"
	sentinel="existing-plugin-file-sentinel"
	mkdir -p "$(dirname "$destination")"
	printf '%s\n' "$sentinel" >"$destination"
	chmod 0400 "$destination"
	mode_before="$(stat -c '%a' "$destination")"
	run_make_target "$home" setup-docker-cli-plugins
	assert_failure || return
	[[ -f "$destination" && ! -L "$destination" ]] || fail "expected existing plugin regular file to remain unchanged" || return
	assert_equal "$sentinel" "$(<"$destination")" || return
	assert_equal "$mode_before" "$(stat -c '%a' "$destination")" || return
	assert_not_contains "$LAST_OUTPUT" "✅ docker-compose をリンクしました" || return
}

test_existing_plugin_directory_is_untouched() {
	local home destination
	home="$(new_home plugin-directory)"
	create_working_brew "$home"
	destination="$home/.docker/cli-plugins/docker-compose"
	mkdir -p "$destination"
	printf 'existing-plugin-directory-sentinel\n' >"$destination/sentinel"
	run_make_target "$home" setup-docker-cli-plugins
	assert_failure || return
	assert_directory "$destination" || return
	assert_equal "existing-plugin-directory-sentinel" "$(<"$destination/sentinel")" || return
	assert_absent "$destination/docker-compose" || return
	assert_not_contains "$LAST_OUTPUT" "✅ docker-compose をリンクしました" || return
}

test_blocked_plugin_parent_fails() {
	local home sentinel
	home="$(new_home plugin-parent-blocked)"
	create_working_brew "$home"
	sentinel="blocked-plugin-parent-sentinel"
	printf '%s\n' "$sentinel" >"$home/.docker"
	run_make_target "$home" setup-docker-cli-plugins
	assert_failure || return
	[[ -f "$home/.docker" && ! -L "$home/.docker" ]] || fail "expected blocked plugin parent file to remain unchanged" || return
	assert_equal "$sentinel" "$(<"$home/.docker")" || return
	assert_not_contains "$LAST_OUTPUT" "✅ docker-compose をリンクしました" || return
	assert_not_contains "$LAST_OUTPUT" "✅ docker-buildx をリンクしました" || return
}

test_absent_config_bootstrap() {
	local home
	home="$(new_home config-absent)"
	run_make_target "$home" setup-docker-config
	assert_success || return
	assert_file "$home/.docker/config.json" || return
	cmp -s "$REPO_ROOT/docker/config.json" "$home/.docker/config.json" || fail "copied config differs from repository config" || return
	assert_equal "600" "$(stat -c '%a' "$home/.docker/config.json")" || return
}

test_missing_config_source_fails_before_parent_creation() {
	local home missing_repo
	home="$(new_home config-source-missing)"
	missing_repo="$TEMP_ROOT/missing-repository"
	run_make_target "$home" setup-docker-config "REPO_ROOT=$missing_repo"
	assert_failure || return
	assert_absent "$home/.docker" || return
	assert_not_contains "$LAST_OUTPUT" "✅ Docker設定を初期化しました" || return
}

test_blocked_config_parent_fails() {
	local home sentinel mode_before
	home="$(new_home config-parent-blocked)"
	sentinel="blocked-config-parent-sentinel"
	printf '%s\n' "$sentinel" >"$home/.docker"
	chmod 0400 "$home/.docker"
	mode_before="$(stat -c '%a' "$home/.docker")"
	run_make_target "$home" setup-docker-config
	assert_failure || return
	[[ -f "$home/.docker" && ! -L "$home/.docker" ]] || fail "expected blocked config parent file to remain unchanged" || return
	assert_equal "$sentinel" "$(<"$home/.docker")" || return
	assert_equal "$mode_before" "$(stat -c '%a' "$home/.docker")" || return
	assert_not_contains "$LAST_OUTPUT" "✅ Docker設定を初期化しました" || return
}

test_config_bootstrap_is_idempotent() {
	local home inode_before
	home="$(new_home config-idempotent)"
	run_make_target "$home" setup-docker-config
	assert_success || return
	inode_before="$(stat -c '%i' "$home/.docker/config.json")"
	run_make_target "$home" setup-docker-config
	assert_success || return
	assert_equal "$inode_before" "$(stat -c '%i' "$home/.docker/config.json")" || return
	assert_equal "600" "$(stat -c '%a' "$home/.docker/config.json")" || return
}

test_existing_config_file_is_untouched() {
	local home sentinel mode_before
	home="$(new_home config-file)"
	sentinel="existing-config-sentinel"
	mkdir -p "$home/.docker"
	printf '%s\n' "$sentinel" >"$home/.docker/config.json"
	chmod 0400 "$home/.docker/config.json"
	mode_before="$(stat -c '%a' "$home/.docker/config.json")"
	run_make_target "$home" setup-docker-config
	assert_success || return
	assert_equal "$sentinel" "$(<"$home/.docker/config.json")" || return
	assert_equal "$mode_before" "$(stat -c '%a' "$home/.docker/config.json")" || return
	assert_not_contains "$LAST_OUTPUT" "$sentinel" || return
}

test_existing_config_directory_is_untouched() {
	local home
	home="$(new_home config-directory)"
	mkdir -p "$home/.docker/config.json"
	printf 'directory-sentinel\n' >"$home/.docker/config.json/sentinel"
	run_make_target "$home" setup-docker-config
	assert_success || return
	assert_directory "$home/.docker/config.json" || return
	assert_equal "directory-sentinel" "$(<"$home/.docker/config.json/sentinel")" || return
}

test_existing_config_symlink_is_untouched() {
	local home target
	home="$(new_home config-symlink)"
	target="$home/config-target"
	printf 'symlink-sentinel\n' >"$target"
	chmod 0640 "$target"
	mkdir -p "$home/.docker"
	ln -s "$target" "$home/.docker/config.json"
	run_make_target "$home" setup-docker-config
	assert_success || return
	assert_symlink "$home/.docker/config.json" || return
	assert_equal "$target" "$(readlink "$home/.docker/config.json")" || return
	assert_equal "symlink-sentinel" "$(<"$target")" || return
	assert_equal "640" "$(stat -c '%a' "$target")" || return
}

test_dangling_config_symlink_is_untouched() {
	local home target
	home="$(new_home config-dangling-symlink)"
	target="$home/missing-config-target"
	mkdir -p "$home/.docker"
	ln -s "$target" "$home/.docker/config.json"
	run_make_target "$home" setup-docker-config
	assert_success || return
	assert_symlink "$home/.docker/config.json" || return
	assert_equal "$target" "$(readlink "$home/.docker/config.json")" || return
	assert_absent "$target" || return
}

test_prepare_system_with_space_in_home() {
	local home
	home="$TEMP_ROOT/prepare-home $TEMP_ROOT/space-home"
	assert_absent "$home" || return
	run_make_target "$home" prepare-system
	assert_success || return
	assert_directory "$home" || return
	assert_symlink "$home/.Brewfile" || return
	assert_equal "$REPO_ROOT/Brewfile" "$(readlink "$home/.Brewfile")" || return
}

test_normal_setup_wiring_without_execution() {
	local home
	home="$(new_home setup-wiring)"
	if LAST_OUTPUT="$(
		env HOME="$home" PATH="$BASE_PATH" \
			"$MAKE_BIN" --no-print-directory -n -C "$REPO_ROOT" \
			"HOME_DIR=$home" \
			"BREW_CANDIDATES=$home/.linuxbrew/bin/brew" \
			setup-system 2>&1
	)"; then
		LAST_STATUS=0
	else
		LAST_STATUS=$?
	fi
	assert_success || return
	assert_contains "$LAST_OUTPUT" "setup-docker-cli-plugins" || return
	assert_contains "$LAST_OUTPUT" "setup-docker-config" || return
	assert_absent "$home/.docker/config.json" || return
}

if PATH="$BASE_PATH" command -v brew >/dev/null 2>&1; then
	printf 'Refusing to run: brew exists in isolated test PATH (%s).\n' "$BASE_PATH" >&2
	exit 1
fi

run_test "discovers Homebrew outside PATH and links resolved plugins" test_plugin_discovery_outside_path
run_test "repeated plugin setup keeps correct links" test_repeated_plugin_setup
run_test "absent Homebrew is skipped" test_absent_homebrew
run_test "broken discovered Homebrew fails without links" test_broken_discovered_homebrew
run_test "Homebrew candidate remains safe when HOME contains spaces" test_plugin_discovery_with_space_in_home
run_test "existing plugin regular file is untouched" test_existing_plugin_file_is_untouched
run_test "existing plugin directory is untouched" test_existing_plugin_directory_is_untouched
run_test "blocked plugin parent propagates failure" test_blocked_plugin_parent_fails
run_test "absent Docker config is copied with mode 0600" test_absent_config_bootstrap
run_test "missing Docker config source fails before parent creation" test_missing_config_source_fails_before_parent_creation
run_test "blocked Docker config parent propagates failure" test_blocked_config_parent_fails
run_test "Docker config bootstrap is idempotent" test_config_bootstrap_is_idempotent
run_test "existing Docker config file and permissions are untouched" test_existing_config_file_is_untouched
run_test "existing Docker config directory is untouched" test_existing_config_directory_is_untouched
run_test "existing Docker config symlink is untouched" test_existing_config_symlink_is_untouched
run_test "dangling Docker config symlink is untouched" test_dangling_config_symlink_is_untouched
run_test "prepare-system supports a HOME path containing spaces" test_prepare_system_with_space_in_home
run_test "normal setup wires Docker targets without executing recipes" test_normal_setup_wiring_without_execution

if [[ "$TESTS_FAILED" -ne 0 ]]; then
	printf '%d of %d tests failed.\n' "$TESTS_FAILED" "$TESTS_RUN" >&2
	exit 1
fi

printf 'All %d Docker setup tests passed.\n' "$TESTS_RUN"
