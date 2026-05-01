#!/bin/bash

clear
echo "🚀 INSTALLER AUTO (NO CONFIG USER)"

# =========================
# 🔐 CONFIG (EDIT DI SINI SAJA)
# =========================
CF_TOKEN="ISI_CLOUDFLARE_API_TOKEN"
ZONE_ID="ISI_ZONE_ID"
VPS_IP="ISI_IP_VPS"

BOT_TOKEN="ISI_TELEGRAM_BOT_TOKEN"
CHAT_ID="ISI_CHAT_ID"

# =========================
# INPUT USER (MINIMAL)
# =========================
read -p "Masukkan domain utama (contoh: hendri.site): " ROOT_DOMAIN
read -p "Masukkan subdomain (contoh: acs): " SUB
read -p "Masukkan port lokal (contoh: 7547): " PORT

DOMAIN="$SUB.$ROOT_DOMAIN"

# =========================
# VALIDASI
# =========================
if [[ -z "$ROOT_DOMAIN" || -z "$SUB" || -z "$PORT" ]]; then
  echo "❌ Input tidak lengkap!"
  exit 1
fi

# =========================
# FUNCTION TELEGRAM
# =========================
send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$1" > /dev/null
}

send_telegram "🚀 INSTALL STARTED
Domain: $DOMAIN
Port: $PORT"

# =========================
# INSTALL DEPENDENCY
# =========================
echo "📦 Install dependency..."
apt update -y
apt install nginx certbot python3-certbot-nginx curl -y

# =========================
# CREATE DNS CLOUDFLARE
# =========================
echo "☁️ Create DNS..."

CREATE_DNS=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
 -H "Authorization: Bearer $CF_TOKEN" \
 -H "Content-Type: application/json" \
 --data "{\"type\":\"A\",\"name\":\"$SUB\",\"content\":\"$VPS_IP\",\"ttl\":120,\"proxied\":false}")

if echo "$CREATE_DNS" | grep -q '"success":true'; then
  echo "✅ DNS OK"
  send_telegram "✅ DNS CREATED: $DOMAIN"
else
  echo "❌ DNS FAIL"
  send_telegram "❌ DNS FAILED: $DOMAIN"
fi

sleep 10

# =========================
# NGINX CONFIG
# =========================
CONFIG="/etc/nginx/sites-available/$DOMAIN"

cat > $CONFIG <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf $CONFIG /etc/nginx/sites-enabled/

nginx -t && systemctl restart nginx

send_telegram "✅ NGINX OK: $DOMAIN"

# =========================
# SSL
# =========================
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$ROOT_DOMAIN --redirect

if [ $? -eq 0 ]; then
  send_telegram "🔒 SSL SUCCESS: https://$DOMAIN"
else
  send_telegram "❌ SSL FAILED: $DOMAIN"
fi

# =========================
# FIREWALL
# =========================
ufw allow 'Nginx Full' || true

# =========================
# DONE
# =========================
echo "🎉 SELESAI: https://$DOMAIN"

send_telegram "🎉 DONE
🌐 https://$DOMAIN
➡️ Port: $PORT"