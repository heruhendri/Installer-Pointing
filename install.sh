#!/bin/bash

clear
echo "🚀 AUTO POINTING + CLOUDFLARE + SSL"

# =========================
# 🔐 CONFIG
# =========================
CF_TOKEN="ISI_TOKEN_CLOUDFLARE"
ZONE_ID="ISI_ZONE_ID"
ROOT_DOMAIN="hdri.web.id"

BOT_TOKEN="ISI_BOT_TOKEN"
CHAT_ID="ISI_CHAT_ID"

API="https://api.cloudflare.com/client/v4"

# =========================
# CEK ROOT
# =========================
if [[ $EUID -ne 0 ]]; then
   echo "❌ Jalankan sebagai root"
   exit 1
fi

# =========================
# INPUT USER
# =========================
read -p "Masukkan subdomain (contoh: acs): " SUB

echo ""
echo "Pilih mode:"
echo "1) Port"
echo "2) Folder"
read -p "Pilih (1/2): " MODE

if [[ "$MODE" == "1" ]]; then
  read -p "Masukkan port aplikasi: " PORT
elif [[ "$MODE" == "2" ]]; then
  read -p "Masukkan path folder: " FOLDER
else
  echo "❌ Mode salah"
  exit 1
fi

DOMAIN="$SUB.$ROOT_DOMAIN"

# =========================
# DETECT PUBLIC IP
# =========================
echo ""
echo "🌐 Detecting IP..."

IP=$(curl -s https://api.ipify.org | tr -d ' \n')

if [[ -z "$IP" ]]; then
  echo "❌ Gagal detect IP"
  exit 1
fi

echo "✅ IP VPS: $IP"

# =========================
# TELEGRAM FUNCTION
# =========================
send_telegram() {
curl -s -X POST \
"https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d chat_id="$CHAT_ID" \
-d text="$1" > /dev/null
}

send_telegram "🚀 INSTALL START

Domain: $DOMAIN
IP: $IP"

# =========================
# INSTALL DEPENDENCY
# =========================
echo ""
echo "📦 Install dependency..."

apt update -y
apt install nginx certbot python3-certbot-nginx curl -y

# =========================
# CLOUDFLARE DNS
# =========================
echo ""
echo "☁️ Sync DNS Cloudflare..."

GET_RES=$(curl -s -X GET \
"$API/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" \
-H "Authorization: Bearer $CF_TOKEN" \
-H "Content-Type: application/json")

RECORD_ID=$(echo "$GET_RES" | grep -o '"id":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')

if [[ -n "$RECORD_ID" ]]; then

  echo "♻️ Update existing DNS..."

  RESULT=$(curl -s -X PATCH \
  "$API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\":\"A\",
    \"name\":\"$DOMAIN\",
    \"content\":\"$IP\",
    \"ttl\":120,
    \"proxied\":false
  }")

else

  echo "🆕 Create new DNS..."

  RESULT=$(curl -s -X POST \
  "$API/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\":\"A\",
    \"name\":\"$DOMAIN\",
    \"content\":\"$IP\",
    \"ttl\":120,
    \"proxied\":false
  }")

fi

echo "$RESULT"

send_telegram "☁️ DNS READY

$DOMAIN → $IP"

# =========================
# NGINX CONFIG
# =========================
echo ""
echo "⚙️ Setup NGINX..."

CONFIG="/etc/nginx/sites-available/$DOMAIN"

if [[ "$MODE" == "1" ]]; then

cat > $CONFIG <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;

        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

fi

ln -sf $CONFIG /etc/nginx/sites-enabled/

rm -f /etc/nginx/sites-enabled/default

nginx -t

if [[ $? -ne 0 ]]; then
  echo "❌ Config nginx error"
  exit 1
fi

systemctl restart nginx

send_telegram "✅ NGINX READY

$DOMAIN"

# =========================
# SSL LETSENCRYPT
# =========================
echo ""
echo "🔒 Setup SSL..."

certbot --nginx \
-d $DOMAIN \
--non-interactive \
--agree-tos \
-m admin@$ROOT_DOMAIN \
--redirect

if [[ $? -eq 0 ]]; then

  echo "✅ SSL SUCCESS"

  send_telegram "🔒 SSL SUCCESS

https://$DOMAIN"

else

  echo "❌ SSL FAILED"

  send_telegram "❌ SSL FAILED

$DOMAIN"

fi

# =========================
# FINAL
# =========================
echo ""
echo "🎉 INSTALL SELESAI"
echo "🌐 https://$DOMAIN"

send_telegram "🎉 INSTALL SUCCESS

https://$DOMAIN"