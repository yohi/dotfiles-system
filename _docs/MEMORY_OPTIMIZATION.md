# 🧠 メモリ最適化ガイド

このドキュメントでは、dotfilesのMakefileに統合されたメモリ最適化機能の使用方法を説明します。

## 🚀 クイックスタート

### 初回セットアップ時

```bash
# メモリ最適化は自動的に含まれます
make system-setup   # または make setup-all
```

### 手動でのメモリ最適化

```bash
# 現在のメモリ状況を確認
make memory-check

# 包括的なメモリ最適化（推奨）
make memory-optimize

# クイックメモリ修復（必要に応じて）
make memory-fix
```

## 📊 コマンド一覧

### 状況確認

- `make memory-check` - 現在のメモリ使用状況を表示
- `make help-memory` - 詳細なヘルプを表示
- `make memory-info` - システム情報とメモリ推奨事項を表示

### 基本最適化

- `make memory-optimize` - 包括的なメモリ最適化設定を適用（推奨）
- `make memory-cleanup` - システムキャッシュ等をクリア

### 監視とトラブルシューティング

- `make memory-monitor` - 高メモリ使用プロセスをリアルタイム監視
- `make memory-troubleshoot` - 問題のあるプロセスを特定・対処
- `make memory-fix` - クイックなメモリ修復を実行

## 🎯 推奨実行フロー

### 1. 通常のメモリ最適化

```bash
# 1. 現状確認
make memory-check

# 2. 包括的最適化
make memory-optimize

# 3. 必要に応じてメモリ修復
make memory-fix
```

### 2. 緊急時のメモリ不足対応

```bash
# 1. 緊急クリーンアップ
make memory-cleanup

# 2. 原因プロセスの特定と修復
make memory-troubleshoot
make memory-fix
```

### 3. 継続監視

```bash
# 1. 高メモリ使用プロセスの監視
make memory-monitor
```

## ⚙️ 設定の詳細

### スワップ積極度（vm.swappiness）

- **デフォルト**: 60
- **推奨値**: 10
- **効果**: メモリ使用量が90%を超えるまでスワップを使用しない

```bash
make memory-optimize
```

### メモリ監視

- **監視間隔**: 5分
- **メモリアラート**: 使用量85%以上
- **スワップアラート**: 使用量50%以上

## 🔧 技術的詳細

### スワップクリアの安全性チェック

コマンド実行時に以下をチェック：

- 利用可能メモリ量
- スワップ使用量
- 必要メモリ量（2GBバッファ含む）

### システムキャッシュクリア

以下のキャッシュをクリア：

- ページキャッシュ
- dentry キャッシュ
- inode キャッシュ

### Chrome最適化

以下の項目をチェック・提案：

- プロセス数の確認
- メモリセーバー機能の推奨
- 不要タブ・拡張機能の整理提案

## 📝 注意事項

### スワップクリア

- **管理者権限が必要**: sudo パスワードの入力が求められます
- **実行時間**: スワップ使用量に応じて30秒〜数分
- **安全性**: 利用可能メモリが不足している場合は実行を中止

### 設定の永続化

- `vm.swappiness` の変更は `/etc/sysctl.conf` に追記され、再起動後も有効

### システムへの影響

- キャッシュクリアは一時的にシステムが重くなる場合があります

## 🚨 トラブルシューティング

### メモリ修復が失敗する場合

```bash
# 1. メモリ使用量を確認
make memory-check

# 2. 原因プロセスの特定と対処
make memory-troubleshoot
make memory-fix

# 3. システムキャッシュを強制クリア
make memory-cleanup
```

### メモリ監視が機能しない場合

```bash
# 高メモリプロセスのリアルタイム監視を再起動
make memory-monitor
```

## 💡 ベストプラクティス

### 定期的なメンテナンス

```bash
# 週次実行推奨
make memory-optimize
```

### 開発環境での使用

```bash
# 開発開始前
make memory-check

# 作業終了時
make memory-optimize
```

### パフォーマンス監視

```bash
# 継続的な監視
make memory-monitor

# 定期的な状況確認
make memory-check
```

## 🔗 関連リンク

- [Linux Memory Management](https://www.kernel.org/doc/html/latest/admin-guide/mm/index.html)
- [Understanding vm.swappiness](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/sysctl/vm.rst)
- [systemd User Services](https://wiki.archlinux.org/title/Systemd/User)

---

**注意**: このドキュメントは Ubuntu 環境での使用を前提としています。他のLinuxディストリビューションでは、一部のコマンドや設定方法が異なる場合があります。
