s
---

# 🚀 AUTO POINTING + CLOUDFLARE + SSL
**Skrip Otomatis Pengaturan Domain, DNS, Nginx, dan SSL Gratis**

Skrip ini dirancang untuk memudahkan pengelolaan domain di VPS. Hanya dengan satu kali perintah, kamu bisa mengarahkan domain ke aplikasi (port) atau folder berkas, mengatur DNS secara otomatis lewat Cloudflare, memasang sertifikat SSL, dan mendapatkan notifikasi langsung ke Telegram.

> ✨ **Cocok untuk**: Penyedia layanan internet, pengelola server, atau siapa saja yang sering mengatur banyak subdomain.

---

## ✨ FITUR UNGGULAN

- 🔐 **Sistem Keamanan Tinggi**
  - Data sensitif (Token, ID, Rahasia) disimpan terpisah dan aman.
  - Mendukung integrasi **GitHub Secrets** & **GitHub Actions** agar aman saat diunggah ke repositori publik.
  - Tidak ada data rahasia yang terekspos di kode sumber.

- ⚡ **Otomatisasi Penuh**
  - Deteksi IP Publik server secara otomatis.
  - Menambah atau Memperbarui catatan DNS di Cloudflare secara otomatis.
  - Membuat konfigurasi Nginx yang optimal dan aman.
  - Pemasangan Sertifikat SSL Let's Encrypt otomatis + Redirect HTTP ke HTTPS.

- 📌 **Dua Mode Pengarahan**
  1.  **Mode Port**: Mengarahkan domain ke aplikasi yang berjalan di latar belakang (Contoh: `127.0.0.1:3000`, `:8080`, dst).
  2.  **Mode Folder**: Mengarahkan domain langsung ke lokasi berkas di server (Contoh: `/var/www/nama_web`).

- 📢 **Notifikasi Real-time**
  - Laporan proses berjalan, sukses, atau gagal dikirim langsung ke **Telegram**.

- 🛡️ **Validasi & Penanganan Kesalahan**
  - Pengecekan hak akses `ROOT`.
  - Validasi masukan pengguna (subdomain, port, path).
  - Cek keberhasilan instalasi paket dan konfigurasi Nginx.

---

## 📋 PERSYARATAN SISTEM

Sebelum menggunakan skrip ini, pastikan kamu sudah menyiapkan:

1.  **Server / VPS** berbasis **Debian 10+** atau **Ubuntu 20.04+**.
2.  **Akun Cloudflare** dengan Domain yang sudah diarahkan ke Nameserver Cloudflare.
3.  **Data Akun Cloudflare**:
    - `CF_TOKEN`: *API Token* Cloudflare (Izin: Zone > DNS > Edit).
    - `ZONE_ID`: Kode ID domain utama kamu.
