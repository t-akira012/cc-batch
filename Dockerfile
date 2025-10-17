FROM public.ecr.aws/ubuntu/ubuntu:latest

ENV TZ=Asia/Tokyo \
    DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

WORKDIR /app

RUN <<EOF
    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        jq \
        cron \
        tzdata \
        nodejs \
        npm
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    # CA証明書更新
    update-ca-certificates

    # JST設定
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone

    # AI Agents インストール
    npm install -g @anthropic-ai/claude-code @google/gemini-cli

    # 非rootユーザーを作成
    useradd -m -s /bin/bash appuser
    echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF

# crontab読み込み用スクリプト
COPY docker-cron-init.sh /docker-cron-init.sh
RUN chmod +x /docker-cron-init.sh

CMD ["/docker-cron-init.sh"]
