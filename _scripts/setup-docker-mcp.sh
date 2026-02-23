#!/bin/bash
set -euo pipefail

# Target files
TARGETS=(
  "cursor/mcp.json"
  "claude/claude-settings.json"
  "opencode/opencode.jsonc"
  "opencode/antigravity.json"
  "gemini/Core/personas.json"
)

ALLOW_JSONC_OVERWRITE="${ALLOW_JSONC_OVERWRITE:-0}"

if [[ "${1:-}" == "--allow-jsonc-overwrite" ]]; then
  ALLOW_JSONC_OVERWRITE=1
  shift
fi

if [[ "$#" -gt 0 ]]; then
  echo "❌ エラー: 不明な引数です: $*"
  echo "使用方法: bash scripts/setup-docker-mcp.sh [--allow-jsonc-overwrite]"
  exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ エラー: jq がインストールされていません。インストールしてください。"
  exit 1
fi

# Check if node/npx is installed
if ! command -v npx >/dev/null 2>&1; then
  echo "❌ エラー: npx (Node.js) がインストールされていません。インストールしてください。"
  exit 1
fi

TMP=""
FILE_TMP=""

cleanup() {
  if [[ -n "${TMP:-}" ]]; then
    rm -f "$TMP"
  fi
  if [[ -n "${FILE_TMP:-}" ]]; then
    rm -f "$FILE_TMP"
  fi
}

trap cleanup EXIT

set_payload_for_target() {
  local file="$1"

  if [[ "$file" == "opencode/opencode.jsonc" ]]; then
    TARGET_KEY="mcp"
    DOCKER_PAYLOAD='{"type":"local","command":["npx","-y","@docker/mcp-server"]}'
  else
    TARGET_KEY="mcpServers"
    DOCKER_PAYLOAD='{"command":"npx","args":["-y","@docker/mcp-server"]}'
  fi

  PAYLOAD=$(jq -cn --arg key "$TARGET_KEY" --argjson docker "$DOCKER_PAYLOAD" '{($key): {docker: $docker}}')
}

merge_jsonc_preserving_comments() {
  local file="$1"
  local target_key="$2"
  local docker_payload="$3"

  JSONC_FILE="$file" \
  JSONC_TARGET_KEY="$target_key" \
  JSONC_DOCKER_PAYLOAD="$docker_payload" \
  npx -y -p jsonc-parser node -e '
    const fs = require("fs");
    const { parse, modify, applyEdits } = require("jsonc-parser");

    const file = process.env.JSONC_FILE;
    const targetKey = process.env.JSONC_TARGET_KEY;
    const dockerPayload = JSON.parse(process.env.JSONC_DOCKER_PAYLOAD);

    const content = fs.readFileSync(file, "utf8");
    const source = content.trim() === "" ? "{}" : content;

    const errors = [];
    parse(source, errors, {
      allowTrailingComma: true,
      disallowComments: false,
      allowEmptyContent: true
    });

    if (errors.length > 0) {
      console.error("❌ エラー: JSONCパースに失敗しました:", file);
      for (const err of errors) {
        console.error(`  - offset=${err.offset}, length=${err.length}, error=${err.error}`);
      }
      process.exit(1);
    }

    const edits = modify(source, [targetKey, "docker"], dockerPayload, {
      formattingOptions: {
        insertSpaces: true,
        tabSize: 2,
        eol: "\n"
      }
    });

    const updated = applyEdits(source, edits);
    fs.writeFileSync(file, updated);
  '
}

for FILE in "${TARGETS[@]}"; do
  set_payload_for_target "$FILE"

  # Ensure directory exists
  DIR=$(dirname "$FILE")
  if [ ! -d "$DIR" ]; then
    echo "📂 ディレクトリを作成中: $DIR..."
    mkdir -p "$DIR"
  fi

  if [ -f "$FILE" ]; then
    # Check if file is empty
    if [ ! -s "$FILE" ]; then
      echo "⚠️  ファイル $FILE は空です。初期設定で上書きします。"
      echo "$PAYLOAD" | jq . > "$FILE"
      continue
    fi

    echo "📋 $FILE を処理中..."
    TMP=""
    FILE_TMP=""

    # If file ends with .jsonc, use JSONC-aware merge first
    if [[ "$FILE" == *.jsonc ]]; then
      if merge_jsonc_preserving_comments "$FILE" "$TARGET_KEY" "$DOCKER_PAYLOAD"; then
        echo "✅ 更新しました: $FILE (JSONCコメントを保持)"
        continue
      fi

      echo "⚠️  警告: JSONCコメント保持マージに失敗しました。"
      echo "⚠️  Warning: converting .jsonc will remove comments; use --allow-jsonc-overwrite to proceed"

      if [[ "$ALLOW_JSONC_OVERWRITE" != "1" ]]; then
        echo "❌ エラー: $FILE は未変更です。"
        exit 1
      fi

      echo "⚠️  --allow-jsonc-overwrite が指定されたため、コメントを削除して上書きします。"
      TMP=$(mktemp)
      FILE_TMP="$FILE.tmp"

      if ! npx -y strip-json-comments-cli "$FILE" > "$TMP"; then
        echo "❌ エラー: JSONCファイル $FILE のパースに失敗しました (strip-json-comments-cli)"
        exit 1
      fi

      if [ ! -s "$TMP" ]; then
        echo "❌ エラー: JSONC変換後のファイルが空です"
        exit 1
      fi

      if jq --argjson p "$PAYLOAD" '. * $p' "$TMP" > "$FILE_TMP"; then
        mv "$FILE_TMP" "$FILE"
        FILE_TMP=""
      else
        echo "❌ エラー: jq マージに失敗しました: $FILE"
        exit 1
      fi
    else
      # Standard JSON
      # Validate JSON first
      FILE_TMP="$FILE.tmp"
      if jq . "$FILE" >/dev/null 2>&1; then
        if jq --argjson p "$PAYLOAD" '. * $p' "$FILE" > "$FILE_TMP"; then
          mv "$FILE_TMP" "$FILE"
          FILE_TMP=""
        else
          echo "❌ エラー: jq マージに失敗しました: $FILE"
          exit 1
        fi
      else
        echo "⚠️  警告: $FILE は有効なJSONではありません。スキップします。"
        continue
      fi
    fi

    echo "✅ 更新しました: $FILE"
  else
    echo "✅ 作成しました: $FILE"
    echo "$PAYLOAD" | jq . > "$FILE"
  fi
done

echo "✅ Docker MCP設定の注入が完了しました。"
