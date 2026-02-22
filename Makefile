REPO_ROOT ?= $(CURDIR)
.DEFAULT_GOAL := setup
include _mk/system.mk
include _mk/install.mk
include _mk/fonts.mk
include _mk/clipboard.mk
include _mk/memory.mk
.PHONY: setup
setup:
	@echo "==> Setting up dotfiles-system"
