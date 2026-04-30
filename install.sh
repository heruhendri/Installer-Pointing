#!/bin/bash

clear
echo "🚀 INSTALLER PORT → HTTPS DOMAIN (NAT VPS)"

# =========================
# INPUT USER
# =========================
read -p "Masukkan domain (contoh: contoh.hendri.site): " DOMAIN
read -p "Masukkan port lokal (contoh: 7547): " PORT
read -p "Gunakan SSL Let's Encrypt? (y/n): " SSL

# =========================
# VALIDASI
# =========================
if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
  echo "❌ Domain dan port wajib diisi!"
  exit 1
fi

# =========================
# INSTALL DEPENDENCY
# =========================
echo "📦 Install Nginx & Certbot..."
apt update -y
apt install nginx certbot python3-certbot-nginx -y

# =========================
# BUAT CONFIG NGINX
# =========================
CONFIG="/etc/nginx/sites-available/$DOMAIN"

echo "⚙️ Membuat config Nginx..."

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
        proxy_cache_bypass \$http_upgrade;

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# =========================
# ENABLE SITE
# =========================
ln -sf $CONFIG /etc/nginx/sites-enabled/

# =========================
# TEST & RESTART NGINX
# =========================
nginx -t
systemctl restart nginx

# =========================
# SSL SETUP
# =========================
if [[ "$SSL" == "y" ]]; then
  echo "🔒 Setup SSL Let's Encrypt..."
  certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN --redirect
fi

# =========================
# FIREWALL (OPTIONAL)
# =========================
ufw allow 'Nginx Full' || true

# =========================
# DONE
# =========================
echo ""
echo "✅ SELESAI!"
echo "🌐 Domain: https://$DOMAIN"
echo "📡 Forward ke: http://127.0.0.1:$PORT"
echo ""