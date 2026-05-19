#!/bin/bash

clear
echo "🚀 AUTO POINTING + CLOUDFLARE + SSL"
echo "======================================"

# ======================================
# 📦 LOKASI KONFIGURASI (DIPINDAH KE SISTEM)
# Supaya bisa dijalankan dari folder mana saja
# ======================================
CONFIG_FILE="/etc/cf/config.env"

# Cek apakah berkas konfigurasi ada
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "❌ KESALAHAN: Berkas konfigurasi '$CONFIG_FILE' tidak ditemukan!"
    echo ""
    echo "👉 Buat folder & berkas dengan perintah:"
    echo "   sudo mkdir -p /etc/cf"
    echo "   sudo nano /etc/cf/config.env"
    echo ""
    echo "👉 Isi dengan:"
    echo "CF_TOKEN=token_anda"
    echo "ZONE_ID=zone_id_anda"
    echo "ROOT_DOMAIN=domainanda.web.id"
    echo "BOT_TOKEN=bot_telegram"
    echo "CHAT_ID=chat_id_telegram"
    exit 1
fi

# Memuat konfigurasi
echo "🔓 Memuat konfigurasi rahasia..."
export $(grep -v '^#' $CONFIG_FILE | xargs)

# Validasi variabel
REQUIRED_VARS=("CF_TOKEN" "ZONE_ID" "ROOT_DOMAIN" "BOT_TOKEN" "CHAT_ID")
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "❌ KESALAHAN: Variabel $VAR kosong di $CONFIG_FILE"
        exit 1
    fi
done

# Variabel Tetap
API="https://api.cloudflare.com/client/v4"

# ======================================
# 🔒 CEK & MINTA HAK AKSES OTOMATIS
# ======================================
if [[ $EUID -ne 0 ]]; then
    echo "⚠️ Membutuhkan hak akses administratif..."
    # Jalankan ulang skrip ini dengan sudo secara otomatis
    exec sudo "$0" "$@"
    exit $?
fi

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

