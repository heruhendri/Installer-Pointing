#!/bin/bash

clear
echo "🚀 AUTO POINTING + CLOUDFLARE + SSL"
echo "======================================"

# ======================================
# 📦 MUAT KONFIGURASI DARI BERKAS
# Otomatis dibuat oleh GitHub Actions / Manual
# ======================================
CONFIG_FILE="config.env"

# Cek apakah berkas konfigurasi ada
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "❌ KESALAHAN: Berkas konfigurasi '$CONFIG_FILE' tidak ditemukan!"
    echo ""
    echo "👉 Jika dijalankan LOKAL/SERVER: Buat berkas config.env dengan isi:"
    echo "CF_TOKEN=token_anda"
    echo "ZONE_ID=zone_id_anda"
    echo "ROOT_DOMAIN=domainanda.web.id"
    echo "BOT_TOKEN=bot_telegram"
    echo "CHAT_ID=chat_id_telegram"
    echo ""
    echo "👉 Jika dijalankan di GITHUB: Pastikan Secrets & Workflow sudah benar."
    exit 1
fi

# Membaca dan memuat semua variabel dari berkas konfigurasi
echo "🔓 Memuat konfigurasi rahasia..."
export $(grep -v '^#' $CONFIG_FILE | xargs)

# Validasi variabel wajib terisi
REQUIRED_VARS=("CF_TOKEN" "ZONE_ID" "ROOT_DOMAIN" "BOT_TOKEN" "CHAT_ID")
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "❌ KESALAHAN: Variabel $VAR kosong atau tidak ditemukan di $CONFIG_FILE"
        exit 1
    fi
done

# Variabel Tetap
API="https://api.cloudflare.com/client/v4"

# ======================================
# 🔒 CEK HAK AKSES ROOT
# ======================================
if [[ $EUID -ne 0 ]]; then
   echo "❌ KESALAHAN: Skrip ini harus dijalankan sebagai pengguna ROOT"
   echo "   Gunakan perintah: sudo bash install.sh"
   exit 1
fi

# ======================================
# 📥 INPUT PENGGUNA
# ======================================
echo ""
read -p "📝 Masukkan nama subdomain (contoh: panel, billing, api): " SUB

if [ -z "$SUB" ]; then
    echo "❌ Subdomain tidak boleh kosong!"
    exit 1
fi

echo ""
echo "📌 Pilih mode arahkan:"
echo "   1) Port  (Contoh: Arahkan ke aplikasi di 127.0.0.1:3000)"
echo "   2) Folder (Contoh: Arahkan ke berkas di /var/www/nama_folder)"
read -p "Pilihan Anda (1/2): " MODE

if [[ "$MODE" == "1" ]]; then
  read -p "🔌 Masukkan nomor port: " PORT
  if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then echo "❌ Port harus berupa angka!"; exit 1; fi
elif [[ "$MODE" == "2" ]]; then
  read -p "📁 Masukkan path lengkap folder (contoh: /var/www/html): " FOLDER
  if [ -z "$FOLDER" ]; then echo "❌ Path folder tidak boleh kosong!"; exit 1; fi
else
  echo "❌ Pilihan mode tidak valid. Harap pilih 1 atau 2."
  exit 1
fi

DOMAIN="$SUB.$ROOT_DOMAIN"
echo ""
echo "🌐 Target Domain: $DOMAIN"

# ======================================
# 🌐 DETEKSI IP PUBLIK
# ======================================
echo "🔍 Mendeteksi IP Publik Server..."

