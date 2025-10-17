# Claude Code 自動実行システム

このリポジトリは、GitHub Gist を制御ハブとして Claude Code をワンショット実行し、結果を Resend 経由で通知する stateless な自動実行パイプラインを提供します。AI はタスクごとに起動・終了し、常駐プロセスや複雑な状態管理を不要とします。

## 構成要素

- `one_shot.sh`  
  `.env` の `ONE_SHOT_GIST_URL` を 10 秒間隔×5 回監視し、ハッシュが変わった場合にだけ `exec_gist_batch.sh` を起動するワンショット監視スクリプト。

- `daily_cron_sync.sh`  
  `.env` の `SYNC_DAILY_CRON_GIST_URL` からバッチ URL リストを取得し、許可された Gist Raw URL だけで 8:00 実行の crontab を再生成。入力検証でシェル注入を遮断。

- `exec_gist_batch.sh`  
  指定 Gist を取得 → `USE_GEMINI=true` なら Gemini CLI、そうでなければ Claude CLI (`claude --print`) で実行 → 1 行目を件名、残りを本文として Resend API に送信。`.env` から送信先などの認証情報を読み込み、一時ファイルを削除します。

- `.env.template`  
  Gist URL や Resend API キーに加え、`USE_GEMINI`（true で Gemini CLI を使用）と `GEMINI_API_KEY` を含む環境変数の雛形。

- `Dockerfile`  
  ベースに `ubuntu:24.04` を採用。`curl`, `jq`, `cron`, `ca-certificates`, `tzdata` に加えて NodeSource 経由で Node.js 20 系を導入し、Gemini CLI が必要とする API を提供。CA ストアを `update-ca-certificates` で再構築し、Claude / Gemini CLI をグローバルインストール。JST 設定と `cron -f` をエントリポイントとしています。

- `compose.yaml`  
  `ai-batch` サービスを定義し、ホストのプロジェクト一式を `/app` にバインド。`.env` を読み込み、`unless-stopped` リスタートポリシーで稼働させます。`cron_ai_batch` を `/etc/cron.d/ai-batch` として読み込ませ、コンテナ再ビルドなしでジョブ定義を編集可能です。

- `Makefile`  
  `make up/down/build/logs/restart/dev` など Docker Compose のラッパーを提供。`make run` は `make up` の糖衣構文です。

## 使い方

1. `.env.template` を参考に `.env` を用意し、Gist URL や Resend の認証情報を設定します。`USE_GEMINI` には必ず `true` または `false` を設定し、Gemini を利用する場合は `GEMINI_API_KEY` も指定します。
2. コンテナイメージをビルドします。
   ```sh
   make build
   ```
3. サービスを起動します。
   ```sh
   make up
   ```
4. 動作確認や保守は以下が目安です。
   - ログの追跡: `make logs`
   - コンテナ内シェル: `make dev`
   - 停止: `make down`

`cron_ai_batch` を編集すると、コンテナを再起動せずとも cron のスケジュールを柔軟に更新できます（`touch cron_ai_batch` でタイムスタンプを更新すると cron が再読込します）。ホスト側でスクリプトを変更した場合も、バインドマウントにより即時反映されます。Gist が更新されれば `one_shot.sh` が 10 秒間隔で検知し、毎朝 8 時には `daily_cron_sync.sh` が最新のバッチリストを取り込みます。

ホスト側でスクリプトを更新すると、`compose.yaml` のバインドマウントによりコンテナへ即時反映されます。Gist 側で思考指示を更新すると `one_shot.sh` や `daily_cron_sync.sh` が自動検知し、Claude Code のワンショット実行 → Resend 通知まで完結します。