# ======================================
# 🌐 FUNGSI DETEKSI IP PUBLIK
# ======================================
detect_ip() {
    echo "🔍 Mendeteksi IP Publik Server..."
    IP=$(curl -s -m 10 https://api.ipify.org | tr -d ' \n')
    [[ -z "$IP" ]] && IP=$(curl -s -m 10 https://ifconfig.me/ip | tr -d ' \n')
    if [[ -z "$IP" ]]; then echo "❌ Gagal mendapatkan IP!"; exit 1; fi
    echo "✅ IP Publik: $IP"
}

# ======================================
# ⚙️ FUNGSI TAMBAH / EDIT KONFIGURASI
# ======================================
install_config() {
    clear
    echo "⚙️ TAMBAH / UBAH KONFIGURASI"
    echo "============================"

    echo ""
    read -p "📝 Masukkan nama subdomain (contoh: panel, billing): " SUB
    [[ -z "$SUB" ]] && { echo "❌ Tidak boleh kosong!"; return; }

    echo ""
    echo "📌 Pilih mode arahkan:"
    echo "   1) Port  (http://127.0.0.1:3000)"
    echo "   2) Folder (/var/www/nama_folderstandar)"
    read -p "Pilihan Anda (1/2): " MODE

    if [[ "$MODE" == "1" ]]; then
      read -p "🔌 Masukkan nomor port: " PORT
      if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then echo "❌ Port harus angka!"; return; fi
    elif [[ "$MODE" == "2" ]]; then
      read -p "📁 Masukkan path lengkap folder: " FOLDER
      [[ -z "$FOLDER" ]] && { echo "❌ Path tidak boleh kosong!"; return; }
    else
      echo "❌ Pilihan tidak valid."; return;
    fi

    DOMAIN="$SUB.$ROOT_DOMAIN"
    echo "🌐 Target Domain: $DOMAIN"

    detect_ip
    send_telegram "🚀 *MULAI INSTALASI* \nDomain: \`$DOMAIN\` \nIP: \`$IP\`"

    # Instal paket
    echo "📦 Memeriksa & menginstal paket pendukung..."
    apt update -y -qq && apt install -y -qq nginx certbot python3-certbot-nginx curl openssl

    # Atur DNS Cloudflare
    echo "☁️ Menyinkronkan DNS Cloudflare..."
    GET_RES=$(curl -s -X GET "$API/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json")
    RECORD_ID=$(echo "$GET_RES" | grep -o '"id":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')

    if [[ -n "$RECORD_ID" ]]; then
      RESULT=$(curl -s -X PATCH "$API/zones/$ZONE_ID/dns_records/$RECORD_ID" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}")
    else
      RESULT=$(curl -s -X POST "$API/zones/$ZONE_ID/dns_records" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":false}")
    fi

    if ! echo "$RESULT" | grep -q '"success":true'; then
        echo "❌ Gagal atur DNS: $RESULT"
        send_telegram "❌ *DNS GAGAL*: $DOMAIN"; return
    fi
    echo "✅ DNS Berhasil diatur."

    # Buat Konfigurasi Nginx
    echo "⚙️ Membuat konfigurasi Nginx..."
    CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"

    if [[ "$MODE" == "1" ]]; then
    cat > $CONFIG_PATH <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    else
    cat > $CONFIG_PATH <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $FOLDER;
    index index.html index.htm index.php;
    location / { try_files \$uri \$uri/ =404; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
EOF
    fi

    ln -sf $CONFIG_PATH /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    nginx -t -q || { echo "❌ Konfigurasi Nginx Salah!"; send_telegram "❌ *NGINX GAGAL*"; return; }
    systemctl restart nginx
    echo "✅ Nginx Aktif."

    # Pasang SSL
    echo "🔒 Memasang SSL..."
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m "admin@$ROOT_DOMAIN" --redirect > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
      echo "✅ SSL Aktif (HTTPS)"
      send_telegram "🔒 *SSL AKTIF* \n✅ https://$DOMAIN"
    else
      echo "⚠️ SSL Gagal / Sudah Ada"
      send_telegram "⚠️ *SSL GAGAL*: $DOMAIN"
    fi

    echo ""
    echo "======================================"
    echo "✅ SELESAI: https://$DOMAIN"
    echo "======================================"
}

# ======================================
# 🗑️ FUNGSI HAPUS KONFIGURASI
# ======================================
delete_config() {
    clear
    echo "🗑️ HAPUS KONFIGURASI"
    echo "===================="
    read -p "📝 Masukkan nama subdomain yang mau dihapus: " SUB
    DOMAIN="$SUB.$ROOT_DOMAIN"
    CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"

    [ ! -f "$CONFIG_PATH" ] && { echo "❌ Tidak ditemukan: $DOMAIN"; return; }

    read -p "⚠️ Yakin hapus $DOMAIN? (y/n): " PILIH
    if [[ "$PILIH" == "y" || "$PILIH" == "Y" ]]; then
        rm -f /etc/nginx/sites-enabled/$DOMAIN
        rm -f $CONFIG_PATH
        systemctl restart nginx
        echo "✅ Dihapus."
        send_telegram "🗑️ *DIHAPUS*: $DOMAIN"
    else
        echo "❌ Dibatalkan."
    fi
}

# ======================================
# 📋 LIHAT DAFTAR
# ======================================
list_config() {
    clear
    echo "📋 DAFTAR DOMAIN TERSEDIA"
    echo "========================="
    ls -l /etc/nginx/sites-available/
    echo ""
}

# ======================================
# 📌 MENU UTAMA
# ======================================
while true; do
    clear
    echo "🚀 MENU UTAMA - CLOUDFLARE + SSL"
    echo "=================================="
    echo "1) Tambah / Ubah Konfigurasi"
    echo "2) Hapus Konfigurasi"
    echo "3) Lihat Daftar Konfigurasi"
    echo "4) Keluar"
    echo ""
    read -p "👉 Pilih menu [1-4]: " MENU

    case $MENU in
        1) install_config ;;
        2) delete_config ;;
        3) list_config ;;
        4) echo "👋 Keluar..."; exit 0 ;;
        *) echo "❌ Pilihan tidak valid!"; sleep 1 ;;
    esac
    echo ""
    read -p "Tekan [Enter] kembali ke menu..."
done