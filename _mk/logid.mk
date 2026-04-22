# logid (logiops) Management Module
# Logicool製マウスのボタン割り当てツールのインストールと設定

.PHONY: logid-install logid-setup logid-restart logid-status logid-debug logid-clean

# 依存パッケージのインストールとソースからのビルド
logid-install:
	@echo "🛠️ Installing logiops dependencies..."
	@sudo apt update
	@sudo apt install -y cmake libevdev-dev libudev-dev libconfig++-dev
	@echo "🏗️ Building logiops from source..."
	@if [ -d "logiops" ]; then \
		mkdir -p logiops/build; \
		cd logiops/build && cmake .. && make && sudo make install; \
	else \
		echo "❌ Error: logiops directory not found. Please clone it first."; \
		exit 1; \
	fi
	@echo "✅ logid installed successfully"

# 設定ファイルの反映とサービスのセットアップ
logid-setup:
	@echo "⚙️ Setting up logid configuration..."
	@if [ ! -x "/usr/local/bin/logid" ]; then \
		echo "❌ Error: /usr/local/bin/logid not found. Please run 'make logid-install' first."; \
		exit 1; \
	fi
	# 設定ファイルのシンボリックリンク作成
	@sudo ln -sf $(REPO_ROOT)/logid/logid.cfg /etc/logid.cfg
	# サービスファイルの配置
	@sudo cp $(REPO_ROOT)/logid/logid.service /etc/systemd/system/logid.service
	@sudo systemctl daemon-reload
	@sudo systemctl enable --now logid
	@echo "✅ logid configuration applied and service started"

# サービスの再起動
logid-restart:
	@echo "🔄 Restarting logid service..."
	@sudo systemctl restart logid
	@echo "✅ logid service restarted"

# ステータスとログの確認
logid-status:
	@echo "📊 Checking logid service status..."
	@systemctl status logid --no-pager || true
	@echo ""
	@echo "📝 Recent logs:"
	@journalctl -u logid -n 20 --no-pager

# デバッグモード（ボタンID確認用）
logid-debug:
	@echo "🪲 Starting logid in debug mode (Ctrl+C to stop)..."
	@sudo systemctl stop logid
	@sudo logid -v

# ビルド成果物の削除
logid-clean:
	@if [ -d "logiops/build" ]; then \
		rm -rf logiops/build; \
		echo "🧹 Cleaned up logiops build directory"; \
	fi
