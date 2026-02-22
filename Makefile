REPO_ROOT ?= $(CURDIR)
.DEFAULT_GOAL := setup
include _mk/system.mk
include _mk/install.mk
include _mk/fonts.mk
include _mk/clipboard.mk
include _mk/memory.mk

.PHONY: link
link:
	@echo "==> Linking dotfiles-system"
	mkdir -p $(HOME)
	ln -sfn $(REPO_ROOT)/Brewfile $(HOME)/.Brewfile

.PHONY: setup
setup:
	@echo "==> Setting up dotfiles-system"
