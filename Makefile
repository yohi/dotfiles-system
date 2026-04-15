include _mk/core.mk
include _mk/help.mk

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

.PHONY: install setup install-system setup-system init

init: install-system ## 初期セットアップ (install-system のエイリアス)

install: install-system ## System 関連のインストール
setup: setup-system ## System の設定適用

install-system:
	@echo "==> Installing dotfiles-system"
	@if ! sudo -n true 2>/dev/null; then \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		echo "⚠️  注意: これから実行されるコマンドには sudo 権限が必要です。"; \
		echo "💡 事前に別のターミナル、またはこの画面で 'sudo -v' を実行しておくと"; \
		echo "   パスワード入力待ちで停止するのを防ぐことができます。"; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	fi
	mkdir -p $(HOME)
	ln -sfn $(CURDIR)/Brewfile $(HOME)/.Brewfile
	$(MAKE) system-install

setup-system:
	@echo "==> Setting up dotfiles-system"
	@if ! sudo -n true 2>/dev/null; then \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		echo "⚠️  注意: これから実行されるコマンドには sudo 権限が必要です。"; \
		echo "💡 事前に別のターミナル、またはこの画面で 'sudo -v' を実行しておくと"; \
		echo "   パスワード入力待ちで停止するのを防ぐことができます。"; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	fi
	mkdir -p $(HOME)
	ln -sfn $(CURDIR)/Brewfile $(HOME)/.Brewfile
	$(MAKE) system-setup
