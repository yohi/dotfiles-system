#!/bin/bash
# Zsh起動時間測定ツール
# 使用方法: ./zsh-benchmark.sh [回数]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 設定
DEFAULT_RUNS=5
RUNS=${1:-$DEFAULT_RUNS}
ZSHRC_PATH="$REPO_ROOT/zsh/zshrc"

# ミリ秒単位のエポックタイム取得
now_ms() {
    local t
    if t=$(date +%s%3N 2>/dev/null) && [[ ${#t} -gt 10 ]]; then
        echo "$t"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import time; print(int(time.time()*1000))"
    else
        echo "$(date +%s)000"
    fi
}

echo "🚀 Zsh起動時間ベンチマーク"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 対象zshrc: $ZSHRC_PATH"
echo "🔄 実行回数: $RUNS回"
echo "📊 測定開始: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 結果保存用配列
declare -a times

echo "⏱️  測定中..."
for i in $(seq 1 $RUNS); do
    echo -n "  Run $i/$RUNS: "

    # zsh起動時間を測定（リポジトリのzshrcを使用）
    start_time=$(now_ms)
    # ZDOTDIRを明示的に設定してリポジトリのzshrcをベンチマーク
    ZDOTDIR="$REPO_ROOT/zsh" zsh -i -c 'exit' 2>/dev/null
    end_time=$(now_ms)

    # 実行時間計算（ミリ秒）
    execution_time=$((end_time - start_time))
    times[$i]=$execution_time

    echo "${execution_time}ms"
done

echo ""
echo "📊 結果分析"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 統計計算
total=0
min=${times[1]}
max=${times[1]}

for time in "${times[@]}"; do
    total=$((total + time))
    if (( time < min )); then
        min=$time
    fi
    if (( time > max )); then
        max=$time
    fi
done

average=$((total / RUNS))

echo "📈 平均起動時間: ${average}ms"
echo "⚡ 最速時間: ${min}ms"
echo "🐌 最遅時間: ${max}ms"

# パフォーマンス評価
if (( average < 100 )); then
    echo "🎉 評価: 優秀 (100ms未満)"
elif (( average < 200 )); then
    echo "✅ 評価: 良好 (100-200ms)"
elif (( average < 500 )); then
    echo "⚠️  評価: 要改善 (200-500ms)"
else
    echo "🚨 評価: 重大 (500ms以上)"
fi

# 改善提案
echo ""
echo "💡 改善提案:"
if (( average > 200 )); then
    echo "  • Lazy loading の実装を検討"
    echo "  • プラグインの見直し"
    echo "  • 重い処理の条件分岐化"
fi

if (( average > 100 )); then
    echo "  • 不要な環境変数の削除"
    echo "  • PATH設定の最適化"
fi

echo "  • 定期的なベンチマーク実行"

# 結果をログファイルに保存
LOG_FILE="$SCRIPT_DIR/performance-history.log"
echo "$(date '+%Y-%m-%d %H:%M:%S'),$average,$min,$max,$RUNS" >> "$LOG_FILE"

echo ""
echo "📝 ログ保存: $LOG_FILE"
echo "🏁 ベンチマーク完了"
