#!/bin/bash

clear
echo "🚀 INSTALLER PORT → HTTPS + CLOUDFLARE + TELEGRAM"

# =========================
# INPUT USER
# =========================
read -p "Masukkan domain utama (contoh: hendri.site): " ROOT_DOMAIN
read -p "Masukkan subdomain (contoh: acs): " SUB
read -p "Masukkan port lokal (contoh: 7547): " PORT
read -p "Cloudflare API Token: " CF_TOKEN
read -p "Cloudflare Zone ID: " ZONE_ID
read -p "IP VPS Publik: " VPS_IP

read -p "Telegram Bot Token: " BOT_TOKEN
read -p "Telegram Chat ID: " CHAT_ID

DOMAIN="$SUB.$ROOT_DOMAIN"

# =========================
# FUNCTION TELEGRAM
# =========================
send_telegram() {
  TEXT="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$TEXT" > /dev/null
}

send_telegram "🚀 INSTALL STARTED
Domain: $DOMAIN
Port: $PORT
IP: $VPS_IP"

# =========================
# INSTALL DEPENDENCY
# =========================
echo "📦 Install dependency..."
apt update -y
apt install nginx certbot python3-certbot-nginx curl -y

# =========================
# CREATE DNS CLOUDFLARE
# =========================
echo "☁️ Create DNS Cloudflare..."

CREATE_DNS=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
 -H "Authorization: Bearer $CF_TOKEN" \
 -H "Content-Type: application/json" \
 --data "{\"type\":\"A\",\"name\":\"$SUB\",\"content\":\"$VPS_IP\",\"ttl\":120,\"proxied\":false}")

if echo "$CREATE_DNS" | grep -q '"success":true'; then
  echo "✅ DNS berhasil dibuat"
  send_telegram "✅ DNS CREATED: $DOMAIN → $VPS_IP"
else
  echo "❌ Gagal create DNS"
  send_telegram "❌ DNS FAILED: $DOMAIN"
fi

# =========================
# WAIT DNS PROPAGATION
# =========================
echo "⏳ Tunggu DNS propagation (10 detik)..."
sleep 10

# =========================
# NGINX CONFIG
# =========================
CONFIG="/etc/nginx/sites-available/$DOMAIN"

echo "⚙️ Setup Nginx..."

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

nginx -t
systemctl restart nginx

send_telegram "✅ NGINX CONFIGURED: $DOMAIN"

# =========================
# SSL SETUP
# =========================
echo "🔒 Setup SSL..."

certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$ROOT_DOMAIN --redirect

if [ $? -eq 0 ]; then
  echo "✅ SSL berhasil"
  send_telegram "🔒 SSL SUCCESS: https://$DOMAIN"
else
  echo "❌ SSL gagal"
  send_telegram "❌ SSL FAILED: $DOMAIN"
fi

# =========================
# FIREWALL
# =========================
ufw allow 'Nginx Full' || true

# =========================
# DONE
# =========================
echo ""
echo "🎉 INSTALL SELESAI!"
echo "🌐 https://$DOMAIN → http://127.0.0.1:$PORT"

send_telegram "🎉 INSTALL DONE

🌐 https://$DOMAIN
➡️ Port: $PORT
🖥 IP: $VPS_IP"