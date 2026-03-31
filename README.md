# dotfiles-system

システム全体の設定（パッケージ管理、メモリ最適化、モニタリングスクリプト、セキュリティチェッカー）を管理するコンポーネントリポジトリです。

## 管理と共存関係

> [!IMPORTANT]
> 本リポジトリは [dotfiles-core](https://github.com/yohi/dotfiles-core) によって管理されるコンポーネントの一つです。

> [!WARNING]
> **使用時の注意点**
> 本リポジトリは `dotfiles-core` の共通 Makefile ルール（`common-mk`）に依存しており、実行時には `common-mk` へのシンボリックリンクが必要です。そのため、**本リポジトリ単体での使用（クローンしての利用）はサポートされていません。**
>
> 推奨される使用方法は、`dotfiles-core` リポジトリから `make setup` を実行し、適切なディレクトリ構造とシンボリックリンクが構成された状態で利用することです。

## ディレクトリ構成

```text
.
├── Makefile
├── README.md
├── AGENTS.md
├── Brewfile                # Homebrew package list
├── _docs/                  # Documentation & Reports
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
