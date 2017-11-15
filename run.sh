#!/usr/bin/env bash

if [ ! -e "bot.token" ]; then
    echo "ERROR: bot.token does not exist"
    exit 1
fi

export DAILY_BOT_TOKEN=$(cat bot.token)

LOGS="./logs/output.log"
echo "Logs will be saved in: $LOGS"

echo "Getting deps"
mix deps.get

echo "Compiling..."
mix compile

echo "Running..."

echo -e "\n\nLOG [$(date)]\n" >>$LOGS
mix run --no-halt >> $LOGS
