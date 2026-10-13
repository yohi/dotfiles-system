# Ubuntu Desktop / Server — Herdr remote OAuth

## 原則

Ubuntu Desktop で `herdr --remote workbox` を実行している場合、Herdr UI とブラウザは Desktop 側にあります。接続先 `workbox` は Desktop の SSH config に登録済みのエイリアスです。Server のIPアドレスやSSH接続元IPからDesktopを推測しません。

認証方法は次の優先順位を推奨します。

1. 認証ツールが Device Authorization Flow を提供するならそれを使用（localhost コールバック転送不要）。
2. それ以外は Herdr のペインに表示された認証URLを **Ctrl+クリック** し、Desktop 側のブラウザで開く（使用する端末が修飾クリックをHerdrに渡す必要があります）。
3. リダイレクトURIが **Serverの localhost コールバック** を指している場合のみ、下記のSSH転送を利用。

ターミナル出力を監視して発見したURLを無条件にブラウザ起動する常駐サービスは導入しません。AIエージェントの出力は信頼できない場合があるため、OAuth URLを開く操作は人間が行います。

## 一時的な localhost SSH 転送

Desktop 側のターミナルで、利用するOAuthツールが実際に表示した待受ポートを指定して実行します。

```bash
# 例示の1455はOAuthツールによって異なります
_bin/herdr-oauth-remote --port 1455 workbox

# Herdrの名前付きセッション
_bin/herdr-oauth-remote --port 1455 --session agents workbox
```

このコマンドはDesktopの `127.0.0.1:PORT` をServerの `127.0.0.1:PORT` にSSH転送し、その後 `herdr --remote` を起動します。OAuth CLIがServerで起動したコールバック待受に対し、Desktopブラウザから接続できます。終了時に専用SSHトンネルを閉じます。Server側HerdrセッションやAIエージェントは停止しません。

**制限:** OAuthリダイレクトが `[::1]` (IPv6) 専用の場合、このIPv4ヘルパーだけでは動作しません。ブラウザ側でlocalhostをIPv4解決できる必要があります。端末のポートが競合している場合はSSH転送を失敗させ、別のOAuth redirect URIに勝手に変更しません。

## セキュリティと保守

- ローカル `127.0.0.1` のみにbind。LANへの待受公開、デスクトップへの新規SSHサービス、資格情報のコピーは不要です。
- 標準のSSHホスト鍵検証を維持。SSHエージェント転送は無効にします。
- トンネルは必要時だけ有効にし、接続確立に失敗した場合はHerdrを起動しません。
- `BROWSER` のグローバル書換え、任意URLの自動起動、systemdによる常駐監視はしません。
- `herdr --remote` のSSH接続と補助トンネルは別接続です。
- 本コンポーネントは dotfiles-core から管理されます。リポジトリ単独のセットアップはサポートされません。

```bash
bash _tests/herdr-oauth-remote-test.sh
```

参考: [Herdr remote](https://herdr.dev/docs/how-to-work/), [Herdr quick start](https://herdr.dev/docs/quick-start/), [Herdr persistence](https://herdr.dev/docs/persistence-remote/)
