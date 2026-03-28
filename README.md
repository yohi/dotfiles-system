# dotfiles-system

システム全体の設定（パッケージ管理、メモリ最適化、モニタリングスクリプト、セキュリティチェッカー）を管理するコンポーネントリポジトリです。
[dotfiles-core](https://github.com/yohi/dotfiles-core) と連携して動作します。


## ⚠️  Standalone Usage Note
This repository depends on common Makefile fragments from [dotfiles-core](https://github.com/yohi/dotfiles-core). When using this repository standalone, ensure the `common-mk` directory is present in the parent directory, or use `dotfiles-core` as the orchestrator.