4.  **Akun Telegram**:
    - `BOT_TOKEN`: Didapatkan dari [@BotFather](https://t.me/BotFather).
    - `CHAT_ID`: Didapatkan dari [@getidsbot](https://t.me/getidsbot).
5.  **Domain Utama**: Contoh `hendrii.web.id`.

---

## 🔐 KONFIGURASI KEAMANAN (WAJIB)

Skrip ini menggunakan sistem pemisahan konfigurasi agar aman diunggah ke GitHub. Data rahasia **TIDAK DISIMPAN** di dalam berkas `install.sh`.

### 1. Cara Manual (Langsung di Server)
Buat berkas konfigurasi di folder yang sama dengan skrip, bernama `config.env`:

```env
# Isi sesuai data kamu
CF_TOKEN=isi_token_cloudflare_kamu
ZONE_ID=isi_zone_id_kamu
ROOT_DOMAIN=hendrii.web.id
BOT_TOKEN=isi_bot_token_telegram
CHAT_ID=isi_chat_id_telegram
```

> ⚠️ **PENTING**: Pastikan berkas `config.env` ditambahkan ke `.gitignore` agar tidak ikut terunggah ke GitHub.

### 2. Cara Otomatis (GitHub Secrets + Actions)
Jika kamu menyimpan proyek ini di GitHub dan ingin menjaga kerahasiaan data:

1.  Masuk ke **Repositori → Settings → Secrets and variables → Actions**.
2.  Buat Rahasia Baru untuk setiap data di atas (`CF_TOKEN`, `ZONE_ID`, dst).
3.  Buat berkas `.github/workflows/deploy.yml` dengan isi berikut:

```yaml
name: Deploy Otomatis
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Ambil Kode Sumber
        uses: actions/checkout@v4

      - name: 🔑 Buat Konfigurasi Aman
        run: |
          echo "CF_TOKEN=${{ secrets.CF_TOKEN }}" >> config.env
          echo "ZONE_ID=${{ secrets.ZONE_ID }}" >> config.env
          echo "ROOT_DOMAIN=${{ secrets.ROOT_DOMAIN }}" >> config.env
          echo "BOT_TOKEN=${{ secrets.BOT_TOKEN }}" >> config.env
          echo "CHAT_ID=${{ secrets.CHAT_ID }}" >> config.env

      - name: 🚀 Jalankan Instalasi
        run: |
          chmod +x install.sh
          sudo bash install.sh
```

4.  Buat berkas `.gitignore`:
```
config.env
*.env
.env
```

---

## 📥 CARA INSTALASI & PENGGUNAAN

### 🔹 Unduh Skrip
Pilih salah satu cara di bawah ini:

**Gunakan `wget`:**
```bash
wget https://raw.githubusercontent.com/heruhendri/Installer-Pointing/hendrii.web/install.sh -O install.sh
```

**Gunakan `curl`:**
```bash
curl -L https://raw.githubusercontent.com/heruhendri/Installer-Pointing/hendrii.web/install.sh -o install.sh
```

### 🔹 Beri Izin Eksekusi
```bash
chmod +x install.sh
```

### 🔹 Jalankan Skrip
> ⚠️ Harus dijalankan sebagai **ROOT**

```bash
sudo bash install.sh
```

### 📝 Alur Penggunaan:
1.  **Masukkan Subdomain**: Contoh `panel`, `billing`, `api`, `mikrotik`.
    *   Hasil akhir: `panel.hendrii.web.id`
2.  **Pilih Mode**:
    *   **Mode 1 (Port)**: Masukkan nomor port aplikasi (misal `3000`, `8080`, `4000`).
    *   **Mode 2 (Folder)**: Masukkan jalur lengkap folder (misal `/var/www/html/billing`).
3.  Tunggu proses selesai. Sistem akan melakukan:
    *   ✅ Deteksi IP Server
    *   ✅ Sinkronisasi DNS ke Cloudflare
    *   ✅ Buat Konfigurasi Nginx
    *   ✅ Pasang Sertifikat SSL (HTTPS)
4.  Cek Telegram kamu, akan ada notifikasi lengkap hasil pemasangan.

---

## 📂 LOKASI BERKAS HASIL INSTALASI

- **Konfigurasi Nginx**: `/etc/nginx/sites-available/[domain-kamu]`
- **Tautan Aktif**: `/etc/nginx/sites-enabled/`
- **Sertifikat SSL**: Dikelola otomatis oleh `certbot` di `/etc/letsencrypt/`
- **Log Sistem**: `/var/log/nginx/`

---

## ⚠️ CATATAN PENTING

1.  **Status Proxied**: Secara bawaan, DNS dibuat dengan status `Proxied: FALSE` (Awan Abu-abu). Kamu bisa mengubahnya menjadi aktif (Awan Oranye) di halaman Cloudflare jika ingin fitur CDN & Perlindungan aktif.
2.  **Port Firewall**: Pastikan port `80` dan `443` di server kamu **terbuka** agar proses verifikasi SSL berhasil.
3.  **Konfigurasi Lama**: Skrip ini otomatis menghapus berkas `default` di Nginx untuk mencegah konflik.
4.  **Keamanan**: Jangan pernah membagikan isi berkas `config.env` atau menampilkannya di log publik.

---

## 🛠️ PEMECAHAN MASALAH

*   **Gagal Deteksi IP**: Cek koneksi internet server atau izin akses ke `https://api.ipify.org`.
*   **Gagal DNS Cloudflare**: Cek kembali `CF_TOKEN` dan `ZONE_ID`, pastikan izin akses sudah benar.
*   **SSL Gagal**: Pastikan domain sudah benar-benar mengarah ke IP server kamu dan tidak ada pemblokiran dari penyedia hosting.
*   **Konfigurasi Nginx Error**: Biasanya terjadi karena nama domain duplikat atau path/folder yang dimasukkan tidak ada/hak akses ditolak.

---

**Dibuat dengan ❤️ oleh Heru Hendri**
