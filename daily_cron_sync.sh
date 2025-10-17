#!/bin/bash
set -euo pipefail

. .env

RUN_SCRIPT="/app/exec_gist_batch.sh"
GIST_URL=$SYNC_DAILY_CRON_GIST_URL

TMP_LIST=$(mktemp /tmp/batch_list.XXXXXX.txt)
echo "[daily_cron_sync] fetching $GIST_URL"
curl -sS "${GIST_URL}?t=$(date +%s)" -o "$TMP_LIST"

{
  while IFS= read -r line || [ -n "$line" ]; do
    # 前後空白除去
    line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac

    # 半角スペース以降は破棄
    url="${line%% *}"

    # gist raw URL 以外は拒否
    case "$url" in
      https://gist.githubusercontent.com/*/raw/*)
        # 毎日07:30(JST)に実行
        echo "30 07 * * * /bin/bash -lc '$RUN_SCRIPT \"$url\"'"
        ;;
      *)
        continue
        ;;
    esac
  done < "$TMP_LIST"
} | crontab -

rm -f "$TMP_LIST"