IP=$(curl -s -m 10 https://api.ipify.org | tr -d ' \n')
# Cadangan jika api.ipify.org gagal
if [[ -z "$IP" ]]; then
    IP=$(curl -s -m 10 https://ifconfig.me/ip | tr -d ' \n')
fi

if [[ -z "$IP" ]]; then
  echo "❌ Gagal mendapatkan IP Publik. Cek koneksi internet server Anda."
  exit 1
fi

echo "✅ IP Publik: $IP"

# ======================================
# 📢 FUNGSI KIRIM NOTIFIKASI TELEGRAM
# ======================================
send_telegram() {
curl -s -X POST \
"https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d chat_id="$CHAT_ID" \
-d parse_mode="Markdown" \
-d text="$1" > /dev/null
}

send_telegram "🚀 *MULAI INSTALASI*
Domain: \`$DOMAIN\`
IP: \`$IP\`
Status: Sedang diproses..."

# ======================================
# 📦 INSTALASI PAKET PENDUKUNG
# ======================================
echo ""
echo "📦 Menginstal paket yang dibutuhkan..."

apt update -y -qq
apt install -y -qq nginx certbot python3-certbot-nginx curl openssl

if [[ $? -ne 0 ]]; then
    echo "❌ Gagal menginstal paket. Cek koneksi atau repositori server."
    send_telegram "❌ *GAGAL INSTALASI*: Gagal menginstal paket pendukung."
    exit 1
fi

# ======================================
# ☁️ PENGATURAN DNS CLOUDFLARE
# ======================================
echo ""
echo "☁️ Menyinkronkan DNS ke Cloudflare..."

# Cek apakah catatan DNS sudah ada
GET_RES=$(curl -s -X GET \
"$API/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" \
-H "Authorization: Bearer $CF_TOKEN" \
-H "Content-Type: application/json")

# Ambil ID catatan jika ada
RECORD_ID=$(echo "$GET_RES" | grep -o '"id":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')

if [[ -n "$RECORD_ID" ]]; then
  # PERBARUI DNS YANG SUDAH ADA
  echo "♻️ Memperbarui catatan DNS yang sudah ada..."
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
  # BUAT DNS BARU
  echo "🆕 Membuat catatan DNS baru..."
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

# Cek respon Cloudflare
if echo "$RESULT" | grep -q '"success":true'; then
    echo "✅ DNS Cloudflare berhasil diatur."
    send_telegram "☁️ *DNS BERHASIL*
\`$DOMAIN\` ➡️ \`$IP\`
(Proxied: Non-Aktif)"
else
    echo "❌ Gagal mengatur DNS Cloudflare! Respon: $RESULT"
    send_telegram "❌ *DNS GAGAL*: $DOMAIN"
    exit 1
fi

# ======================================
# ⚙️ KONFIGURASI NGINX
# ======================================
echo ""
echo "⚙️ Membuat konfigurasi Nginx..."

CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"

# Buat konfigurasi sesuai MODE yang dipilih
if [[ "$MODE" == "1" ]]; then
# MODE PORT (Reverse Proxy)
cat > $CONFIG_PATH <<EOF
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
        
        # Peningkatan keamanan & koneksi
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 60s;
        proxy_read_timeout 600s;
    }
}
EOF

else
# MODE FOLDER (Layanan Berkas)
cat > $CONFIG_PATH <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $FOLDER;
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Izinkan akses ke berkas PHP jika ada
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
EOF

fi

# Aktifkan konfigurasi & bersihkan bawaan
ln -sf $CONFIG_PATH /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Cek kesalahan konfigurasi
nginx -t -q
if [[ $? -ne 0 ]]; then
  echo "❌ KESALAHAN: Konfigurasi Nginx tidak valid!"
  send_telegram "❌ *NGINX GAGAL*: Konfigurasi bermasalah."
  exit 1
fi

# Mulai ulang layanan
systemctl restart nginx
echo "✅ Konfigurasi Nginx aktif."

send_telegram "✅ *NGINX SIAP*
Domain: $DOMAIN
Mode: $( [[ "$MODE" == "1" ]] && echo "Port ($PORT)" || echo "Folder ($FOLDER)" )"

# ======================================
# 🔒 PEMASANGAN SSL LET'S ENCRYPT
# ======================================
echo ""
echo "🔒 Memasang Sertifikat SSL (HTTPS)..."

certbot --nginx \
-d $DOMAIN \
--non-interactive \
--agree-tos \
-m "admin@$ROOT_DOMAIN" \
--redirect \
--keep-until-expiring > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo "✅ SSL Berhasil dipasang & HTTP diarahkan ke HTTPS."
  send_telegram "🔒 *SSL AKTIF*
✅ https://$DOMAIN"
else
  echo "⚠️ Peringatan: Gagal mendapatkan sertifikat SSL. Cek apakah domain sudah mengarah ke server atau kuota Let's Encrypt habis."
  send_telegram "⚠️ *SSL GAGAL*: $DOMAIN (HTTP saja)"
fi

# ======================================
# 🎉 SELESAI
# ======================================
echo ""
echo "======================================"
echo "🎉 INSTALASI SELESAI 100%"
echo "🌐 Alamat: https://$DOMAIN"
echo "======================================"

send_telegram "🎉 *INSTALASI SELESAI*
✅ Domain: https://$DOMAIN
✅ Status: Berhasil diinstal & dikonfigurasi"

exit 0