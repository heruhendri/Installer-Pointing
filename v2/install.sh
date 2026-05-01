#!/bin/bash

clear
echo "🚀 AUTO POINTING + CLOUDFLARE + SSL"

# =========================
# 🔐 CONFIG (EDIT SEKALI SAJA)
# =========================
CF_TOKEN="ISI_CLOUDFLARE_TOKEN"
ZONE_ID="ISI_ZONE_ID"
ROOT_DOMAIN="hendri.site"

BOT_TOKEN="ISI_BOT_TOKEN"
CHAT_ID="ISI_CHAT_ID"

# =========================
# INPUT USER
# =========================
read -p "Masukkan subdomain (contoh: acs): " SUB

echo "Pilih mode:"
echo "1) Port (contoh: 7547)"
echo "2) Folder (contoh: /var/www/html)"
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
IP=$(curl -s https://api.ipify.org)

# =========================
# TELEGRAM
# =========================
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$1" > /dev/null
}

send_telegram "🚀 INSTALL START
$DOMAIN"

# =========================
# INSTALL DEPENDENCY
# =========================
apt update -y
apt install nginx certbot python3-certbot-nginx curl -y

# =========================
# DNS CLOUDFLARE (UPSERT)
# =========================
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

# =========================
# SSL
# =========================
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$ROOT_DOMAIN --redirect

# =========================
# DONE
# =========================
echo "🎉 DONE: https://$DOMAIN"

send_telegram "🎉 SUCCESS
https://$DOMAIN"up