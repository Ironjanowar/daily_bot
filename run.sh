#!/usr/bin/env bash

LOGS="./logs/output.log"

echo "Logs will be saved in: $LOGS"

echo "Running..."

echo -e "\n\nLOG [$(date)]\n" >>$LOGS
mix run --no-halt >> $LOGS
