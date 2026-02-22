REPO_ROOT ?= $(CURDIR)
.DEFAULT_GOAL := setup
include mk/system.mk
include mk/install.mk
include mk/fonts.mk
include mk/clipboard.mk
include mk/memory.mk
.PHONY: setup
setup:
	@echo "==> Setting up dotfiles-system"
