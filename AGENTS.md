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
All changes MUST comply with the central layout rules. Please refer to [`dotfiles-core/docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) for the full, authoritative rules and constraints.

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
