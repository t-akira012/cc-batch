FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        cron \
        tzdata \
        nodejs \
        npm && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

CMD ["cron", "-f"]
