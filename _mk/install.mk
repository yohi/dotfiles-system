# Homebrewのインストール
install-packages-homebrew:
	@if $(call check_command,brew); then \
		echo "$(call IDEMPOTENCY_SKIP_MSG,install-packages-homebrew)"; \
		exit 0; \
	fi
	@echo "🍺 Homebrewをインストール中..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "📥 Homebrewをダウンロード・インストール..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		\
		echo "🔧 Homebrew環境設定を追加中..."; \
		if ! grep -q 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' $(HOME_DIR)/.bashrc 2>/dev/null; then \
			echo "📝 .bashrcにHomebrew設定を追加中..."; \
			echo '' >> $(HOME_DIR)/.bashrc; \
			echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(HOME_DIR)/.bashrc; \
		else \
			echo "✅ .bashrcには既にHomebrew設定が存在します"; \
		fi; \
		\
		if [ -f "$(HOME_DIR)/.zshrc" ] || command -v zsh >/dev/null 2>&1; then \
			if ! grep -q 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' $(HOME_DIR)/.zshrc 2>/dev/null; then \
				echo "📝 .zshrcにHomebrew設定を追加中..."; \
				echo '' >> $(HOME_DIR)/.zshrc 2>/dev/null || touch $(HOME_DIR)/.zshrc; \
				echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(HOME_DIR)/.zshrc; \
			else \
				echo "✅ .zshrcには既にHomebrew設定が存在します"; \
			fi; \
		fi; \
		\
		echo "🚀 現在のセッションでHomebrewを有効化..."; \
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		\
		echo "📦 Homebrew依存関係の確認・インストール..."; \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential || true; \
		fi; \
		\
		echo "🔨 GCCをインストール中（推奨）..."; \
		brew install gcc || true; \
		\
		echo "✅ Homebrewのセットアップが完了しました"; \
	else \
		echo "✅ Homebrewは既にインストールされています。"; \
		echo "🔧 環境変数を確認中..."; \
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" || true; \
		\
		echo "🔍 Homebrew設定を確認中..."; \
		if ! grep -q 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' $(HOME_DIR)/.bashrc 2>/dev/null; then \
			echo "📝 .bashrcにHomebrew設定を追加中..."; \
			echo '' >> $(HOME_DIR)/.bashrc; \
			echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(HOME_DIR)/.bashrc; \
		else \
			echo "✅ .bashrcには既にHomebrew設定が存在します"; \
		fi; \
		\
		if [ -f "$(HOME_DIR)/.zshrc" ] || command -v zsh >/dev/null 2>&1; then \
			if ! grep -q 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' $(HOME_DIR)/.zshrc 2>/dev/null; then \
				echo "📝 .zshrcにHomebrew設定を追加中..."; \
				echo '' >> $(HOME_DIR)/.zshrc 2>/dev/null || touch $(HOME_DIR)/.zshrc; \
				echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $(HOME_DIR)/.zshrc; \
			else \
				echo "✅ .zshrcには既にHomebrew設定が存在します"; \
			fi; \
		fi; \
	fi

	@echo "📋 Homebrewの状態確認:"
	@echo "   バージョン: $$(brew --version | head -1 2>/dev/null || echo '取得できませんでした')"
	@echo "   インストール先: $$(brew --prefix 2>/dev/null || echo '取得できませんでした')"
	@echo "✅ Homebrewのインストールが完了しました。"

