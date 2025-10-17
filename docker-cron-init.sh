#!/bin/bash
set -e

# /app/cron_ai_batchからユーザー名部分だけ削除してappuserのcrontabに登録
sed 's/^\([^#]*\) appuser /\1 /' /app/cron_ai_batch | crontab -u appuser -

# cronをフォアグラウンドで起動
exec cron -f
