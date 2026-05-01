#!/bin/bash

clear
echo "🚀 NOC MULTI DOMAIN SETUP"

read -p "Cloudflare API Token: " CF_TOKEN
read -p "Zone ID: " ZONE_ID
read -p "Telegram Bot Token: " BOT_TOKEN
read -p "Telegram Chat ID: " CHAT_ID
read -p "Root Domain: " ROOT_DOMAIN

cat > /etc/noc.env <<EOF
CF_TOKEN=$CF_TOKEN
ZONE_ID=$ZONE_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
ROOT_DOMAIN=$ROOT_DOMAIN
EOF

chmod 600 /etc/noc.env

apt update -y
apt install curl dnsutils netcat -y

mkdir -p /root/noc/state

echo "✅ Setup selesai"
echo "➡️ Edit domain di: /root/noc/domains.conf"