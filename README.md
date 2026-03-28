# dotfiles-system

システム全体の設定（パッケージ管理、メモリ最適化、モニタリングスクリプト、セキュリティチェッカー）を管理するコンポーネントリポジトリです。
[dotfiles-core](https://github.com/yohi/dotfiles-core) と連携して動作します。

## 管理と依存関係

本リポジトリは [dotfiles-core](https://github.com/yohi/dotfiles-core) によって管理されるコンポーネントの一つです。

### ⚠️ 単体使用時の注意点
本リポジトリは `dotfiles-core` の共通 Makefile ルール（`common-mk`）に依存しています。単体で使用（クローン）する場合は、以下の手順が必要です：

1. `common-mk` ディレクトリを本リポジトリの親ディレクトリに配置するか、パスを適切に設定してください。
2. `make help` を実行して、正しく設定されていることを確認してください。

推奨される使用方法は、`dotfiles-core` から `make setup` を実行することです。

## ディレクトリ構成

```text
.
├── Makefile
├── README.md
├── AGENTS.md
├── Brewfile                # Homebrew package list
├── _mk/                    # Makefile sub-targets
├── _scripts/               # System management/optimization
└── logid/                  # Logiops mouse configuration
```

## 主要機能

- **パッケージ管理**: Homebrew (`Brewfile`) による一括管理。
- **フォント管理**: 開発用フォントの自動インストール。
- **システム最適化**: メモリ使用量の最適化スクリプト。
- **クリップボード統合**: システムクリップボードの共有設定。
- **システム監視**: カスタム監視スクリプト。
