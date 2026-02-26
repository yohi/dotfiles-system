# システムレベルの基本設定
system-setup:
ifndef FORCE
	@result="$(call check_marker,setup-system)"; if [ -n "$$result" ] && $$result; then \
		echo "$(call IDEMPOTENCY_SKIP_MSG,setup-system)"; \
		exit 0; \
	fi
endif
	@echo "🔧 システムレベルの基本設定を開始..."

	# tzdataの入力を省略するための設定
	@echo "🕐 tzdataの自動設定を行います..."
	@echo "tzdata tzdata/Areas select Asia" | sudo debconf-set-selections
	@echo "tzdata tzdata/Zones/Asia select Tokyo" | sudo debconf-set-selections
	@export DEBIAN_FRONTEND=noninteractive

	# 問題のあるリポジトリの事前修正（CopyQは除外）
	@echo "🔧 問題のあるリポジトリを修正中..."
	# CopyQ PPAは正常なPPAなので無効化しない
	@if [ -f /etc/apt/sources.list.d/remmina-ppa-team-ubuntu-remmina-next-plucky.list ]; then \
	sudo mv /etc/apt/sources.list.d/remmina-ppa-team-ubuntu-remmina-next-plucky.list /etc/apt/sources.list.d/remmina-ppa-team-ubuntu-remmina-next-plucky.list.disabled  || true; \
	fi

	# TablePlusの公開鍵を再インストール
	@echo "🔑 TablePlusの公開鍵を修正中..."
	@sudo rm -f /etc/apt/trusted.gpg.d/tableplus-archive.gpg  || true
	@wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg >/dev/null 2>&1 || true

	# システムアップデート（エラーを許容）
	@echo "📦 システムパッケージを更新中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt update  || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"
	@sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade  || echo "⚠️  一部のパッケージで問題がありますが、処理を続行します"

	# 日本語環境の設定
	@echo "🌏 日本語環境を設定中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt -y install language-pack-ja language-pack-ja-base  || echo "⚠️  一部の日本語パッケージのインストールに失敗しましたが、処理を続行します"

	# タイムゾーンを日本/東京に設定
	@echo "🕐 タイムゾーンをAsia/Tokyoに設定中..."
	@sudo timedatectl set-timezone Asia/Tokyo || true

	# ロケールの設定
	@echo "🌐 ロケールを設定中..."
	@sudo locale-gen ja_JP.UTF-8 || true
	@sudo update-locale LANG=ja_JP.UTF-8 LANGUAGE=ja_JP:ja LC_ALL=ja_JP.UTF-8 || true

	# 基本開発ツール
	@echo "🔧 基本開発ツールをインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt -y install build-essential curl file wget software-properties-common unzip zsh  || echo "⚠️  一部の基本開発ツールのインストールに失敗しましたが、処理を続行します"

	# 日本語フォントのインストール
	@echo "🔤 日本語フォントをインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt -y install fonts-noto-cjk fonts-noto-cjk-extra || true

	# 日本語入力メソッド（mozc）のインストール
	@echo "🇯🇵 日本語入力メソッド（mozc）をインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt -y install ibus-mozc mozc-utils-gui || echo "⚠️  mozcのインストールに失敗しました（デスクトップ環境がない可能性があります）"

	# IBusの設定
	@if command -v gsettings >/dev/null 2>&1; then \
		echo "⌨️  IBus入力メソッドを設定中..."; \
		gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'mozc-jp')]" || true; \
		gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']" || true; \
	else \
		echo "⏭️  gsettings が見つからないため、IBusの設定をスキップします。"; \
	fi

	# IBusサービスの有効化
	@if command -v systemctl >/dev/null 2>&1 && systemctl --user >/dev/null 2>&1; then \
		echo "⚙️  IBusサービスを有効化中..."; \
		systemctl --user enable ibus-daemon || true; \
		systemctl --user start ibus-daemon || true; \
	else \
		echo "⏭️  systemctl --user が利用できないため、IBusサービスの有効化をスキップします。"; \
	fi

	# フォント環境のセットアップ
	@if [ "$$SKIP_FONTS" != "1" ]; then \
		$(MAKE) fonts-setup || echo "⚠️  fonts-setup の実行中にエラーが発生しましたが、処理を続行します"; \
	else \
		echo "⏭️  SKIP_FONTS=1 が設定されているため、フォント設定をスキップします。"; \
	fi

	# ユーザーディレクトリ管理パッケージをインストール
	@sudo DEBIAN_FRONTEND=noninteractive apt -y install xdg-user-dirs || echo "⚠️  xdg-user-dirs のインストールに失敗しましたが、処理を続行します"

	# ホームディレクトリを英語名にする（非対話的）
	@if command -v xdg-user-dirs-update >/dev/null 2>&1; then \
		LANG=C xdg-user-dirs-update --force; \
	else \
		echo "⚠️  xdg-user-dirs-update が見つからないため、ディレクトリ名の変更をスキップします"; \
	fi
	
	# Ubuntu Japanese
	@echo "🇯🇵 Ubuntu Japanese環境を設定中..."
	@for key_url in \
		https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg \
		https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg; do \
		key_file="/etc/apt/trusted.gpg.d/$$(basename $$key_url)"; \
		tmp_key=$$(mktemp); \
		if wget -qO "$$tmp_key" "$$key_url" && grep -q "BEGIN PGP" "$$tmp_key"; then \
			sudo tee "$$key_file" < "$$tmp_key" >/dev/null; \
			rm -f "$$tmp_key"; \
		else \
			echo "❌ エラー: $$key_url から有効なGPGキーを取得できませんでした"; \
			rm -f "$$tmp_key"; \
			exit 1; \
		fi; \
	done
	@REL_CODE=$$(lsb_release -cs); \
	if wget --spider https://www.ubuntulinux.jp/sources.list.d/$$REL_CODE.list 2>/dev/null; then \
		sudo wget https://www.ubuntulinux.jp/sources.list.d/$$REL_CODE.list -O /etc/apt/sources.list.d/ubuntu-ja.list || true; \
		sudo DEBIAN_FRONTEND=noninteractive apt update || true; \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-defaults-ja || echo "⚠️  Ubuntu Japanese のインストールに失敗しましたが、処理を続行します"; \
	else \
		echo "⚠️  Ubuntu Japanese のリポジトリリスト ($$REL_CODE.list) が見つかりません。スキップします。"; \
	fi

	# キーボード設定
	@echo "⌨️  キーボードレイアウトを設定中..."

	# キーボードレイアウトを英語（US）に設定
	@if command -v setxkbmap >/dev/null 2>&1; then \
		setxkbmap us || true; \
		setxkbmap -option "ctrl:nocaps" || true; \
	else \
		echo "⏭️  setxkbmap が見つからないため、キーボードレイアウト設定をスキップします。"; \
	fi

	@if command -v localectl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then \
		sudo localectl set-keymap us || true; \
		sudo localectl set-x11-keymap us || true; \
	else \
		echo "⏭️  localectl または systemd が利用できないため、システムキーマップの設定をスキップします。"; \
	fi
		# GNOME環境の場合、入力ソースは既にmozc設定で行われているためスキップ
	@echo "✅ GNOME入力ソースはmozc設定で設定されています"

	# CapsLock -> Ctrl
	@sudo update-initramfs -u || true

	@echo "✅ キーボードレイアウトが英語（US）に設定されました"

	# 基本パッケージ
	@echo "📦 基本パッケージをインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt install -y flatpak gdebi chrome-gnome-shell xclip xsel  || echo "⚠️  一部の基本パッケージのインストールに失敗しましたが、処理を続行します"

	# AppImage実行に必要なFUSEパッケージ
	@echo "📦 AppImage実行用のFUSEパッケージをインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt install -y fuse libfuse2t64  fuse3  || \
	sudo DEBIAN_FRONTEND=noninteractive apt install -y fuse libfuse2 fuse3  || \
	sudo DEBIAN_FRONTEND=noninteractive apt install -y fuse fuse3 || true

	# FUSEの設定
	@echo "🔧 FUSEユーザー権限を設定中..."
	@sudo usermod -a -G fuse $(USER) || true
	@sudo chmod +x /usr/bin/fusermount || true
	@sudo chmod u+s /usr/bin/fusermount || true

	# メモリ最適化設定
	@echo "🧠 メモリ最適化設定を適用中..."
	@CURRENT_SWAPPINESS=$$(cat /proc/sys/vm/swappiness  || echo 60); \
	if [ $$CURRENT_SWAPPINESS -ne 10 ]; then \
	echo "📊 現在のスワップ積極度: $$CURRENT_SWAPPINESS"; \
	echo "⚙️  推奨値（vm.swappiness=10）を設定中..."; \
	if ! grep -q "vm.swappiness=10" /etc/sysctl.conf ; then \
	echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf >/dev/null; \
	fi; \
	sudo sysctl vm.swappiness=10 || echo "⚠️  vm.swappiness の設定適用に失敗しましたが、処理を続行します"; \
	NEW_SWAPPINESS=$$(cat /proc/sys/vm/swappiness  || echo "unknown"); \
	echo "✅ スワップ積極度を最適化しました: $$CURRENT_SWAPPINESS → $$NEW_SWAPPINESS"; \
	echo "💡 この設定により、メモリ使用量が90%を超えるまでスワップを使用しません"; \
	else \
	echo "✅ スワップ積極度は既に最適化されています ($$CURRENT_SWAPPINESS)"; \
	fi

	@$(call create_marker,setup-system,N/A)
	@echo "✅ システムレベルの基本設定が完了しました。"
	@echo "🌏 タイムゾーン: $$(timedatectl show --property=Timezone --value  || echo '取得に失敗')"
	@echo "🌐 ロケール: $$(locale | grep LANG  || echo '取得に失敗')"
	@echo "🇯🇵 日本語入力: mozc（IBus）がインストールされました"
	@echo "🧠 メモリ最適化: vm.swappiness=$$(cat /proc/sys/vm/swappiness  || echo 'unknown') に設定されました"
	@echo ""
	@echo "⚠️  重要：設定を反映するため、システムの再起動を推奨します。"
	@echo "🔄 再起動後は Super+Space または Alt+\` で日本語⇔英語切り替えが可能です"
	@echo "⚙️  mozc設定は「設定」→「地域と言語」→「入力ソース」から変更できます"
	@echo "💾 メモリ最適化設定は恒久的に適用されています"
	@echo ""
	@echo "ℹ️  一部のリポジトリでエラーが発生した場合は、以下のコマンドで修正できます："
	@echo "    make clean-repos"

