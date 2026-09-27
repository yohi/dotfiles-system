# UEFIの電力・ファン設定の推奨値

[English](bios-power-and-fan-settings.md)

> [!NOTE]
> この文書は[英語版](bios-power-and-fan-settings.md)の日本語訳です。内容に差がある場合は英語版を優先します。

対象は **ASUS TUF GAMING Z890-PLUS WIFI、Intel Core Ultra 7 270K Plus、DeepCool AK620 DIGITAL SE** の構成です。これは設定の**推奨案**であり、現在のUEFI設定を確認した記録ではありません。実際に表示される項目はBIOSの版で確認してください。

CPUの標準的な電力制限をUEFI側の基準とし、冷却を維持しながらファンの急な騒音を減らすことを目指します。Linuxの`agent`電力プロファイルは別の設定で、明示的に選んだ場合にのみ適用します。

## CPUの電力・電圧

| UEFIの項目 | 推奨する初期設定 | 理由 |
| --- | --- | --- |
| Performance Preferences | `Intel Default Settings`。選択肢があれば`Performance` | ASUS独自のオーバークロック設定ではなく、CPUの標準設定を基準にする。 |
| ASUS MultiCore Enhancement | `Disabled - Enforce All limits` | CPUの電力制限を解除しない。 |
| AI Overclocking、コア倍率、SVID Behavior、Load-line Calibration | 自動オーバークロックは使わず、倍率と電圧関連の手動調整は`Auto` | 静音化のために電圧やクロックを上げる必要はない。 |
| Unlimited ICCMAX | 項目があれば無効、またはIntel標準設定のまま | 電流制限を解除しない。 |
| Long/Short Duration Package Power Limit（PL1/PL2） | UEFIではIntel標準設定を維持し、Linuxの`agent`値に固定しない | 基準となる設定を残し、Linux側の変更を明示的な操作に限定する。 |

IntelによるこのCPUの公称値は、**Processor Base Powerが125 W**、**Maximum Turbo Powerが250 W**、**最大動作温度が105°C**です。公称値は現在のUEFI設定値や目標温度を示すものではありません。以前の資料にあるPL1の200 WをIntel標準値として扱わないでください。

## Q-Fanによる冷却

1. CPUクーラーが`CPU_FAN`へ接続され、クーラーの両方のファンが回っていることを確認します。CPUファンの回転異常検出は維持し、CPUファン停止は使いません。
2. 4ピン接続を確認できたファンは`PWM`に設定します。配線方式が不明なら`Auto`を使い、Q-Fan Tuningでファンの動作可能な回転域を確認します。
3. CPUファンは`Standard`から始めます。短い温度上昇で回転音が急増する場合は、対応項目があれば**Step Up Timeを約2～3秒**から試します。高温が続く場合のファン応答を過度に遅らせないでください。
4. 最低回転数で安定して回ることを確かめてから、低温側のファンカーブを調整します。高温側の回転上昇は残し、カーブ全体を平坦にしないでください。
5. 長時間の負荷でケースファンの通気も確認します。CPUファンだけを静かにして、クーラーや周辺部品に熱をこもらせないようにします。

Q-Fanの項目名と選べる秒数はBIOSの版で異なる場合があります。約2～3秒は**試すための初期値**であり、ASUSの指定値や騒音が消える保証ではありません。

## 適用後の確認

1. 変更前のUEFI設定を控え、設定を一度に大きく変えずに保存・再起動します。
2. 普段のエージェント作業やビルドを約15～30分実行し、CPU温度、ファンの安定回転、騒音、処理時間を確認します。
3. 温度が上がり続ける、冷却が不足する、またはCPUファンが停止する場合は、ファンカーブを戻すか通気を増やします。**80～85°C付近での継続動作**はカーブを見直すための保守的な目安であり、Intelの最大動作温度ではありません。
4. 必要な場合のみ、別途`make cpu-power-agent`でLinuxのプロファイルを適用し、`make cpu-power-status`で確認します。UEFIのファン設定とLinuxの電力制限は別の対策です。

## 参照資料

- [ASUS TUF GAMING Z890-PLUS WIFIのマニュアル一覧](https://www.asus.com/motherboards-components/motherboards/tuf-gaming/tuf-gaming-z890-plus-wifi/helpdesk_manual/)と[Intel 800シリーズBIOSマニュアル](https://dlcdnets.asus.com/pub/ASUS/mb/13MANUAL/J25827_Intel_800_Series_BIOS_manual_EM_WEB.pdf?model=TUF+GAMING+Z890-PLUS+WIFI)：Q-Fan Control、Performance Preferences、ASUS MultiCore Enhancement、電力制限。
- [ASUSのCPUファン検出に関する案内](https://www.asus.com/support/faq/1006064/)：CPU_FANへの接続と低回転の警告。
- [Intel Core Ultra 7 270K Plusの仕様](https://www.intel.com/content/www/us/en/products/sku/245692/intel-core-ultra-7-processor-270k-plus-36m-cache-up-to-5-50-ghz/specifications.html)：電力と最大動作温度。
