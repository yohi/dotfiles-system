# logid 設定管理

このディレクトリでは、Logicool製マウスのボタン割り当てを管理するための `logid` (logiops) の設定ファイルを管理しています。

## 構成ファイル

- **logid.cfg**: ボタン割り当て、感度、ジェスチャー設定などのメイン設定ファイル。
- **logid.service**: システム起動時に実行するための systemd サービス設定。

## 対応デバイス

### MX Ergo S
- **戻るボタン (0x53)**: `Ctrl + Alt + Right` (仮想デスクトップ切り替え)
- **進むボタン (0x56)**: `Ctrl + Alt + Left` (仮想デスクトップ切り替え)
- **プレシジョンモードボタン (0xfd)**: `Left Meta` (アプリケーション一覧など)
  - ※ このボタンの CID は `0xd7` や `0x52` ではなく、**`0xfd`** が正解です。

### M720 Triathlon
- **戻るボタン (0x53)**: `Ctrl + Alt + Right`
- **進むボタン (0x56)**: `Ctrl + Alt + Left`
- **ジェスチャーボタン (0xd0)**: `Left Meta`

## システムへの反映方法

### 1. 設定ファイルのリンク
設定ファイルは `/etc/logid.cfg` に配置する必要があります。このリポジトリのファイルをシンボリックリンクとして配置します。

```bash
sudo ln -sf $(pwd)/logid/logid.cfg /etc/logid.cfg
```

### 2. サービス設定の反映
接続トラブル（タイムアウト等）に備え、サービスが停止した際に自動再起動するように設定されています。

```bash
# サービスファイルのコピー
sudo cp logid/logid.service /etc/systemd/system/logid.service

# 設定の反映
sudo systemctl daemon-reload
sudo systemctl enable --now logid
```

## トラブルシューティング

### 設定が反映されない場合
ボタンを押しても反応がない場合は、`logid` を詳細ログモードで起動して、正しい CID が送られているか確認してください。

```bash
sudo systemctl stop logid
sudo logid -v
```

### 接続が切れた場合
サービスは `Restart=always` (5s間隔) で設定されているため、通常は自動的に復旧します。手動で直す場合は以下を実行してください。

```bash
sudo systemctl restart logid
```
