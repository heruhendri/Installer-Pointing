
# 🚀 AUTO POINTING + CLOUDFLARE + SSL
Skrip otomatis untuk membuat konfigurasi domain di Nginx, menyinkronkan DNS ke Cloudflare, dan memasang sertifikat SSL Let's Encrypt. Cukup ketik perintah `cf` untuk masuk ke menu.

## ✨ FITUR UTAMA
- ✅ Otomatis deteksi IP publik server
- ✅ Terintegrasi penuh dengan API Cloudflare
- ✅ 2 Mode pengaturan:
  - **Mode Port**: Arahkan domain ke aplikasi berjalan di lokal (contoh: `127.0.0.1:3000`)
  - **Mode Folder**: Arahkan domain ke berkas statis atau website PHP di folder tertentu
- ✅ Pembuatan/Pembaruan catatan DNS otomatis
- ✅ Pemasangan SSL (HTTPS) otomatis menggunakan Certbot
- ✅ Notifikasi ke Telegram saat proses selesai/gagal
- ✅ Menu interaktif: Tambah / Hapus / Lihat daftar konfigurasi
- ✅ Cukup ketik `cf` saja, tanpa perlu `sudo` (hak akses otomatis)

---

## 📋 PERSYARATAN
- Server Ubuntu / Debian
- Akun Cloudflare dengan domain sudah terdaftar
- Token API Cloudflare (izin baca & tulis DNS)
- Bot Telegram & Chat ID untuk notifikasi

---

## ⚡ CARA PASANG

### 1. Unduh Skrip & Simpan ke Sistem
Jalankan perintah berikut satu per satu:
```bash
# Unduh berkas skrip dari repositori
curl -o /usr/local/bin/cf https://raw.githubusercontent.com/heruhendri/Installer-Pointing/refs/heads/menu/install.sh

# Berikan izin eksekusi
chmod +x /usr/local/bin/cf
```

### 2. Buat Berkas Konfigurasi
Buat folder dan berkas konfigurasi di lokasi sistem:
```bash
# Buat folder konfigurasi
mkdir -p /etc/cf

# Buat berkas konfigurasi
nano /etc/cf/config.env
```

Isi berkas `config.env` dengan data kamu:
```env
CF_TOKEN=token_api_cloudflare_kamu
ZONE_ID=zone_id_domain_kamu
ROOT_DOMAIN=domainutama.web.id
BOT_TOKEN=token_bot_telegram
CHAT_ID=nomor_chat_id_telegram
```

> 💡 **Cara mendapatkan nilai ini:**
> - `CF_TOKEN`: Buat di [Cloudflare > Profil > API Tokens](https://dash.cloudflare.com/profile/api-tokens) (Izin: *Zone:DNS:Edit*)
> - `ZONE_ID`: Ada di halaman ringkasan domain Cloudflare
> - `BOT_TOKEN`: Dapatkan dari [@BotFather](https://t.me/BotFather) di Telegram
> - `CHAT_ID`: Dapatkan dari [@getidsbot](https://t.me/getidsbot) di Telegram

Simpan dengan `Ctrl+O` → `Enter` → Keluar dengan `Ctrl+X`.

---

## 🚀 CARA PENGGUNAAN

Cukup ketik perintah berikut di terminal mana saja:
```bash
cf
```

### 📌 MENU UTAMA
```
🚀 MENU UTAMA - CLOUDFLARE + SSL
==================================
1) Tambah / Ubah Konfigurasi
2) Hapus Konfigurasi
3) Lihat Daftar Konfigurasi
4) Keluar
```

#### 1️⃣ Tambah / Ubah Konfigurasi
1. Masukkan nama subdomain (contoh: `panel`, `billing`, `api`)
2. Pilih mode:
   - **Mode 1 (Port)**: Masukkan nomor port aplikasi (contoh: `3000`, `8080`)
   - **Mode 2 (Folder)**: Masukkan jalur lengkap folder website (contoh: `/var/www/nama_web`)
3. Proses berjalan otomatis: Deteksi IP ➔ Atur DNS ➔ Buat konfigurasi Nginx ➔ Pasang SSL
4. Notifikasi dikirim ke Telegram jika sukses/gagal

#### 2️⃣ Hapus Konfigurasi
1. Masukkan nama subdomain yang ingin dihapus
2. Konfirmasi penghapusan
3. Konfigurasi Nginx dihapus dan layanan dimulai ulang

#### 3️⃣ Lihat Daftar Konfigurasi
Melihat semua domain yang sudah dikonfigurasi di server kamu.

---

## 📂 LOKASI BERKAS
- Skrip Perintah: `/usr/local/bin/cf`
- Konfigurasi Rahasia: `/etc/cf/config.env`
- Konfigurasi Nginx: `/etc/nginx/sites-available/`
- Konfigurasi Aktif: `/etc/nginx/sites-enabled/`

---

## 🛠️ PERBAIKAN & CATATAN
- Jika ada perubahan pada `config.env`, tidak perlu instal ulang, cukup jalankan ulang perintah `cf`.
- Jika Nginx gagal berjalan, cek dengan perintah `nginx -t` untuk melihat kesalahan konfigurasi.
- Sertifikat SSL diperbarui otomatis oleh sistem Certbot.

---

## 📄 LISENSI
Proyek ini dibuat untuk memudahkan manajemen domain dan server, bebas digunakan dan dikembangkan.

---
