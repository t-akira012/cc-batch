#!/bin/bash
set -euo pipefail

# --- 引数 ---
URL="$1"
ENV_FILE="/app/.env"

# --- 一時ファイル作成 ---
TMP_INPUT=$(mktemp /tmp/gist_prompt.XXXXXX.txt)

# --- Gist取得 ---
curl -sS "$URL" -o "$TMP_INPUT"

# --- Claude実行 ---
OUTPUT=$(claude --print "$TMP_INPUT")

# --- 出力整形 ---
TITLE=$(echo "$OUTPUT" | head -n1)
BODY=$(echo "$OUTPUT" | tail -n +2)

# --- メール送信 ---
source "$ENV_FILE"
curl -sX POST "https://api.resend.com/emails" \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg from "$FROM_EMAIL" --arg to "$SEND_EMAIL" \
               --arg subject "$TITLE" --arg text "$BODY" \
               '{from:$from, to:$to, subject:$subject, text:$text}')"

rm -f "$TMP_INPUT"