# AppImage実行用のFUSEパッケージをインストール
install-packages-fuse:
	@echo "📦 AppImage実行用のFUSEパッケージをインストール中..."
	@echo "ℹ️  これによりCursor、PostmanなどのAppImageアプリケーションが実行可能になります"

	# 問題のあるリポジトリの一時的な無効化
	@echo "🔧 問題のあるリポジトリの確認と修正..."
	@if [ -f /etc/apt/sources.list.d/google-chrome-beta.list ]; then \
		echo "ℹ️  重複するGoogle Chromeリポジトリを修正中..."; \
		sudo rm -f /etc/apt/sources.list.d/google-chrome-beta.list 2>/dev/null || true; \
	fi

	# Ubuntu 25.04で利用できないPPAの無効化（CopyQは除外）
	@echo "🔧 Ubuntu 25.04で利用できないPPAを一時的に無効化中..."
	# CopyQ PPAは正常なPPAなので無効化しない
	@if [ -f /etc/apt/sources.list.d/remmina-ppa-team-ubuntu-remmina-next-plucky.list ]; then \
		sudo mv /etc/apt/sources.list.d/remmina-ppa-team-ubuntu-remmina-next-plucky.list /etc/apt/sources.list.d/remmina-ppa-team-ubuntu-remmina-next-plucky.list.disabled 2>/dev/null || true; \
	fi

	# システムパッケージの更新（エラーを抑制）
	@echo "📦 パッケージリストを更新中..."
	@sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"

	# FUSEパッケージのインストール
	@echo "🔧 FUSEライブラリをインストール中..."
	@echo "ℹ️  Ubuntu 25.04対応: 新しいパッケージ名でインストールを試行中..."

	# Ubuntu 25.04以降の新しいパッケージ名でインストール
	@sudo DEBIAN_FRONTEND=noninteractive apt install -y fuse libfuse2t64  libfuse3-dev fuse3 2>/dev/null || \
	echo "⚠️  新しいパッケージ名でのインストールに失敗、従来名を試行中..."

	# 従来のパッケージ名でのフォールバック
	@sudo DEBIAN_FRONTEND=noninteractive apt install -y fuse libfuse2 libfuse2-dev fuse3 libfuse3-dev 2>/dev/null || \
	echo "⚠️  従来のパッケージ名でもインストールに失敗"

	# 最低限必要なパッケージのみを確実にインストール
	@echo "🔧 最低限必要なFUSEパッケージをインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt install -y fuse fuse3 || \
	echo "⚠️  基本FUSEパッケージのインストールに失敗しました"

	# FUSEユーザー権限の設定
	@echo "👤 FUSEユーザー権限を設定中..."
	@sudo usermod -a -G fuse $(USER) || true
	@sudo chmod +x /usr/bin/fusermount 2>/dev/null || true
	@sudo chmod u+s /usr/bin/fusermount 2>/dev/null || true
	@sudo chmod +x /usr/bin/fusermount3 2>/dev/null || true
	@sudo chmod u+s /usr/bin/fusermount3 2>/dev/null || true

	# FUSEモジュールのロード
	@echo "⚙️  FUSEモジュールをロード中..."
	@sudo modprobe fuse || true

	@echo "✅ FUSEパッケージのインストールが完了しました。"

# Brewfileを使用してアプリケーションをインストール
install-packages-apps:
ifndef FORCE
	@if [ -n "$(call check_marker,install-packages-apps)" ] && $(call check_marker,install-packages-apps) 2>/dev/null; then \
		echo "$(call IDEMPOTENCY_SKIP_MSG,install-packages-apps)"; \
		exit 0; \
	fi
endif
	@echo "📦 アプリケーションをインストール中..."
	@if command -v brew >/dev/null 2>&1; then \
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		echo "🍺 Brewパッケージをインストール中..."; \
		brew bundle --file=$(REPO_ROOT)/Brewfile --no-upgrade; \
	else \
		echo "❌ Homebrewがインストールされていません。先に 'make install-packages-homebrew' を実行してください。"; \
		exit 1; \
	fi
	@$(call create_marker,install-packages-apps,N/A)
	@echo "✅ アプリケーションのインストールが完了しました。"

# DEBパッケージをインストール（IDE・ブラウザ含む）
install-packages-deb:
ifndef FORCE
	@if [ -n "$(call check_marker,install-packages-deb)" ] && $(call check_marker,install-packages-deb) 2>/dev/null; then \
		echo "$(call IDEMPOTENCY_SKIP_MSG,install-packages-deb)"; \
		exit 0; \
	fi
