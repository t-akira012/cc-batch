#!/bin/bash
set -euo pipefail

[[ ! -f .env ]] && echo ".env require" && exit 1

. .env
GIST_URL=$ONE_SHOT_GIST_URL

# --- 設定 ---
TMP_TXT="/tmp/oneshot.txt"
TMP_HASH="/tmp/oneshot.hash"


# ハッシュ監視 10秒おき、5回
for i in {1..5}; do
  curl -sS "$GIST_URL" -o "$TMP_TXT"
  NEW_HASH=$(sha256sum "$TMP_TXT" | awk '{print $1}')
  OLD_HASH=$(cat "$TMP_HASH" 2>/dev/null || echo "")
  if [ "$NEW_HASH" != "$OLD_HASH" ]; then
    echo "$NEW_HASH" > "$TMP_HASH"
    /app/exec_gist_batch.sh "$GIST_URL"
  fi
  sleep 10
done
