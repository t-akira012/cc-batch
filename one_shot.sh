#!/bin/bash
set -euo pipefail

. .env
URL=$ONE_SHOT_GIST_URL

# --- 設定 ---
TMP_DIR="${HOME}/.tmp"
mkdir -p "$TMP_DIR"
TMP_TXT="$TMP_DIR/oneshot.txt"
TMP_HASH="$TMP_DIR/oneshot.hash"

# --- ハッシュ監視 10秒おき、5回 ---
for _ in {1..5}; do
  echo "[one_shot] fetching $URL"
  curl -sS "${URL}?t=$(date +%s)" -o "$TMP_TXT"
  HASH=$(sha256sum "$TMP_TXT" | awk '{print $1}')
  PREV=$(cat "$TMP_HASH" 2>/dev/null || true)
  if [ "$HASH" != "$PREV" ]; then
    echo "[one_shot] change detected, executing batch"
    echo "$HASH" > "$TMP_HASH"
    /app/exec_gist_batch.sh "$URL"
  else
    echo "[one_shot] no change"
  fi
  sleep 10
done