endif
	@echo "📦 DEBパッケージをインストール中..."
	@echo "ℹ️  IDE・ブラウザ・開発ツールをインストールします"

	# パッケージリストを更新
	@echo "🔄 パッケージリストを更新中..."
	@sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"

	# Visual Studio Code のインストール
	@echo "📝 Visual Studio Code のインストール中..."
	@if ! command -v code >/dev/null 2>&1; then \
		echo "📥 Microsoft GPGキーを追加中..."; \
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg; \
		sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/; \
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'; \
		sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"; \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y code; \
		rm -f packages.microsoft.gpg; \
	else \
		echo "✅ Visual Studio Code は既にインストールされています"; \
	fi

	# Google Chrome Stable のインストール
	@echo "🌐 Google Chrome Stable のインストール中..."
	@if ! command -v google-chrome-stable >/dev/null 2>&1; then \
		echo "📥 Google GPGキーをダウンロード・設定中..."; \
		sudo mkdir -p /usr/share/keyrings; \
		curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg; \
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list; \
		sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"; \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y google-chrome-stable; \
	else \
		echo "✅ Google Chrome Stable は既にインストールされています"; \
	fi

	# Google Chrome Beta のインストール
	@echo "🌐 Google Chrome Beta のインストール中..."
	@if ! command -v google-chrome-beta >/dev/null 2>&1; then \
		echo "📥 Google Chrome リポジトリの確認中..."; \
		if ! grep -q "chrome/deb" /etc/apt/sources.list.d/google-chrome.list 2>/dev/null; then \
			echo "📥 Google GPGキーをダウンロード・設定中..."; \
			sudo mkdir -p /usr/share/keyrings; \
			curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg; \
			sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'; \
			sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"; \
		fi; \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y google-chrome-beta; \
	else \
		echo "✅ Google Chrome Beta は既にインストールされています"; \
	fi

	# Chromium のインストール
	@echo "🌐 Chromium のインストール中..."
	@if ! command -v chromium-browser >/dev/null 2>&1; then \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y chromium-browser; \
	else \
		echo "✅ Chromium は既にインストールされています"; \
	fi

	# FUSE（AppImage実行用）のインストール
	@echo "🔧 FUSE（AppImage実行用）のインストール中..."
	@$(MAKE) install-packages-fuse

	# Cursor IDE のインストール
	@echo "💻 Cursor IDE のインストール中..."
	@$(MAKE) install-packages-cursor

	# WezTerm のインストール
	@echo "🖥️  WezTerm のインストール中..."
	@if ! command -v wezterm >/dev/null 2>&1; then \
		echo "📦 WezTerm GPGキーを追加中..."; \
		curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg; \
		echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list; \
		sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"; \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y wezterm; \
	else \
		echo "✅ WezTerm は既にインストールされています"; \
	fi

	@$(call create_marker,install-packages-deb,N/A)
	@echo "✅ DEBパッケージのインストールが完了しました"
	@echo "📋 インストール完了項目:"
	@echo "   - Visual Studio Code"
	@echo "   - Google Chrome Stable"
	@echo "   - Google Chrome Beta"
	@echo "   - Chromium"
	@echo "   - FUSE（AppImage実行用）"
	@echo "   - Cursor IDE"
	@echo "   - WezTerm"

