#!/bin/bash

source /etc/noc.env

CONFIG="/root/noc/domains.conf"
STATE_DIR="/root/noc/state"

send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$1" > /dev/null
}

check_domain() {
  DOMAIN=$1
  PORT=$2
  STATE_FILE="$STATE_DIR/$DOMAIN"

  for i in {1..3}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
    [[ "$STATUS" =~ ^2|3 ]] && break
    sleep 2
  done

  if [[ "$STATUS" =~ ^2|3 ]]; then
    NEW="UP"
  else
    NEW="DOWN"
  fi

  OLD=$(cat $STATE_FILE 2>/dev/null)

  if [[ "$NEW" != "$OLD" ]]; then
    if [[ "$NEW" == "DOWN" ]]; then
      send_telegram "🚨 DOWN
$DOMAIN
HTTP: $STATUS
Port: $PORT"
    else
      send_telegram "✅ RECOVERED
$DOMAIN"
    fi
    echo "$NEW" > $STATE_FILE
  fi
}

while IFS='|' read -r DOMAIN PORT
do
  [[ "$DOMAIN" =~ ^#.*$ || -z "$DOMAIN" ]] && continue
  check_domain "$DOMAIN" "$PORT"
done < $CONFIG