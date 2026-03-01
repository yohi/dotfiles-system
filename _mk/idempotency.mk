# 冪等性管理と共通ユーティリティのマクロ定義
MARKER_DIR := $(HOME)/.make_markers

# マーカーの作成: $(call create_marker,name,version)
define create_marker
	@mkdir -p "$(MARKER_DIR)"
	@echo "$(2)" > "$(MARKER_DIR)/$(1).version"
	@touch "$(MARKER_DIR)/$(1)"
endef

# マーカーの存在確認: $(call check_marker,name)
# Returns a shell command for use in Makefile recipes
check_marker = [ -f "$(MARKER_DIR)/$(1)" ]

# スキップメッセージの表示
IDEMPOTENCY_SKIP_MSG = ✅ $(1) は既に完了しているためスキップします。

# コマンドの存在確認: $(call check_command,command)
check_command = command -v $(1) >/dev/null 2>&1

# 共通ターゲット: Node.jsの確認
.PHONY: check-nodejs
check-nodejs:
	@command -v node >/dev/null 2>&1 || { echo "❌ Node.js がインストールされていません"; exit 1; }