# Playwright E2Eテストフレームワークのインストール
install-packages-playwright:
	@echo "🎭 Playwright E2Eテストフレームワークのインストールを開始..."

	# Node.jsの確認
	@$(MAKE) check-nodejs

	# npmの確認
	@echo "🔍 npm の確認中..."
	@if ! command -v npm >/dev/null 2>&1; then \
		echo "❌ npm がインストールされていません"; \
		echo "ℹ️  通常はNode.jsと一緒にインストールされます"; \
		exit 1; \
	else \
		echo "✅ npm が見つかりました (バージョン: $$(npm --version))"; \
	fi

	# Playwright のインストール確認
	@echo "🔍 既存の Playwright インストールを確認中..."
	@if command -v npx >/dev/null 2>&1 && npx playwright --version >/dev/null 2>&1; then \
		echo "✅ Playwright は既にインストールされています"; \
		echo "   バージョン: $$(npx playwright --version 2>/dev/null || echo '取得できませんでした')"; \
		echo ""; \
		echo "🔄 Playwright をアップデート中..."; \
		npm update -g @playwright/test 2>/dev/null || npm install -g @playwright/test@latest 2>/dev/null || true; \
		echo "🌐 ブラウザバイナリをアップデート中..."; \
		npx playwright install 2>/dev/null || true; \
	else \
		echo "📦 Playwright をインストール中..."; \
		echo "ℹ️  グローバルインストールを実行します: npm install -g @playwright/test"; \
		\
		if npm install -g @playwright/test; then \
			echo "✅ Playwright のインストールが完了しました"; \
		else \
			echo "❌ Playwright のインストールに失敗しました"; \
			echo ""; \
			echo "🔧 トラブルシューティング:"; \
			echo "1. 権限の問題: npm config set prefix $(HOME)/.local"; \
			echo "2. WSLの場合: npm config set os linux"; \
			echo "3. ローカルプロジェクトでのインストール: npm install @playwright/test"; \
			echo "4. 強制インストール: npm install -g @playwright/test --force"; \
			echo ""; \
			exit 1; \
		fi; \
		\
		echo "🌐 ブラウザバイナリをインストール中..."; \
		echo "ℹ️  Chromium、Firefox、WebKit のブラウザエンジンをダウンロードします"; \
		if npx playwright install; then \
			echo "✅ ブラウザバイナリのインストールが完了しました"; \
		else \
			echo "⚠️  ブラウザバイナリのインストールに失敗しました"; \
			echo "ℹ️  手動でインストールしてください: npx playwright install"; \
		fi; \
	fi

	# システム依存関係のインストール (Linux)
	@echo "📦 システム依存関係をインストール中..."
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "🔧 Linux向けの依存関係をインストール中..."; \
		sudo apt update -q 2>/dev/null || echo "⚠️  パッケージリストの更新で問題が発生しましたが、処理を続行します"; \
		npx playwright install-deps 2>/dev/null || \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y \
			libnss3 \
			libatk-bridge2.0-0 \
			libdrm2 \
			libgtk-3-0 \
			libgbm1 \
			libasound2 \
			fonts-liberation \
			libappindicator3-1 \
			libxss1 \
			xdg-utils 2>/dev/null || \
		echo "⚠️  一部の依存関係のインストールに失敗しましたが、処理を続行します"; \
	else \
		echo "ℹ️  Linuxではないため、システム依存関係のインストールをスキップします"; \
	fi

	# インストール確認
	@echo "🔍 インストールの確認中..."
	@if command -v npx >/dev/null 2>&1 && npx playwright --version >/dev/null 2>&1; then \
		echo "✅ Playwright が正常にインストールされました"; \
		echo "   実行ファイル: npx playwright"; \
		echo "   バージョン: $$(npx playwright --version 2>/dev/null || echo '取得できませんでした')"; \
		echo ""; \
		echo "🌐 インストール済みブラウザの確認:"; \
		npx playwright --help | grep -A 5 "browsers" 2>/dev/null || \
		echo "   ℹ️  npx playwright install でブラウザをインストールできます"; \
	else \
		echo "❌ Playwright のインストール確認に失敗しました"; \
		echo "ℹ️  PATH の問題の可能性があります"; \
		echo "   手動確認: npx playwright --version"; \
		exit 1; \
	fi

	@echo ""
	@echo "🎉 Playwright のセットアップガイド:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "🚀 基本的な使用方法:"
	@echo "1. プロジェクトディレクトリに移動: cd your-project-directory"
	@echo "2. Playwright 設定ファイルを生成: npx playwright init"
	@echo "3. テストファイルを作成: npx playwright codegen"
	@echo "4. テストを実行: npx playwright test"
	@echo ""
	@echo "📋 主要なコマンド:"
	@echo "   npx playwright test              - すべてのテストを実行"
	@echo "   npx playwright test --ui         - UIモードでテストを実行"
	@echo "   npx playwright test --headed     - ブラウザ表示モードで実行"
	@echo "   npx playwright test --debug      - デバッグモードで実行"
	@echo "   npx playwright codegen <URL>     - テストコードを生成"
	@echo "   npx playwright show-report       - テストレポートを表示"
	@echo "   npx playwright install           - ブラウザバイナリを再インストール"
	@echo ""
	@echo "🌐 対応ブラウザ:"
	@echo "   ✓ Chromium (Chrome、Microsoft Edge)"
	@echo "   ✓ Firefox"
	@echo "   ✓ WebKit (Safari)"
	@echo ""
	@echo "📱 対応プラットフォーム:"
	@echo "   ✓ デスクトップ (Windows、macOS、Linux)"
	@echo "   ✓ モバイル (Android、iOS シミュレータ)"
	@echo ""
	@echo "🎯 主要機能:"
	@echo "   - クロスブラウザテスト自動化"
	@echo "   - モバイルデバイステスト"
	@echo "   - スクリーンショット・動画記録"
	@echo "   - パフォーマンステスト"
	@echo "   - APIテスト"
	@echo "   - 視覚的回帰テスト"
	@echo ""
	@echo "📚 詳細なドキュメント:"
	@echo "   公式サイト: https://playwright.dev/"
	@echo "   ガイド: https://playwright.dev/docs/intro"
	@echo "   API リファレンス: https://playwright.dev/docs/api/class-playwright"
	@echo ""
	@echo "💡 おすすめワークフロー:"
	@echo "   1. 'npx playwright init' でプロジェクトをセットアップ"
	@echo "   2. 'npx playwright codegen' でテストを録画生成"
	@echo "   3. 'npx playwright test --ui' でテストをデバッグ・実行"
	@echo "   4. CI/CDパイプラインに組み込んで継続的テスト"
	@echo ""
	@echo "✅ Playwright のインストールが完了しました"

