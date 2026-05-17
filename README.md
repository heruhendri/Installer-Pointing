
---

# 🚀 Auto Pointing + Cloudflare + SSL
Skrip otomatis untuk memudahkan pemasangan konfigurasi domain, pengaturan DNS di Cloudflare, konfigurasi Nginx, serta pemasangan Sertifikat SSL gratis dari Let's Encrypt. Cocok untuk mengarahkan domain ke port aplikasi atau folder berkas di VPS anda.

## ✨ Fitur Unggulan
- ✅ Berjalan otomatis sebagai pengguna `root`
- 🌐 Deteksi IP Publik VPS secara otomatis
- ☁️ Pengaturan DNS otomatis ke Cloudflare (buat baru atau perbarui jika sudah ada)
- ⚙️ Dua mode penunjuk:
  - **Mode Port**: Mengarahkan domain ke aplikasi yang berjalan di port tertentu (misal: `http://127.0.0.1:3000`)
  - **Mode Folder**: Mengarahkan domain langsung ke direktori berkas di server
- 🔒 Pemasangan SSL otomatis menggunakan `Let's Encrypt`
- 🔄 Konfigurasi Nginx otomatis & pengecekan kesalahan konfigurasi
- 📢 Notifikasi langsung ke Telegram saat proses berjalan selesai/gagal
- 🚀 Mengaktifkan redirect otomatis dari `HTTP` ke `HTTPS`

---

## 📋 Persyaratan
- Server / VPS berbasis **Debian / Ubuntu**
- Memiliki akun Cloudflare dan domain yang sudah diarahkan ke nameserver Cloudflare
- Sudah membuat Bot Telegram dan mendapatkan `Bot Token` serta `Chat ID`
- Mendapatkan `Zone ID` dan `API Token` dari akun Cloudflare

---

## ⚙️ Konfigurasi Awal
Sebelum menjalankan skrip, pastikan Anda mengisi nilai berikut di dalam berkas `install.sh` pada bagian **CONFIG**:

```bash
CF_TOKEN="ISI_TOKEN_CLOUDFLARE_ANDA"
ZONE_ID="ISI_ZONE_ID_ANDA"
ROOT_DOMAIN="domain-anda.web.id" # Contoh: hdri.web.id
BOT_TOKEN="ISI_TOKEN_BOT_TELEGRAM"
CHAT_ID="ISI_CHAT_ID_TELEGRAM"
```

### Cara mendapatkan nilai konfigurasi:
1. **Cloudflare API Token & Zone ID**:
   - Masuk ke akun Cloudflare → Pilih Domain Anda → Menu **API** → **Create Token** → Buat token dengan izin *Zone:DNS:Edit*
   - `Zone ID` ada di halaman utama domain Anda.
2. **Telegram Bot Token**:
   - Chat ke [@BotFather](https://t.me/BotFather) → Buat Bot baru → Salin Token yang diberikan.
3. **Telegram Chat ID**:
   - Chat ke [@getidsbot](https://t.me/getidsbot) → Salin angka ID yang ditampilkan.

---

## 📥 Cara Install & Penggunaan

Anda bisa mengunduh berkas menggunakan salah satu perintah di bawah ini:

### 🔹 Menggunakan `wget`
```bash
wget https://github.com/heruhendri/Installer-Pointing/raw/refs/heads/final/install.sh -O install.sh
```

### 🔹 Menggunakan `curl`
```bash
curl -L https://github.com/heruhendri/Installer-Pointing/raw/refs/heads/final/install.sh -o install.sh
```

### 🔹 Beri Izin Eksekusi
```bash
chmod +x install.sh
```

### 🔹 Jalankan Skrip
```bash
bash install.sh
```

---

## 📝 Alur Penggunaan
1. Masukkan nama **Subdomain** yang ingin dibuat (contoh: `panel`, `api`, `billing`).
   - Hasil akhir: `panel.domain-anda.web.id`
2. Pilih Mode:
   - **Pilih 1 (Port)**: Masukkan nomor port aplikasi anda (contoh: `4000`, `3000`, `8080`).
   - **Pilih 2 (Folder)**: Masukkan lokasi folder absolut di server (contoh: `/var/www/html/billing`).
3. Tunggu proses selesai, sistem akan:
   - Memasang paket pendukung (`nginx`, `certbot`)
   - Menambahkan / Memperbarui catatan DNS di Cloudflare
   - Membuat berkas konfigurasi Nginx
   - Memasang Sertifikat SSL dan mengaktifkan `HTTPS`
4. Anda akan menerima notifikasi di Telegram jika proses berhasil atau gagal.

---

## 📂 Struktur Konfigurasi
- Berkas konfigurasi Nginx tersimpan di: `/etc/nginx/sites-available/[subdomain.domainanda.web.id]`
- Tautan aktif di: `/etc/nginx/sites-enabled/`
- Sertifikat SSL dikelola otomatis oleh `certbot` (terpasang di `/etc/letsencrypt/`)

---

## ❌ Catatan Penting
- Skrip ini otomatis menghapus berkas `default` pada `sites-enabled` Nginx agar tidak konflik.
- Pengaturan DNS dibuat dengan status **Proxied = False** (abu-abu). Anda bisa mengubahnya menjadi *Proxied* (awan oranye) secara manual di halaman Cloudflare jika ingin perlindungan & CDN aktif.
- Pastikan port `80` dan `443` di server **tidak diblokir** oleh firewall agar proses verifikasi SSL berhasil.

---

## 🛠️ Masalah & Solusi
- **Gagal deteksi IP**: Pastikan server terhubung ke internet dan bisa mengakses `https://api.ipify.org`.
- **Gagal SSL**: Cek apakah domain sudah mengarah ke Cloudflare dan belum ada batasan port.
- **Konfigurasi Nginx Error**: Biasanya terjadi karena port atau alamat folder yang dimasukkan tidak benar atau sudah digunakan konfigurasi lain.