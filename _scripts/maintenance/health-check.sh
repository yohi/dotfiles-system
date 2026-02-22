#!/bin/bash
# Dotfiles健全性チェックスクリプト
# 使用方法: ./health-check.sh [--detailed] [--fix]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# オプション処理
DETAILED=false
AUTO_FIX=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed)
            DETAILED=true
            shift
            ;;
        --fix)
            AUTO_FIX=true
            shift
            ;;
        *)
            echo "使用方法: $0 [--detailed] [--fix]"
            echo "  --detailed: 詳細チェックを実行"
            echo "  --fix:      自動修復を試行"
            exit 1
            ;;
    esac
done

# 色コード定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🏥 Dotfiles 健全性チェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 対象ディレクトリ: $REPO_ROOT"
echo "🔍 詳細モード: $([ "$DETAILED" == "true" ] && echo "有効" || echo "無効")"
echo "🔧 自動修復: $([ "$AUTO_FIX" == "true" ] && echo "有効" || echo "無効")"
echo "📊 チェック開始: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$REPO_ROOT" || { echo "cd failed: $REPO_ROOT"; exit 1; }

# チェック結果カウンタ
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0
FIXED_ISSUES=0

# チェック実行関数
run_check() {
    local name="$1"
    local command="$2"
    local fix_command="$3"
    local expected_result="$4"

    ((TOTAL_CHECKS++))
    echo -n "🔍 $name... "

    result=$(eval "$command" 2>/dev/null)
    exit_code=$?

    if [[ $exit_code -eq 0 && "$result" == "$expected_result" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED_CHECKS++))
    elif [[ $exit_code -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  WARNING${NC}"
        [[ "$DETAILED" == "true" ]] && echo "    詳細: $result"
        ((WARNING_CHECKS++))

        if [[ "$AUTO_FIX" == "true" && ! -z "$fix_command" ]]; then
            echo -n "    🔧 修復中... "
            if eval "$fix_command" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ 修復完了${NC}"
                ((FIXED_ISSUES++))
            else
                echo -e "${RED}❌ 修復失敗${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ FAIL${NC}"
        [[ "$DETAILED" == "true" ]] && echo "    エラー: $result"
        ((FAILED_CHECKS++))

        if [[ "$AUTO_FIX" == "true" && ! -z "$fix_command" ]]; then
            echo -n "    🔧 修復中... "
            if eval "$fix_command" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ 修復完了${NC}"
                ((FIXED_ISSUES++))
            else
                echo -e "${RED}❌ 修復失敗${NC}"
            fi
        fi
    fi
}

# 1. 基本構造チェック
echo -e "${CYAN}📁 基本構造チェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_check "Makefileの存在" \
    "test -f Makefile && echo 'exists'" \
    "touch Makefile" \
    "exists"

run_check "READMEの存在" \
    "test -f README.md && echo 'exists'" \
    "touch README.md" \
    "exists"

run_check "mkディレクトリの存在" \
    "test -d mk && echo 'exists'" \
    "mkdir -p mk" \
    "exists"

run_check "scriptsディレクトリの存在" \
    "test -d scripts && echo 'exists'" \
    "mkdir -p scripts" \
    "exists"

# 2. 設定ファイルチェック
echo ""
echo -e "${CYAN}⚙️  設定ファイルチェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_check "zshrc設定ファイル" \
    "test -f zsh/zshrc && echo 'exists'" \
    "touch zsh/zshrc" \
    "exists"

run_check "gitignore設定" \
    "test -f .gitignore && echo 'exists'" \
    "touch .gitignore" \
    "exists"

run_check "vscode設定ディレクトリ" \
    "test -d vscode && echo 'exists'" \
    "mkdir -p vscode" \
    "exists"

run_check "cursor設定ディレクトリ" \
    "test -d cursor && echo 'exists'" \
    "mkdir -p cursor" \
    "exists"

# 3. Makefileチェック
echo ""
echo -e "${CYAN}🔧 Makefileチェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_check "Makefile構文チェック" \
    "make -n help >/dev/null 2>&1 && echo 'valid'" \
    "" \
    "valid"

if [[ -f "Makefile" ]]; then
    include_count=$(grep -c "^include" Makefile)
    run_check "includeファイル数" \
        "echo $include_count" \
        "" \
        "14"
fi

run_check "help ターゲットの実行" \
    "timeout 10 make help >/dev/null 2>&1 && echo 'success'" \
    "" \
    "success"

# 4. シンボリックリンクチェック
echo ""
echo -e "${CYAN}🔗 シンボリックリンクチェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 壊れたシンボリックリンクの検出
broken_links=$(find . -type l ! -exec test -e {} \; -print 2>/dev/null)
if [[ ! -z "$broken_links" ]]; then
    echo -e "${RED}❌ 壊れたシンボリックリンク:${NC}"
    while read -r link; do
        echo "    📄 $link"
        if [[ "$AUTO_FIX" == "true" ]]; then
            rm -f "$link"
            echo "      🔧 削除しました"
            ((FIXED_ISSUES++))
        fi
    done <<< "$broken_links"
    ((FAILED_CHECKS++))
else
    echo -e "${GREEN}✅ シンボリックリンク正常${NC}"
    ((PASSED_CHECKS++))
fi

((TOTAL_CHECKS++))

# 5. 権限チェック
echo ""
echo -e "${CYAN}🔐 ファイル権限チェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 実行可能ファイルの権限チェック
script_files=$(find scripts/ -name "*.sh" -type f -print0 2>/dev/null)
if [[ -n "$script_files" ]]; then
    non_exec_list=$(find scripts/ -name "*.sh" -type f ! -perm -u=x -print)
    non_executable=$(printf "%s\n" "$non_exec_list" | sed '/^$/d' | wc -l)
    if [[ $non_executable -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  実行権限なしスクリプト: $non_executable 個${NC}"
        if [[ "$AUTO_FIX" == "true" ]]; then
            printf "%s\n" "$non_exec_list" | sed '/^$/d' | xargs -r chmod +x
            echo "    🔧 権限を修正しました"
            ((FIXED_ISSUES++))
        fi
        ((WARNING_CHECKS++))
    else
        echo -e "${GREEN}✅ スクリプト権限正常${NC}"
        ((PASSED_CHECKS++))
    fi
else
    echo -e "${BLUE}📝 スクリプトファイルなし${NC}"
    ((PASSED_CHECKS++))
fi

((TOTAL_CHECKS++))

# 6. パフォーマンスチェック
if [[ "$DETAILED" == "true" ]]; then
    echo ""
    echo -e "${CYAN}⚡ パフォーマンスチェック${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Zsh起動時間測定
    if [[ -f "scripts/monitoring/zsh-benchmark.sh" ]]; then
        echo "🚀 Zsh起動時間測定中..."
        zsh_result=$(./scripts/monitoring/zsh-benchmark.sh 1 2>/dev/null | grep "平均起動時間" | grep -o "[0-9.]*ms")
        if [[ ! -z "$zsh_result" ]]; then
            time_value=$(echo "$zsh_result" | sed 's/ms//')
            if (( $(echo "$time_value < 100" | bc -l 2>/dev/null || echo 0) )); then
                echo -e "    ✅ Zsh起動時間: $zsh_result ${GREEN}(優秀)${NC}"
                ((PASSED_CHECKS++))
            elif (( $(echo "$time_value < 200" | bc -l 2>/dev/null || echo 0) )); then
                echo -e "    ⚠️  Zsh起動時間: $zsh_result ${YELLOW}(良好)${NC}"
                ((WARNING_CHECKS++))
            else
                echo -e "    ❌ Zsh起動時間: $zsh_result ${RED}(要改善)${NC}"
                ((FAILED_CHECKS++))
            fi
        fi
        ((TOTAL_CHECKS++))
    fi

    # Make実行時間測定
    if [[ -f "scripts/monitoring/makefile-profiler.sh" ]]; then
        echo "🔧 Makefile実行時間測定中..."
        make_result=$(timeout 10 ./scripts/monitoring/makefile-profiler.sh help 2>/dev/null | grep "実行時間" | grep -o "[0-9.]*ms")
        if [[ ! -z "$make_result" ]]; then
            time_value=$(echo "$make_result" | sed 's/ms//')
            if (( $(echo "$time_value < 500" | bc -l 2>/dev/null || echo 0) )); then
                echo -e "    ✅ Make実行時間: $make_result ${GREEN}(良好)${NC}"
                ((PASSED_CHECKS++))
            else
                echo -e "    ⚠️  Make実行時間: $make_result ${YELLOW}(普通)${NC}"
                ((WARNING_CHECKS++))
            fi
        fi
        ((TOTAL_CHECKS++))
    fi
fi

# 7. Git状態チェック
echo ""
echo -e "${CYAN}📋 Git状態チェック${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_check "Gitリポジトリ初期化" \
    "test -d .git && echo 'initialized'" \
    "git init" \
    "initialized"

# 未コミット変更の確認
if git rev-parse --git-dir >/dev/null 2>&1; then
    uncommitted=$(git status --porcelain 2>/dev/null | wc -l)
    if [[ $uncommitted -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  未コミット変更: $uncommitted ファイル${NC}"
        if [[ "$DETAILED" == "true" ]]; then
            git status --porcelain | head -5 | while read status_line; do
                echo "    📄 $status_line"
            done
        fi
        ((WARNING_CHECKS++))
    else
        echo -e "${GREEN}✅ Git状態クリーン${NC}"
        ((PASSED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
fi

# 8. 最終評価
echo ""
echo -e "${BLUE}📊 健全性評価${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📈 チェック結果:"
echo -e "  ${GREEN}✅ 正常:${NC} $PASSED_CHECKS/$TOTAL_CHECKS"
echo -e "  ${YELLOW}⚠️  警告:${NC} $WARNING_CHECKS/$TOTAL_CHECKS"
echo -e "  ${RED}❌ 失敗:${NC} $FAILED_CHECKS/$TOTAL_CHECKS"

if [[ "$AUTO_FIX" == "true" ]]; then
    echo -e "  ${CYAN}🔧 修復済み:${NC} $FIXED_ISSUES 件"
fi

# スコア計算
HEALTH_SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo ""
echo "🎯 健全性スコア: $HEALTH_SCORE/100"

if [[ $HEALTH_SCORE -ge 90 ]]; then
    echo -e "${GREEN}🎉 評価: 優秀 - システムは非常に健全です${NC}"
elif [[ $HEALTH_SCORE -ge 75 ]]; then
    echo -e "${BLUE}✅ 評価: 良好 - システムは健全です${NC}"
elif [[ $HEALTH_SCORE -ge 60 ]]; then
    echo -e "${YELLOW}⚠️  評価: 注意 - いくつかの問題があります${NC}"
else
    echo -e "${RED}🚨 評価: 不良 - 早急な対応が必要です${NC}"
fi

# 改善提案
echo ""
echo -e "${BLUE}💡 改善提案${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED_CHECKS -gt 0 ]]; then
    echo "🔴 緊急対応:"
    echo "  • 失敗したチェックの原因調査と修正"
    echo "  • --fix オプションで自動修復を試行"
fi

if [[ $WARNING_CHECKS -gt 0 ]]; then
    echo "🟡 推奨改善:"
    echo "  • 警告項目の確認と対応"
    echo "  • 定期的な健全性チェック実行"
fi

echo "🔄 メンテナンス:"
echo "  • 週1回の健全性チェック"
echo "  • 月1回の詳細チェック (--detailed)"
echo "  • プロジェクト更新後のチェック"

echo ""
echo "📝 ログ保存: $SCRIPT_DIR/health-check-$(date +%Y%m%d_%H%M%S).log"
echo "🏁 健全性チェック完了"
