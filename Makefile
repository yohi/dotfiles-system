include _mk/core.mk
include _mk/help.mk


# GUI環境の自動検出 (非GUI環境ではGUIアプリをスキップ)
ifndef SKIP_GUI
    ifeq ($(shell uname -s),Linux)
        # 1. DISPLAY環境変数のチェック
        # 2. X serverバイナリのチェック
        # 3. systemd/loginctlによるセッションタイプチェック
        IS_GRAPHICAL := 0
        ifneq ($(DISPLAY),)
            IS_GRAPHICAL := 1
        else ifneq ($(shell command -v Xorg 2>/dev/null),)
            IS_GRAPHICAL := 1
        else ifneq ($(shell command -v X 2>/dev/null),)
            IS_GRAPHICAL := 1
        else ifneq ($(shell command -v loginctl 2>/dev/null),)
            ifeq ($(shell loginctl show-session $${XDG_SESSION_ID:-$$(loginctl --no-legend list-sessions | head -n1 | awk '{print $$1}')} -p Type --value 2>/dev/null),x11)
                IS_GRAPHICAL := 1
            else ifeq ($(shell loginctl show-session $${XDG_SESSION_ID:-$$(loginctl --no-legend list-sessions | head -n1 | awk '{print $$1}')} -p Type --value 2>/dev/null),wayland)
                IS_GRAPHICAL := 1
            endif
        else ifneq ($(shell command -v systemctl 2>/dev/null),)
            ifeq ($(shell systemctl get-default 2>/dev/null),graphical.target)
                IS_GRAPHICAL := 1
            endif
        endif

        ifneq ($(IS_GRAPHICAL),1)
            export SKIP_GUI := 1
        endif
    endif
endif

# Global variables
HOME_DIR := $(HOME)
REPO_ROOT := $(CURDIR)

# Include individual modules
include _mk/idempotency.mk
include _mk/system.mk
include _mk/install.mk
include _mk/fonts.mk
include _mk/clipboard.mk
include _mk/memory.mk
include _mk/logid.mk

.PHONY: all clean test install setup install-system setup-system init

all: install setup ## インストールとセットアップを全て実行します
clean: ## 一時ファイルやビルド成果物を削除します
	@$(MAKE) logid-clean
test: ## 設定のテストを実行します（現在はプレースホルダー）
	@echo "Running tests..."

init: install-system ## 初期セットアップ (install-system のエイリアス)

install: install-system ## System 関連のインストール
setup: setup-system ## System の設定適用

prepare-system:
	@echo "==> Preparing dotfiles-system"
	mkdir -p $(HOME)
	ln -sfn $(CURDIR)/Brewfile $(HOME)/.Brewfile

install-system: prepare-system
	@echo "==> Installing dotfiles-system"
	$(MAKE) system-install

setup-system: prepare-system
	@echo "==> Setting up dotfiles-system"
	$(MAKE) system-setup
