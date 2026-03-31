include _mk/core.mk
include _mk/help.mk

# Include individual modules
-include _mk/idempotency.mk
-include _mk/system.mk
-include _mk/install.mk
-include _mk/fonts.mk
-include _mk/clipboard.mk
-include _mk/memory.mk

install: install-system ## System 関連のインストール
setup: setup-system ## System の設定適用

install-system:
	@echo "==> Installing dotfiles-system"

setup-system:
	@echo "==> Setting up dotfiles-system"
	mkdir -p $(HOME)
	ln -sfn $(CURDIR)/Brewfile $(HOME)/.Brewfile
	$(MAKE) system-setup
