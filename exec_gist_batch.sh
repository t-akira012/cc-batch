#!/bin/bash
set -euo pipefail
set -x

# --- 引数 ---
URL="$1"
ENV_FILE="/app/.env"

# --- 環境変数読込（直接起動時のフォールバック） ---
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

# --- Gist取得 ---
echo "[exec_gist_batch] fetching $URL"
TMP_INPUT=$(curl -sS "${URL}?t=$(date +%s)")

# --- エージェント追記 ---
AGENTS_NOTE="/app/AGENTS.md"
if [ -f "$AGENTS_NOTE" ]; then
  TMP_INPUT="${TMP_INPUT}"$'\n\n'"$(cat "$AGENTS_NOTE")"
fi

# --- 実行エンジン ---
set +e
echo "[exec_gist_batch] Running Claude with input length: ${#TMP_INPUT} chars"
CLAUDE_OUTPUT=$(printf '%s' "$TMP_INPUT" | claude --print \
  --permission-mode bypassPermissions \
  --verbose \
  2>&1)
CLAUDE_STATUS=$?
echo "[exec_gist_batch] Claude exit status: $CLAUDE_STATUS"
set -e

if [ "$CLAUDE_STATUS" -eq 0 ]; then
  OUTPUT="$CLAUDE_OUTPUT"
else
  if [ "$USE_GEMINI" = "true" ]; then
    echo "[exec_gist_batch] Claude failed (status $CLAUDE_STATUS), falling back to Gemini"
    OUTPUT=$(printf '%s' "$TMP_INPUT" | gemini prompt)
  else
    echo "$CLAUDE_OUTPUT" >&2
    exit "$CLAUDE_STATUS"
  fi
fi

# --- 出力整形 ---
TITLE=$(echo "$OUTPUT" | head -n1)
BODY=$(echo "$OUTPUT" | tail -n +2)
if [ -z "$BODY" ]; then
  BODY="(no additional content)"
fi

# --- メール送信 ---
curl -sX POST "https://api.resend.com/emails" \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg from "$FROM_EMAIL" --arg to "$SEND_EMAIL" \
               --arg subject "$TITLE" --arg text "$BODY" \
               '{from:$from, to:$to, subject:$subject, text:$text}')"
