# 🚀 メモリ最適化設定

## 1. システムメモリ設定 (`/etc/sysctl.d/99-memory-optimization.conf`)

```bash
# スワッピネス (デフォルト: 60 → 10)
vm.swappiness = 10

# VFSキャッシュ圧力 (デフォルト: 100 → 50)
vm.vfs_cache_pressure = 50

# Dirty比率 (デフォルト: 20 → 15)
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 最小空きメモリ
vm.min_free_kbytes = 131072
```

## 2. Chrome最適化フラグ

```bash
--memory-pressure-off
--max_old_space_size=4096
--enable-low-end-device-mode
--process-per-site
```

## 3. 即座に適用可能なコマンド

```bash
# スワッピネス変更
echo 10 | sudo tee /proc/sys/vm/swappiness

# キャッシュクリア
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# メモリ使用量確認
free -h && ps aux --sort=-%mem | head -10
```

## 4. ブラウザプロセス削減

現在Chrome が80プロセス実行中。以下で最適化：

- タブ数を制限（20タブ以下推奨）
- 拡張機能を最小限に
- `chrome://settings/system` でバックグラウンドアプリを無効化