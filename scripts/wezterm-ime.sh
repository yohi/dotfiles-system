#!/bin/bash
# WezTerm IME対応起動スクリプト
#
# 使用方法:
#   ./wezterm-ime.sh [options] [wezterm arguments]
#
# オプション:
#   --debug    デバッグ情報を表示
#   --help     このヘルプを表示
#
# 環境変数:
#   WEZTERM_PATH_OVERRIDE  WezTermのパスを手動指定
#
# 例:
#   ./wezterm-ime.sh --debug
#   WEZTERM_PATH_OVERRIDE=/usr/local/bin/wezterm ./wezterm-ime.sh
#   ./wezterm-ime.sh start --cwd /home/user/project

# 環境変数の設定（IME統合を確実にする）
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

# Wayland環境でのIME統合のための追加設定
export IBUS_USE_PORTAL=1
export GTK_USE_PORTAL=1

# ヘルプ表示
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "WezTerm IME対応起動スクリプト"
    echo ""
    echo "使用方法:"
    echo "  $0 [options] [wezterm arguments]"
    echo ""
    echo "オプション:"
    echo "  --debug, -d    デバッグ情報を表示"
    echo "  --help, -h     このヘルプを表示"
    echo ""
    echo "環境変数:"
    echo "  WEZTERM_PATH_OVERRIDE  WezTermのパスを手動指定"
    echo ""
    echo "例:"
    echo "  $0 --debug"
    echo "  WEZTERM_PATH_OVERRIDE=/usr/local/bin/wezterm $0"
    echo "  $0 start --cwd /home/user/project"
    echo ""
    echo "このスクリプトは以下を自動的に行います:"
    echo "  - IBus関連環境変数の設定"
    echo "  - IBusデーモンの起動確認・自動起動"
    echo "  - WezTermパスの動的検出"
    echo "  - 最適化されたIME設定でWezTermを起動"
    exit 0
fi

# デバッグ情報（必要に応じて）
if [ "$1" = "--debug" ] || [ "$1" = "-d" ]; then
    echo "=== WezTerm IME Debug Info ==="
    echo "GTK_IM_MODULE: $GTK_IM_MODULE"
    echo "QT_IM_MODULE: $QT_IM_MODULE"
    echo "XMODIFIERS: $XMODIFIERS"
    echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
    echo "DISPLAY: $DISPLAY"
    echo "IBUS_USE_PORTAL: $IBUS_USE_PORTAL"
    echo "=============================="
    shift
fi

# IBusが起動していることを確認
if ! pgrep -x "ibus-daemon" > /dev/null; then
    echo "Warning: IBus daemon is not running. Starting it..."

    # ibus-daemonを起動し、エラーハンドリングを実装
    if ! ibus-daemon -d; then
        echo "Error: Failed to start ibus-daemon. Trying alternative methods..."

        # 既存のプロセスをクリーンアップ
        pkill -f "ibus-daemon" 2>/dev/null || true
        sleep 1

        # 再度起動を試行
        if ! ibus-daemon -d --replace; then
            echo "Error: Unable to start ibus-daemon. IME may not work properly."
            echo "Please check your IBus installation and try running 'ibus-daemon -d' manually."
        fi
    fi

    # ibus-daemonの起動を確認するループ（最大10秒待機）
    echo "Waiting for IBus daemon to start..."
    for i in {1..20}; do
        if pgrep -x "ibus-daemon" > /dev/null; then
            echo "IBus daemon started successfully."
            break
        fi

        if [ $i -eq 20 ]; then
            echo "Warning: IBus daemon did not start within 10 seconds. Proceeding anyway..."
            break
        fi

        sleep 0.5
    done
fi

# WezTermのパスを動的に検出
WEZTERM_PATH=""

# 環境変数WEZTERM_PATHが設定されている場合はそれを使用
if [ -n "$WEZTERM_PATH_OVERRIDE" ]; then
    WEZTERM_PATH="$WEZTERM_PATH_OVERRIDE"
    echo "Using WEZTERM_PATH_OVERRIDE: $WEZTERM_PATH"
elif command -v wezterm > /dev/null 2>&1; then
    # PATHからweztermを検出
    WEZTERM_PATH="$(command -v wezterm)"
    echo "Found wezterm in PATH: $WEZTERM_PATH"
elif [ -x "/home/y_ohi/bin/wezterm" ]; then
    # フォールバック: デフォルトの場所を確認
    WEZTERM_PATH="/home/y_ohi/bin/wezterm"
    echo "Using fallback path: $WEZTERM_PATH"
else
    echo "Error: WezTerm not found. Please install WezTerm or set WEZTERM_PATH_OVERRIDE environment variable."
    echo "Tried locations:"
    echo "  - Environment variable: WEZTERM_PATH_OVERRIDE"
    echo "  - System PATH: $(command -v wezterm 2>/dev/null || echo 'not found')"
    echo "  - Fallback: /home/y_ohi/bin/wezterm"
    exit 1
fi

# WezTermを起動
echo "Starting WezTerm: $WEZTERM_PATH"
exec "$WEZTERM_PATH" "$@"
