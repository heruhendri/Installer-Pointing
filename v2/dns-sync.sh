#!/bin/bash

source /etc/noc.env
CONFIG="/root/noc/domains.conf"

IP=$(curl -s https://api.ipify.org)

cf_upsert() {
  DOMAIN=$1
  SUB=$(echo $DOMAIN | cut -d'.' -f1)

  RES=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN" \
    -H "Authorization: Bearer $CF_TOKEN")

  ID=$(echo $RES | grep -o '"id":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')

  if [[ -n "$ID" ]]; then
    curl -s -X PATCH \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$ID" \
      -H "Authorization: Bearer $CF_TOKEN" \
      --data "{\"type\":\"A\",\"name\":\"$SUB\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}" > /dev/null
  else
    curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "Authorization: Bearer $CF_TOKEN" \
      --data "{\"type\":\"A\",\"name\":\"$SUB\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}" > /dev/null
  fi
}

while IFS='|' read -r DOMAIN PORT
do
  [[ "$DOMAIN" =~ ^#.*$ || -z "$DOMAIN" ]] && continue
  cf_upsert "$DOMAIN"
done < $CONFIG