# IBM Plex Sans フォントのインストール（単独実行用）
install-packages-ibm-plex-fonts:
	@echo "🔤 IBM Plex Sans フォントのインストールを開始..."
	@mkdir -p $(HOME_DIR)/.local/share/fonts/ibm-plex
	@cd /tmp && \
	EXISTING_FONTS=$$(fc-list | grep -i "IBM Plex Sans" | wc -l  || echo "0"); \
	echo "🔍 現在認識されているIBM Plex Sansフォント数: $$EXISTING_FONTS"; \
	echo "📥 IBM Plex フォントをダウンロード中..."; \
	rm -rf plex-fonts.zip ibm-plex-sans ; \
	RELEASE_JSON=$$(curl -s --connect-timeout 10 --max-time 30 https://api.github.com/repos/IBM/plex/releases/latest); \
	PLEX_VERSION=$$(echo "$$RELEASE_JSON" | jq -r '.tag_name' 2>/dev/null || echo "$$RELEASE_JSON" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$$' || echo "@ibm/plex-sans@1.1.0"); \
	echo "📦 IBM Plex バージョン: $$PLEX_VERSION"; \
	DOWNLOAD_URL=$$(echo "$$RELEASE_JSON" | jq -r '.assets[] | select(.name == "ibm-plex-sans.zip") | .browser_download_url' 2>/dev/null); \
	if [ -z "$$DOWNLOAD_URL" ] || [ "$$DOWNLOAD_URL" = "null" ]; then \
		ENCODED_VERSION=$$(echo "$$PLEX_VERSION" | sed 's/@/%40/g'); \
		DOWNLOAD_URL="https://github.com/IBM/plex/releases/download/$$ENCODED_VERSION/ibm-plex-sans.zip"; \
	fi; \
	echo "🔗 ダウンロードURL: $$DOWNLOAD_URL"; \
	if wget --timeout=30 "$$DOWNLOAD_URL" -O plex-fonts.zip; then \
	echo "✅ ダウンロード完了 ($$(ls -lh plex-fonts.zip | awk '{print $$5}'))"; \
	if [ -f plex-fonts.zip ] && [ -s plex-fonts.zip ]; then \
	echo "📂 ZIPファイルを展開中..."; \
	if unzip -q plex-fonts.zip; then \
	if [ -d ibm-plex-sans/fonts/complete/ttf ]; then \
	FONT_COUNT=$$(find ibm-plex-sans/fonts/complete/ttf -name "*.ttf" | wc -l); \
	echo "📊 展開されたフォントファイル数: $$FONT_COUNT"; \
	if [ "$$FONT_COUNT" -gt 0 ]; then \
	echo "📋 フォントファイルをコピー中..."; \
	cp ibm-plex-sans/fonts/complete/ttf/*.ttf $(HOME_DIR)/.local/share/fonts/ibm-plex/ && \
	COPIED_COUNT=$$(ls -1 $(HOME_DIR)/.local/share/fonts/ibm-plex/*.ttf | wc -l  || echo "0"); \
	echo "✅ コピー完了: $$COPIED_COUNT 個のフォントファイル"; \
	rm -rf plex-fonts.zip ibm-plex-sans ; \
	echo "🔄 フォントキャッシュを更新中..."; \
	(fc-cache -f  && echo "✅ フォントキャッシュ更新完了") || echo "⚠️  フォントキャッシュの更新をスキップ（システムが自動更新します）"; \
	FINAL_COUNT=$$(fc-list | grep -i "IBM Plex Sans" | wc -l  || echo "0"); \
	echo "🎉 インストール完了: $$FINAL_COUNT 個のIBM Plex Sansフォントが認識されています"; \
	echo ""; \
	echo "📋 インストールされたフォント一覧:"; \
	fc-list | grep -i "IBM Plex Sans" | head -5 | sed 's/^/  /' || echo "  (フォント一覧の取得に失敗)"; \
	if [ $$(fc-list | grep -i "IBM Plex Sans" | wc -l) -gt 5 ]; then \
	echo "  ...他 $$(($$FINAL_COUNT - 5)) 個"; \
	fi; \
	else \
	echo "❌ TTFファイルが見つかりません"; \
	rm -rf plex-fonts.zip ibm-plex-sans ; \
	fi; \
	else \
	echo "❌ 期待されるディレクトリ構造が見つかりません"; \
	rm -rf plex-fonts.zip ibm-plex-sans ; \
	fi; \
	else \
	echo "❌ ZIPファイルの展開に失敗しました"; \
	rm -rf plex-fonts.zip ibm-plex-sans ; \
	fi; \
	else \
	echo "❌ ダウンロードされたファイルが空または見つかりません"; \
	rm -rf plex-fonts.zip ; \
	fi; \
	else \
	echo "❌ IBM Plex フォントのダウンロードに失敗しました"; \
	echo "ℹ️  インターネット接続を確認してください"; \
	rm -rf plex-fonts.zip ; \
	fi

# Cica Nerd Fonts のインストール（単独実行用）
install-packages-cica-fonts:
	@echo "🔤 Cica Nerd Fonts のインストールを開始..."
	@mkdir -p $(HOME_DIR)/.local/share/fonts/cica
	@cd /tmp && \
	EXISTING_FONTS=$$(fc-list | grep -i "Cica" | wc -l  || echo "0"); \
	echo "🔍 現在認識されているCicaフォント数: $$EXISTING_FONTS"; \
	if [ "$$EXISTING_FONTS" -lt 4 ]; then \
	echo "📥 Cica フォントをダウンロード中..."; \
	rm -rf cica-fonts.zip Cica_* ; \
	CICA_VERSION=$$(curl -s --connect-timeout 10 --max-time 30 https://api.github.com/repos/miiton/Cica/releases/latest | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$$'  || echo "v5.0.3"); \
	echo "📦 Cica バージョン: $$CICA_VERSION"; \
	DOWNLOAD_URL="https://github.com/miiton/Cica/releases/download/$$CICA_VERSION/Cica_$${CICA_VERSION#v}.zip"; \
	echo "🔗 ダウンロードURL: $$DOWNLOAD_URL"; \
	if wget --timeout=30 "$$DOWNLOAD_URL" -O cica-fonts.zip ; then \
	echo "✅ ダウンロード完了 ($$(ls -lh cica-fonts.zip | awk '{print $$5}'))"; \
	if [ -f cica-fonts.zip ] && [ -s cica-fonts.zip ]; then \
	echo "📂 ZIPファイルを展開中..."; \
	if unzip -q cica-fonts.zip; then \
	FONT_COUNT=$$(find . -maxdepth 1 -name "Cica*.ttf" | wc -l); \
	echo "📊 展開されたフォントファイル数: $$FONT_COUNT"; \
	if [ "$$FONT_COUNT" -gt 0 ]; then \
	echo "📋 フォントファイルをコピー中..."; \
	cp Cica*.ttf $(HOME_DIR)/.local/share/fonts/cica/  && \
	COPIED_COUNT=$$(ls -1 $(HOME_DIR)/.local/share/fonts/cica/Cica*.ttf | wc -l  || echo "0"); \
	echo "✅ コピー完了: $$COPIED_COUNT 個のフォントファイル"; \
	rm -rf cica-fonts.zip Cica*.ttf ; \
	echo "🔄 フォントキャッシュを更新中..."; \
	(fc-cache -f  && echo "✅ フォントキャッシュ更新完了") || echo "⚠️  フォントキャッシュの更新をスキップ（システムが自動更新します）"; \
	FINAL_COUNT=$$(fc-list | grep -i "Cica" | wc -l  || echo "0"); \
	echo "🎉 インストール完了: $$FINAL_COUNT 個のCicaフォントが認識されています"; \
	echo ""; \
	echo "📋 インストールされたフォント一覧:"; \
	fc-list | grep -i "Cica" | sed 's/^/  /' || echo "  (フォント一覧の取得に失敗)"; \
	else \
	echo "❌ TTFファイルが見つかりません"; \
	rm -rf cica-fonts.zip Cica*.ttf ; \
	fi; \
	else \
	echo "❌ ZIPファイルの展開に失敗しました"; \
	rm -rf cica-fonts.zip ; \
	fi; \
	else \
	echo "❌ ダウンロードされたファイルが空または見つかりません"; \
	rm -rf cica-fonts.zip ; \
	fi; \
	else \
	echo "❌ Cica フォントのダウンロードに失敗しました"; \
	echo "ℹ️  インターネット接続を確認してください"; \
	echo "💡 手動インストール方法:"; \
	echo "    1. https://github.com/miiton/Cica/releases にアクセス"; \
	echo "    2. 最新版のCica_*.zipをダウンロード"; \
	echo "    3. ダウンロード後、再度このコマンドを実行"; \
	rm -rf cica-fonts.zip ; \
	fi; \
	else \
	echo "✅ Cica フォントは既に十分にインストールされています ($$EXISTING_FONTS 個)"; \
	fi
