# Orchestrator core configuration
# Note: These are symlinked from ../../common-mk/ when managed by dotfiles-core
ifneq ($(wildcard _mk/core.mk),)
include _mk/core.mk
else
$(warning "missing _mk/core.mk - please ensure symlink or run setup")
.DEFAULT_GOAL := help
endif

ifneq ($(wildcard _mk/help.mk),)
include _mk/help.mk
else
$(warning "missing _mk/help.mk - please ensure symlink or run setup")
.DEFAULT_GOAL := help
endif

# Component-specific logic





REPO_ROOT ?= $(CURDIR)

# Include individual modules
include _mk/idempotency.mk
include _mk/system.mk
include _mk/install.mk
include _mk/fonts.mk
include _mk/clipboard.mk
include _mk/memory.mk

.PHONY: link
link: ## シンボリックリンクを展開し、dotfiles を配置します
	@echo "==> Linking dotfiles-system"
	mkdir -p $(HOME)
	ln -sfn $(REPO_ROOT)/Brewfile $(HOME)/.Brewfile

.PHONY: setup
setup: ## セットアップ（依存関係、設定適用）を一括実行します
	$(MAKE) system-setup
	@echo "==> Setting up dotfiles-system"