# ========================================
# エイリアス
# ========================================

.PHONY: install-playwright
install-playwright: install-packages-playwright  ## Playwrightをインストール(エイリアス)


# ccusage のインストール
install-packages-ccusage:
	@echo "📦 ccusage をインストールしています..."
	@if ! command -v bun >/dev/null 2>&1; then \
		if command -v brew >/dev/null 2>&1; then \
			echo "🍺 Homebrewを使用してbunをインストール中..."; \
			if ! brew install bun; then \
				echo "⚠️  Homebrewでのインストールに失敗しました。公式インストーラーにフォールバックします..."; \
				curl -fsSL https://bun.sh/install | bash; \
			fi; \
		else \
			echo "🔐 Bunをインストール中（公式インストーラー使用）..."; \
			curl -fsSL https://bun.sh/install | bash; \
		fi; \
		export PATH="$(HOME)/.bun/bin:$$PATH"; \
		if ! command -v bun >/dev/null 2>&1; then \
			echo "❌ bun のインストールに失敗しました。PATH を確認してください。"; \
			exit 1; \
		fi; \
	fi
	@echo "🔧 ccusage をグローバル導入中..."
	@export PATH="$(HOME)/.bun/bin:$$PATH"; \
	CCUSAGE_VERSION="15.0.1"; \
	echo "📦 ccusage ($$CCUSAGE_VERSION) をインストール中..."; \
	if ! bun add -g ccusage@$$CCUSAGE_VERSION; then \
		echo "⚠️ bun add -g に失敗。bunx での実行にフォールバックします"; \
	fi
	@echo "🔍 動作確認: ccusage --version"
	@export PATH="$(HOME)/.bun/bin:$$PATH"; \
	if ! bunx -y ccusage --version >/dev/null 2>&1; then \
		echo "⚠️ bunx 実行確認に失敗しました（ネットワーク状況を確認してください）"; \
	fi
	@echo "✅ ccusage のインストールが完了しました。"

# 追加のブラウザインストール系
install-packages-chrome-beta:
	@echo "🌐 Google Chrome Beta のインストール中..."
	@if ! command -v google-chrome-beta >/dev/null 2>&1; then \
		echo "📥 Google Chrome リポジトリの確認中..."; \
		if ! grep -q "chrome/deb" /etc/apt/sources.list.d/google-chrome.list 2>/dev/null; then \
			echo "📥 Google GPGキーをダウンロード・設定中..."; \
			sudo mkdir -p /usr/share/keyrings; \
			curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg; \
			sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'; \
			sudo apt update -q 2>/dev/null || echo "⚠️  一部のリポジトリで問題がありますが、処理を続行します"; \
		fi; \
		sudo DEBIAN_FRONTEND=noninteractive apt install -y google-chrome-beta; \
	else \
		echo "✅ Google Chrome Beta は既にインストールされています"; \
	fi
	@echo "✅ Google Chrome Beta のインストールが完了しました"

