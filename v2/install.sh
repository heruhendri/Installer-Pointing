#!/bin/bash

clear
echo "🚀 AUTO POINTING + CLOUDFLARE + SSL (FIX VERSION)"

# =========================
# 🔐 CONFIG
# =========================
CF_TOKEN="ISI_TOKEN_BARU"
ZONE_ID="ISI_ZONE_ID"
ROOT_DOMAIN="hdri.web.id"

BOT_TOKEN="ISI_BOT_TOKEN_BARU"
CHAT_ID="ISI_CHAT_ID"

API="https://api.cloudflare.com/client/v4"

# =========================
# INPUT USER
# =========================
read -p "Masukkan subdomain (contoh: acs): " SUB

echo "Pilih mode:"
echo "1) Port"
echo "2) Folder"
read -p "Pilih (1/2): " MODE

if [[ "$MODE" == "1" ]]; then
  read -p "Masukkan port: " PORT
elif [[ "$MODE" == "2" ]]; then
  read -p "Masukkan path folder: " FOLDER
else
  echo "❌ Mode salah"
  exit 1
fi

DOMAIN="$SUB.$ROOT_DOMAIN"

# =========================
# DETECT IP
# =========================
IP=$(curl -s https://api.ipify.org | tr -d ' \n')

if [[ -z "$IP" ]]; then
  echo "❌ Gagal detect IP"
  exit 1
fi

echo "🌐 IP: $IP"

# =========================
# TELEGRAM
# =========================
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$1" > /dev/null
}

send_telegram "🚀 INSTALL START
Domain: $DOMAIN
IP: $IP"

# =========================
# INSTALL DEPENDENCY
# =========================
apt update -y
apt install nginx certbot python3-certbot-nginx curl -y

# =========================
# DNS CLOUDFLARE (UPSERT + DEBUG)
# =========================
echo "☁️ Sync DNS..."

GET_RES=$(curl -s -X GET \
"$API/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" \
-H "Authorization: Bearer $CF_TOKEN" \
-H "Content-Type: application/json")

echo "DEBUG GET:"
echo "$GET_RES"

RECORD_ID=$(echo "$GET_RES" | grep -o '"id":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')

if [[ -n "$RECORD_ID" ]]; then
  echo "♻️ Update DNS"

  UPDATE_RES=$(curl -s -X PATCH \
  "$API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}")

  echo "$UPDATE_RES"
else
  echo "🆕 Create DNS"

  CREATE_RES=$(curl -s -X POST \
  "$API/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}")

  echo "$CREATE_RES"
fi

send_telegram "☁️ DNS SYNC DONE
$DOMAIN → $IP"

# =========================
# NGINX CONFIG
# =========================
CONFIG="/etc/nginx/sites-available/$DOMAIN"

if [[ "$MODE" == "1" ]]; then
cat > $CONFIG <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
else
cat > $CONFIG <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $FOLDER;
    index index.html index.php;
}
EOF
fi

ln -sf $CONFIG /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

send_telegram "✅ NGINX READY
$DOMAIN"

# =========================
# SSL
# =========================
echo "🔒 Setup SSL..."

certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$ROOT_DOMAIN --redirect

if [[ $? -eq 0 ]]; then
  send_telegram "🔒 SSL SUCCESS
https://$DOMAIN"
else
  send_telegram "❌ SSL FAILED
$DOMAIN"
fi

# =========================
# DONE
# =========================
echo "🎉 DONE: https://$DOMAIN"

send_telegram "🎉 INSTALL SUCCESS
https://$DOMAIN"