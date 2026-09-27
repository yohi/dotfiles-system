#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cpu-power-test.XXXXXX")"
SYSFS="$TEMP_ROOT/sys"
STATE="$TEMP_ROOT/state"
CPU="$SYSFS/devices/system/cpu"
RAPL="$SYSFS/class/powercap/intel-rapl/intel-rapl:0"
mkdir -p "$CPU/cpu0/cpufreq" "$CPU/cpu1/cpufreq" "$CPU/intel_pstate" "$RAPL" "$STATE"
printf '%s\n' balance_performance > "$CPU/cpu0/cpufreq/energy_performance_preference"
printf '%s\n' performance > "$CPU/cpu1/cpufreq/energy_performance_preference"
printf '%s\n' schedutil > "$CPU/cpu0/cpufreq/scaling_governor"
printf '%s\n' performance > "$CPU/cpu1/cpufreq/scaling_governor"
printf '%s\n' 100 > "$CPU/intel_pstate/max_perf_pct"
printf '%s\n' 0 > "$CPU/intel_pstate/no_turbo"
printf '%s\n' 125000000 > "$RAPL/constraint_0_power_limit_uw"
printf '%s\n' 250000000 > "$RAPL/constraint_1_power_limit_uw"
printf '%s\n' long_term > "$RAPL/constraint_0_name"
printf '%s\n' short_term > "$RAPL/constraint_1_name"
printf '%s\n' package-0 > "$RAPL/name"

run_profile() {
    CPU_POWER_SYSFS_ROOT="$SYSFS" CPU_POWER_STATE_DIR="$STATE" \
        CPU_POWER_CPU_MODEL='Intel(R) Core(TM) Ultra 7 270K Plus' \
        bash "$SCRIPT_DIR/_scripts/cpu-power-optimization.sh" "$1" >/dev/null
}

run_hint() {
    CPU_POWER_SYSFS_ROOT="$SYSFS" CPU_POWER_STATE_DIR="$STATE" \
        CPU_POWER_CPU_MODEL="$1" \
        bash "$SCRIPT_DIR/_scripts/cpu-power-optimization.sh" hint
}

SUPPORTED_HINT="$(run_hint 'Intel(R) Core(TM) Ultra 7 270K Plus')"
[[ "$SUPPORTED_HINT" == *'make cpu-power-agent'* ]]
UNSUPPORTED_HINT="$(run_hint 'Intel(R) Core(TM) Ultra 5 250K')"
[[ -z "$UNSUPPORTED_HINT" ]]
[[ $(< "$CPU/intel_pstate/max_perf_pct") == 100 ]]
[[ $(< "$RAPL/constraint_1_power_limit_uw") == 250000000 ]]
[[ ! -s "$STATE/original-settings" ]]

run_profile auto
[[ $(< "$CPU/intel_pstate/max_perf_pct") == 100 ]]
[[ $(< "$RAPL/constraint_1_power_limit_uw") == 250000000 ]]

if run_profile agent 2>"$TEMP_ROOT/profile-error"; then
    printf 'agent profile must fail when a CPU uses the performance governor\n' >&2
    exit 1
fi
[[ $(< "$CPU/intel_pstate/max_perf_pct") == 100 ]]
[[ $(< "$CPU/intel_pstate/no_turbo") == 0 ]]
[[ $(< "$RAPL/constraint_0_power_limit_uw") == 125000000 ]]
[[ $(< "$RAPL/constraint_1_power_limit_uw") == 250000000 ]]
[[ $(< "$CPU/cpu0/cpufreq/energy_performance_preference") == balance_performance ]]
[[ $(< "$CPU/cpu1/cpufreq/energy_performance_preference") == performance ]]
[[ ! -s "$STATE/original-settings" ]]
[[ "$(< "$TEMP_ROOT/profile-error")" == *'performance'* ]]

printf '%s\n' schedutil > "$CPU/cpu1/cpufreq/scaling_governor"
run_profile agent
[[ $(< "$CPU/intel_pstate/max_perf_pct") == 80 ]]
[[ $(< "$RAPL/constraint_1_power_limit_uw") == 150000000 ]]
[[ $(< "$CPU/cpu0/cpufreq/energy_performance_preference") == balance_power ]]
[[ $(< "$CPU/cpu1/cpufreq/energy_performance_preference") == balance_power ]]
[[ -f "$STATE/lock" ]]
[[ $(wc -l < "$STATE/original-settings") -eq 6 ]]

run_profile quiet
run_profile restore
[[ $(< "$CPU/cpu0/cpufreq/energy_performance_preference") == balance_performance ]]
[[ $(< "$CPU/cpu1/cpufreq/energy_performance_preference") == performance ]]
[[ $(< "$CPU/intel_pstate/max_perf_pct") == 100 ]]
[[ $(< "$CPU/intel_pstate/no_turbo") == 0 ]]
[[ $(< "$RAPL/constraint_0_power_limit_uw") == 125000000 ]]
[[ $(< "$RAPL/constraint_1_power_limit_uw") == 250000000 ]]

if run_profile restore 2>/dev/null; then
    printf 'restore must fail without a saved baseline\n' >&2
    exit 1
fi

printf 'CPU power profile tests passed\n'