# ========================================
# 後方互換性のためのエイリアス (一部のみここに定義)
# ほとんどの後方互換エイリアスは mk/deprecated-targets.mk で一元管理されています。
# ========================================

# ここでは、単純な転送のみが必要な少数のエイリアスのみを定義しています。
# 詳細な非推奨ポリシー（警告、期限など）は mk/deprecated-targets.mk を参照してください。

# SuperCopilot Framework for VSCode のインストール
install-packages-vscode-supercopilot:
	@echo "📦 SuperCopilot Framework for VSCode をインストール中..."
	@if [ ! -f vscode/setup-supercopilot.sh ]; then \
		echo "❌ エラー: vscode/setup-supercopilot.sh が見つかりません"; \
		exit 1; \
	fi
	@bash vscode/setup-supercopilot.sh || (echo "❌ エラー: SuperCopilot セットアップスクリプトの実行に失敗しました" && exit 1)

# 後方互換性のためのエイリアス
install-vscode-supercopilot: install-packages-vscode-supercopilot

# ccusage の後方互換エイリアス
install-ccusage: install-packages-ccusage

# ImageMagick のインストール（アイコン変換用）
install-imagemagick:
	@echo "🎨 ImageMagick（アイコン変換用）をインストール中..."
	@if command -v convert >/dev/null 2>&1; then \
		echo "✅ ImageMagickは既にインストールされています"; \
	else \
		echo "📦 ImageMagickをインストール中..."; \
		sudo apt-get update >/dev/null 2>&1 && \
		sudo apt-get install -y imagemagick >/dev/null 2>&1 && \
		echo "✅ ImageMagickのインストールが完了しました"; \
	fi

# ========================================
# テスト用ターゲット
# ========================================

# システム情報の表示
system-info:
	@echo "🖥️ システム情報:"
	@uname -a
	@echo ""; \
	@echo "📦 パッケージ管理システム:"
	@command -v apt-get && echo "APT (Debian/Ubuntu)" || echo "APT not found"
	@command -v brew && echo "Homebrew (Linuxbrew)" || echo "Homebrew not found"
	@command -v dnf && echo "DNF (Fedora)" || echo "DNF not found"
	@command -v pacman && echo "Pacman (Arch Linux)" || echo "Pacman not found"
	@echo ""; \
	@echo "🔧 シェル情報:"
	@echo "   SHELL: $$SHELL"
	@echo "   BASH_VERSION: $$BASH_VERSION"
	@echo "   ZSH_VERSION: $$ZSH_VERSION"
	@echo ""; \
	@echo "📂 ホームディレクトリ: $$HOME"
	@echo "📂 カレントディレクトリ: $$PWD"
	@echo ""; \
	@echo "🔄 環境変数:"
	@printenv | sort

# インストール済みパッケージのリスト表示
list-installed-packages:
	@echo "📦 インストール済みパッケージのリスト:"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Homebrew パッケージ:"; \
		brew list --versions; \
		echo ""; \
	fi
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "APT パッケージ:"; \
		dpkg --get-selections | grep -v deinstall; \
		echo ""; \
	fi
	@if command -v rpm >/dev/null 2>&1; then \
		echo "RPM パッケージ:"; \
		rpm -qa; \
		echo ""; \
	fi
	@if command -v pacman >/dev/null 2>&1; then \
		echo "Pacman パッケージ:"; \
		pacman -Q; \
		echo ""; \
	fi

# システムの再起動
restart-system:
	@echo "🔄 システムを再起動しようとしています..."
	@echo "⚠️  この操作により、すべての未保存の作業が失われます。"
	@printf "本当にシステムを再起動しますか? (y/N): " && read confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "システムを再起動します..."; \
		sudo reboot; \
	else \
		echo "再起動をキャンセルしました。"; \
	fi

# システムのシャットダウン
shutdown-system:
	@echo "⏹️ システムをシャットダウンしようとしています..."
	@echo "⚠️  この操作により、すべての未保存の作業が失われます。"
	@printf "本当にシステムをシャットダウンしますか? (y/N): " && read confirm; \
			if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
				echo "システムをシャットダウンします..."; \
				sudo shutdown now; \
			else \
				echo "シャットダウンをキャンセルしました。"; \
			fi
