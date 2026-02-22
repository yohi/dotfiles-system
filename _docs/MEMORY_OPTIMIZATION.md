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
make memory-status

# 包括的なメモリ最適化（推奨）
make memory-optimize

# スワップをクリア（必要に応じて）
make memory-clear-swap
```

## 📊 コマンド一覧

### 状況確認
- `make memory-status` - 現在のメモリ使用状況を表示
- `make memory-help` - 詳細なヘルプを表示

### 基本最適化
- `make memory-optimize` - 包括的なメモリ最適化（推奨）
- `make memory-clear-swap` - スワップを安全にクリア
- `make memory-clear-cache` - システムキャッシュをクリア
- `make memory-optimize-swappiness` - スワップ積極度を最適化

### アプリケーション最適化
- `make memory-optimize-chrome` - Chrome関連最適化情報を表示

### 監視システム
- `make memory-setup-monitoring` - メモリ監視システムをセットアップ
- `make memory-start-monitoring` - メモリ監視サービスを開始
- `make memory-stop-monitoring` - メモリ監視サービスを停止

### 緊急時
- `make memory-emergency-cleanup` - 緊急メモリクリーンアップ

## 🎯 推奨実行フロー

### 1. 通常のメモリ最適化
```bash
# 1. 現状確認
make memory-status

# 2. 包括的最適化
make memory-optimize

# 3. 必要に応じてスワップクリア
make memory-clear-swap
```

### 2. 緊急時のメモリ不足対応
```bash
# 1. 緊急クリーンアップ
make memory-emergency-cleanup

# 2. アプリケーション整理後にスワップクリア
make memory-clear-swap
```

### 3. 監視システムの設定
```bash
# 1. 監視システムをセットアップ
make memory-setup-monitoring

# 2. 監視を開始
make memory-start-monitoring

# 3. 状況確認
systemctl --user status memory-monitor.service
```

## ⚙️ 設定の詳細

### スワップ積極度（vm.swappiness）
- **デフォルト**: 60
- **推奨値**: 10
- **効果**: メモリ使用量が90%を超えるまでスワップを使用しない

```bash
make memory-optimize-swappiness
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
- 監視サービスは systemd により管理され、自動起動設定可能

### システムへの影響
- キャッシュクリアは一時的にシステムが重くなる場合があります
- 監視サービスは軽量で、システムパフォーマンスへの影響は最小限

## 🚨 トラブルシューティング

### スワップクリアが失敗する場合
```bash
# 1. メモリ使用量を確認
make memory-status

# 2. 不要なアプリケーションを終了
# Chrome、Slack等の大きなアプリケーション

# 3. キャッシュをクリア
make memory-clear-cache

# 4. 再度スワップクリアを試行
make memory-clear-swap
```

### 監視サービスが開始できない場合
```bash
# サービス状況を確認
systemctl --user status memory-monitor.service

# ログを確認
journalctl --user -u memory-monitor.service

# サービスを再設定
make memory-setup-monitoring
make memory-start-monitoring
```

## 💡 ベストプラクティス

### 定期的なメンテナンス
```bash
# 週次実行推奨
make memory-optimize

# 月次実行推奨  
make memory-setup-monitoring  # 監視設定の更新
```

### 開発環境での使用
```bash
# 開発開始前
make memory-status

# 重い処理の前
make memory-clear-cache

# 作業終了時
make memory-optimize
```

### パフォーマンス監視
```bash
# 継続的な監視
make memory-start-monitoring

# 定期的な状況確認
make memory-status
```

## 🔗 関連リンク

- [Linux Memory Management](https://www.kernel.org/doc/html/latest/admin-guide/mm/index.html)
- [Understanding vm.swappiness](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/sysctl/vm.rst)
- [systemd User Services](https://wiki.archlinux.org/title/Systemd/User)

---

**注意**: このドキュメントは Ubuntu 環境での使用を前提としています。他のLinuxディストリビューションでは、一部のコマンドや設定方法が異なる場合があります。