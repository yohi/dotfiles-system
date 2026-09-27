#!/bin/bash
# CPU電力・静音最適化スクリプト (AIエージェント並列特化 & 多環境互換)
#
# 他のPC（低スペックPCやノートPC、AMD環境等）でも安全に動作するよう
# CPUの種類・コア数・利用可能なカーネルインターフェースを自動判定します。

set -euo pipefail

MODE="${1:-agent}"
SYSFS_ROOT="${CPU_POWER_SYSFS_ROOT:-/sys}"
CPU_SYSFS="$SYSFS_ROOT/devices/system/cpu"
RAPL_SYSFS="$SYSFS_ROOT/class/powercap/intel-rapl/intel-rapl:0"
STATE_DIR="${CPU_POWER_STATE_DIR:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cpu-power-optimization}"
STATE_FILE="$STATE_DIR/original-settings"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 環境判定
detect_environment() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo -e "${YELLOW}⏭️  Linux以外のOSのため、CPU最適化をスキップします。${NC}"
        return 1
    fi

    CPU_CORES=$(nproc 2>/dev/null || echo 1)
    CPU_MODEL="${CPU_POWER_CPU_MODEL:-$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^[ \t]*//' || echo "Unknown")}"
    return 0
}

# 2. ステータス表示
show_status() {
    echo -e "${BLUE}=== CPU & Power Status ===${NC}"
    echo "Model      : ${CPU_MODEL:-Unknown}"
    echo "Cores      : ${CPU_CORES:-Unknown}"

    if [ -f "$CPU_SYSFS/cpu0/cpufreq/energy_performance_preference" ]; then
        EPP=$(cat "$CPU_SYSFS/cpu0/cpufreq/energy_performance_preference" 2>/dev/null || echo "N/A")
        echo "EPP        : $EPP"
    fi

    if [ -f "$CPU_SYSFS/intel_pstate/max_perf_pct" ]; then
        MAX_PERF=$(cat "$CPU_SYSFS/intel_pstate/max_perf_pct" 2>/dev/null || echo "N/A")
        echo "Max Perf % : ${MAX_PERF}%"
    fi

    if [ -f "$CPU_SYSFS/intel_pstate/no_turbo" ]; then
        NO_TURBO=$(cat "$CPU_SYSFS/intel_pstate/no_turbo" 2>/dev/null || echo "N/A")
        echo "No Turbo   : $NO_TURBO (1=Disabled, 0=Enabled)"
    fi

    if [ -f "$RAPL_SYSFS/constraint_0_power_limit_uw" ]; then
        PL1_UW=$(cat "$RAPL_SYSFS/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
        PL1_W=$((PL1_UW / 1000000))
        echo "RAPL PL1   : ${PL1_W}W"
    fi
    if [ -f "$RAPL_SYSFS/constraint_1_power_limit_uw" ]; then
        PL2_UW=$(cat "$RAPL_SYSFS/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
        echo "RAPL PL2   : $((PL2_UW / 1000000))W"
    fi

    echo -e "\n${BLUE}=== Current Temperatures ===${NC}"
    if command -v sensors >/dev/null 2>&1; then
        sensors 2>/dev/null | grep -E "Package id|Core 0|temp1" | head -n 5 || true
    fi
}

write_setting() {
    local path="$1" value="$2" actual
    if [ -w "$path" ]; then
        printf '%s\n' "$value" > "$path" || return 1
    else
        printf '%s\n' "$value" | sudo tee "$path" > /dev/null || return 1
    fi
    actual=$(< "$path")
    if [ "$actual" != "$value" ]; then
        echo "❌ 設定の検証に失敗しました: $path" >&2
        return 1
    fi
}

setting_paths() {
    local file
    for file in "$CPU_SYSFS"/cpu*/cpufreq/energy_performance_preference \
        "$CPU_SYSFS/intel_pstate/max_perf_pct" \
        "$CPU_SYSFS/intel_pstate/no_turbo" \
        "$RAPL_SYSFS/constraint_0_power_limit_uw" \
        "$RAPL_SYSFS/constraint_1_power_limit_uw"; do
        [ -f "$file" ] && printf '%s\n' "$file"
    done
}

save_original_settings() {
    local path value temporary
    [ -s "$STATE_FILE" ] && return 0
    umask 077
    mkdir -p "$STATE_DIR"
    temporary=$(mktemp "$STATE_DIR/.original-settings.XXXXXX") || return 1
    while IFS= read -r path; do
        if ! IFS= read -r value < "$path"; then
            echo "❌ 元の設定を読み取れません: $path" >&2
            unlink "$temporary"
            return 1
        fi
        if ! printf '%s\t%s\n' "$path" "$value" >> "$temporary"; then
            echo "❌ 一時状態ファイルへ書き込めません" >&2
            unlink "$temporary"
            return 1
        fi
    done < <(setting_paths)
    if [ ! -s "$temporary" ] || ! mv -f -- "$temporary" "$STATE_FILE"; then
        echo '❌ 元の設定を完全な状態で保存できません' >&2
        unlink "$temporary"
        return 1
    fi
}

restore_settings() {
    local path value failed=0
    if [ ! -s "$STATE_FILE" ]; then
        echo '❌ 復元する元の設定がありません' >&2
        return 1
    fi
    while IFS=$'\t' read -r path value; do
        if ! write_setting "$path" "$value"; then
            failed=1
        fi
    done < "$STATE_FILE"
    [ "$failed" -eq 0 ] || return 1
    : > "$STATE_FILE"
    show_status
}

# 3. 最適化の適用
apply_profile() {
    local target_mode="$1"
    echo -e "${GREEN}⚙️  CPUプロファイル「$target_mode」を適用中...${NC}"

    case "$target_mode" in
        agent)
            # AIエージェント並列特化: 高並列時の発熱・電力急増を抑え、静音かつ高スループットを維持
            TARGET_EPP="balance_power"
            TARGET_MAX_PERF="80"
            TARGET_NO_TURBO="0"
            TARGET_PL1_W="125"
            TARGET_PL2_W="150"
            ;;
        quiet)
            # 極限静音モード: ファン回転を最低限に抑制
            TARGET_EPP="power"
            TARGET_MAX_PERF="65"
            TARGET_NO_TURBO="1"
            TARGET_PL1_W="90"
            TARGET_PL2_W="100"
            ;;
        *)
            echo -e "${RED}❌ 未知のモード: $target_mode${NC} (指定可能: agent, quiet)"
            exit 1
            ;;
    esac

    if [[ "$CPU_MODEL" != *"Core(TM) Ultra 7 270K Plus"* ]]; then
        echo '❌ この電力プロファイルは Core Ultra 7 270K Plus 専用です' >&2
        return 1
    fi
    local file governor failed=0
    for file in "$CPU_SYSFS/cpu0/cpufreq/energy_performance_preference" \
        "$CPU_SYSFS/intel_pstate/max_perf_pct" \
        "$CPU_SYSFS/intel_pstate/no_turbo" \
        "$RAPL_SYSFS/name" \
        "$RAPL_SYSFS/constraint_0_name" \
        "$RAPL_SYSFS/constraint_1_name" \
        "$RAPL_SYSFS/constraint_0_power_limit_uw" \
        "$RAPL_SYSFS/constraint_1_power_limit_uw"; do
        if [ ! -f "$file" ]; then
            echo "❌ 必要な CPU 電力制御インターフェースがありません: $file" >&2
            return 1
        fi
    done
    if [ "$(< "$RAPL_SYSFS/name")" != package-0 ] || \
        [ "$(< "$RAPL_SYSFS/constraint_0_name")" != long_term ] || \
        [ "$(< "$RAPL_SYSFS/constraint_1_name")" != short_term ]; then
        echo '❌ 対応する CPU 電力制御インターフェースがありません' >&2
        return 1
    fi
    for file in "$CPU_SYSFS"/cpu*/cpufreq/energy_performance_preference; do
        [ -f "$file" ] || continue
        governor="${file%/energy_performance_preference}/scaling_governor"
        if [ ! -r "$governor" ]; then
            echo "❌ governor を確認できないため、設定を適用できません: $governor" >&2
            return 1
        fi
        if [ "$(< "$governor")" = performance ]; then
            echo "❌ $governor が performance のため、設定を適用できません。利用可能な governor を確認し、EPP に対応する governor へ手動で切り替えてから再実行してください。" >&2
            return 1
        fi
    done
    save_original_settings || return 1

    # 1. EPP (Energy Performance Preference) の設定
    for file in "$CPU_SYSFS"/cpu*/cpufreq/energy_performance_preference; do
        [ -f "$file" ] || continue
        write_setting "$file" "$TARGET_EPP" || failed=1
    done

    # 2. intel_pstate の max_perf_pct 設定
    write_setting "$CPU_SYSFS/intel_pstate/max_perf_pct" "$TARGET_MAX_PERF" || failed=1

    # 3. Turbo Boost 設定
    write_setting "$CPU_SYSFS/intel_pstate/no_turbo" "$TARGET_NO_TURBO" || failed=1

    # 4. RAPL 電力上限 (PL1: 持続 / PL2: 短時間スパイク) の設定 (利用可能な場合のみ)
    write_setting "$RAPL_SYSFS/constraint_0_power_limit_uw" "$((TARGET_PL1_W * 1000000))" || failed=1
    write_setting "$RAPL_SYSFS/constraint_1_power_limit_uw" "$((TARGET_PL2_W * 1000000))" || failed=1
    if [ "$failed" -ne 0 ]; then
        echo '❌ プロファイルの適用に失敗しました。復元を試みます' >&2
        restore_settings || true
        return 1
    fi

    echo -e "${GREEN}✅ プロファイル「$target_mode」の適用が完了しました。${NC}\n"
    show_status
}

# メイン処理
detect_environment || exit 0

if [ "$MODE" = hint ]; then
    if [[ "$CPU_MODEL" == *"Core(TM) Ultra 7 270K Plus"* ]]; then
        printf '\n%s\n' '💡 CPU電力・静音プロファイルを利用できます:' '   make cpu-power-agent'
    fi
    exit 0
fi

case "$MODE" in
    status)
        show_status
        ;;
    auto)
        echo '⏭️  自動適用は無効です。make cpu-power-agent で明示的に適用してください。'
        ;;
    restore)
        mkdir -p "$STATE_DIR"
        exec {lock_fd}> "$STATE_DIR/lock"
        flock -x "$lock_fd"
        restore_settings
        ;;
    agent|quiet)
        mkdir -p "$STATE_DIR"
        exec {lock_fd}> "$STATE_DIR/lock"
        flock -x "$lock_fd"
        apply_profile "$MODE"
        ;;
    *)
        echo "使用方法: $0 {status|agent|quiet|restore|auto}"
        exit 1
        ;;
esac
