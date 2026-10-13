# Herdr --remote のブラウザ OAuth（Ubuntu Desktop / Ubuntu Server）

## 設計判断（2026-10-13）

従来の `herdr --remote workbox` を変更しない。ここで `workbox` は Ubuntu Desktop 側のSSH configで定義した接続先であり、DesktopのIPアドレスを推測する必要はない。Herdrは `--remote` の場合でもUIをDesktop側で描画し、ペイン内のHTTPSリンクをCtrl+クリックすると、Desktop側の既定ブラウザで開ける（端末が修飾クリックを渡す場合）。

**Ctrl+クリックは自動起動ではない。** 任意のURLをペイン出力から抽出して勝手に開く監視デーモンは採用しない。URL、OAuthコード、PKCE情報、トークンはログ収集やGit管理へ送らない。

## プロバイダ別の判断

| ケース | 例 | 推奨 | localhost転送 |
|---|---|---|---|
| Device Authorization | Codex `codex login --device-auth`（ChatGPT設定で有効化が必要） | URLをDesktopで開き表示コードを入力 | 不要 |
| ブラウザ認証後にコードを貼る方式 | 対応するCLI/provider | Ctrl+クリック、必要なコードをCLIへ入力 | 不要 |
| 固定loopback OAuth | Codex標準認証では通常 `127.0.0.1:1455` | ログインの前後に一時転送 | 必要 |
| 動的loopback OAuth | Gemini CLI は空きポートを使用する場合あり | 実際に表示されたredirect URIのポートで転送 | 必要 |

OpenCodeの `/connect`、`opencode auth login`、`opencode mcp auth` はプロバイダ・バージョンごとに認証方式が異なる。全OpenCode認証に共通するポートは仮定しない。Claude Codeも利用バージョンと認証方式を確認する。「ブラウザを開いてください」という表示だけでは転送の要否は確定できない。

## 普段の操作：変更なし

Ubuntu Desktopでこれまでどおり：

```bash
herdr --remote workbox
```

CodexでDevice Codeログインを選べる場合、Server上のHerdrペインから：

```bash
codex login --device-auth
```

表示されたURLをCtrl+クリックしてDesktopのブラウザでログイン、コードを入力する。SSHポート転送は不要。

## localhostコールバックが必要な例外だけ

**Herdrを再起動せず**、Desktopで別のターミナルを開き、ServerのOAuth CLIが待ち受けるポートで次を起動する：

```bash
_bin/herdr-oauth-forward --port 1455 workbox
```

この補助コマンドは別SSH接続による `Desktop 127.0.0.1:1455 → Server 127.0.0.1:1455` だけを作る。Herdr自体は起動・終了しない。認証URLをHerdrでCtrl+クリックし、ログイン後に別ターミナルでCtrl+Cを押す。SSHトンネルだけが終了し、Herdrのセッションは継続する。

`1455` はCodexの通常ポートの例。Gemini CLI等の動的ポート、別のプロバイダの場合は、実際のOAuth redirect URIに合わせて指定する。ローカルポート競合・異なる待受アドレス・IPv6 `::1` 専用待受なら成功しないため、無断でポートを変更しない。補助コマンドはIPv4 loopback専用。

### なぜSSH設定にLocalForwardを常設しないか

OpenSSHの `LocalForward 127.0.0.1:1455 127.0.0.1:1455` をDesktopの対象Hostに書けば、既知の固定ポートの転送を透過的に設定できる可能性はある。ただし、そのHostへの別のSSH接続にも効き、多重接続時のポート競合やHerdr固有のSSH接続再利用との兼ね合いがある。今回の環境での実測はなく、`make setup` がユーザーのSSH設定を自動変更する方式は採用しない。固定ポートの常時転送が必要な場合に個別検討する。

## 自動ブラウザ起動の設計上の境界

Herdrの公開ドキュメントと該当ソースには、利用者のCtrl+クリックに応じて **DesktopでURLを開く** 挙動がある。一方、信頼できる構造化OAuth開始イベントをリモートエージェントからDesktopへ送り、URL/redirect URIを確認して無条件に自動ブラウザ起動・動的ポート転送を完結する正式な統合APIは今回確認できていない。完全自動化を要求する場合は、Herdr本体または各CLIが安全な通知・明示承認・期限付き転送・失敗処理を備える拡張が必要。任意URL文字列の監視では代替しない。

## テストとマージ条件

```bash
bash _tests/herdr-oauth-forward-test.sh
```

モックSSHで引数検証、loopback制限、SSH失敗伝播をテストする。ただし **実SSH、Ubuntu Desktopブラウザ、Ubuntu Server上の実OAuthは未検証**。マージ前に以下を確認すること：

1. HerdrのペインからCtrl+クリックでDesktopのブラウザが開く
2. Device Codeの認証は転送なしで完了する
3. localhost認証は一時SSH転送で完了する（固定ポートと必要に応じ動的ポート）
4. Ctrl+C後に転送が止まり、Herdrとリモートエージェントが動作し続ける
5. ポート競合・SSH障害時にServerが停止せず、資格情報も漏洩しない

## 一次情報

- [Herdr — Persistence and remote access](https://herdr.dev/docs/persistence-remote/)
- [Herdr — Quick start（Ctrl-click）](https://herdr.dev/docs/quick-start/)
- [Herdr — Configuration（remote SSH）](https://herdr.dev/docs/configuration/)
- [OpenAI Codex — Authentication / Login on headless devices](https://developers.openai.com/codex/auth)
- [Gemini CLI OAuth実装](https://github.com/google-gemini/gemini-cli/blob/main/packages/core/src/code_assist/oauth2.ts)
- [OpenCode MCP OAuth](https://docs.opencode.ai/docs/mcp-servers/)
