# PROJECT KNOWLEDGE BASE

**Repository:** dotfiles-system
**Role:** System-level configuration — package management, fonts, clipboard, memory optimization, security, Docker, and maintenance scripts

## STRUCTURE

```text
dotfiles-system/
├── _mk/                         # Makefile sub-targets
│   ├── clipboard.mk            # Clipboard manager setup
│   ├── fonts.mk                # Font installation
│   ├── install.mk              # Package installation
│   ├── memory.mk               # Memory optimization
│   └── system.mk               # System-level settings
├── scripts/                    # Setup and utility scripts
│   ├── check-setup.sh          # Environment verification
│   ├── maintenance/            # Maintenance automation
│   │   ├── auto-cleanup.sh     # Automatic cleanup
│   │   └── health-check.sh     # System health check
│   ├── monitoring/             # Performance monitoring
│   │   ├── makefile-profiler.sh
│   │   └── zsh-benchmark.sh
│   ├── security/               # Security scripts
│   │   └── credential-checker.sh
│   ├── memory-optimization.sh  # Memory tuning
│   ├── setup-apparmor.sh       # AppArmor setup
│   ├── setup-docker-mcp.sh     # Docker MCP setup
│   └── wezterm-ime.sh          # WezTerm IME workaround
├── docs/                       # Documentation
│   └── reports/                # Analysis reports
├── logid/                      # Logitech device configuration
│   └── logid.cfg               # logid config file
├── Brewfile                    # Homebrew package list
└── Makefile                    # Setup entry point (includes _mk/*.mk)
```

## COMPONENT LAYOUT CONVENTION

This repository is part of the **dotfiles polyrepo** orchestrated by `dotfiles-core`.
All changes MUST comply with the following layout rules.

### Required Files

Every component repository MUST have:

| File | Purpose |
| :--- | :--- |
| `Makefile` | Exposes a `setup` target; called by `dotfiles-core` via delegation |
| `.stow-local-ignore` | Lists files/dirs excluded from Stow symlink creation |
| `README.md` | Component overview (written in Japanese) |
| `LICENSE` | MIT license |
| `.gitignore` | Git exclusion rules |

### Stow Symlink Rules

GNU Stow creates symlinks from this repo's root into `~/`.
**Only dotfiles and directories intended for the user's `$HOME` should be Stow targets.**

- Files/dirs listed in `.stow-local-ignore` are **excluded** from Stow.
- When `.stow-local-ignore` exists, Stow's default exclusions (README.*, LICENSE, etc.) are **disabled** — you must list them explicitly.
- `.stow-local-ignore` patterns are interpreted as **regex** — escape dots: `README\.md`, not `README.md`.

### Makefile Rules

```makefile
.DEFAULT_GOAL := setup
# include _mk/<feature>.mk    # if using _mk/ subdirectory

.PHONY: setup
setup:
 @echo "==> Setting up dotfiles-<name>"
```

1. `setup` target is **mandatory** (interface for dotfiles-core delegation).
2. Set `.DEFAULT_GOAL := setup` when using `include` directives.
3. Declare all non-file targets with `.PHONY`.
4. Use `mk/` subdirectory to split complex Makefiles.
5. Print progress with `@echo "==> ..."`.

### `bin/` vs `scripts/`

| Directory | Purpose | On `$PATH` | Stow target |
| :--- | :--- | :--- | :--- |
| `bin/` | Public commands callable by users or other components | ✅ Added dynamically by dotfiles-zsh | ❌ Excluded |
| `scripts/` | Internal helpers for this component only | ❌ | ❌ Excluded |

### Path Resolution (MANDATORY)

All scripts must resolve paths dynamically. Hardcoded absolute paths are **forbidden**.

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
```

**Forbidden:**

- Hardcoded paths like `~/dotfiles/components/dotfiles-system/...`
- Legacy `$DOTFILES_DIR` references from monorepo era

## THIS COMPONENT — SPECIAL NOTES

- **All subdirectories are excluded from Stow.** System configs are applied via scripts and `make` targets.
- `_mk/` splits Makefile targets by system subsystem (fonts, clipboard, memory, packages, etc.).
- `scripts/` is organized by concern: `maintenance/`, `monitoring/`, `security/`.
- `logid/logid.cfg` is for Logitech device daemon — installed to `/etc/logid.cfg` (requires `sudo`).
- `Brewfile` lists Homebrew packages — applied via `brew bundle`.
- Many scripts require `sudo` — legitimate for system setup but blocked for AI agent execution.

## CODE STYLE

- **Documentation / README**: Japanese (日本語)
- **AGENTS.md**: English
- **Commit Messages**: Japanese, Conventional Commits (e.g., `feat: 新機能追加`, `fix: バグ修正`)
- **Shell**: `set -euo pipefail`, dynamic path resolution, idempotent operations

## FORBIDDEN OPERATIONS

Per `opencode.jsonc` (when present), these operations are blocked for agent execution:

- `rm` (destructive file operations)
- `ssh` (remote access)
- `sudo` (privilege escalation)
