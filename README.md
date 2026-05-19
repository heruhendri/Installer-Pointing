

# 🚀 AUTO POINTING + CLOUDFLARE + SSL

Skrip otomatis manajemen domain untuk Nginx, terintegrasi penuh dengan Cloudflare API, pemasangan SSL Let's Encrypt, dan notifikasi Telegram. Cukup ketik perintah `cf` untuk mengakses menu lengkap.

> **Repositori:** `https://raw.githubusercontent.com/heruhendri/Installer-Pointing/refs/heads/menu/install.sh`

---

## ✨ FITUR UTAMA

1.  **Manajemen Mudah**
    *   Cukup ketik `cf` saja (tanpa `sudo`, hak akses otomatis diminta saat diperlukan).
    *   Menu interaktif: Tambah/Ubah, Hapus, Lihat Daftar, dan Perbarui Skrip.

2.  **2 Mode Pengaturan**
    *   🚢 **Mode Port**: Meneruskan lalu lintas ke aplikasi lokal (contoh: `127.0.0.1:3000`, cocok untuk NodeJS, Python, dll).
    *   📁 **Mode Folder**: Menampilkan berkas website statis atau PHP dari folder server (contoh: `/var/www/nama_web`).

3.  **Integrasi Cloudflare**
    *   Deteksi IP Publik server otomatis.
    *   Membuat atau Memperbarui catatan DNS `A` secara langsung ke Cloudflare.
    *   Status *Proxied* dapat diatur (saat ini diset ke `Non-Aktif`).

4.  **Keamanan & SSL**
    *   Konfigurasi Nginx dihasilkan otomatis dan divalidasi agar aman.
    *   Pemasangan Sertifikat SSL Let's Encrypt otomatis dengan pengalihan HTTPS.
    *   Penanganan jika SSL sudah ada agar tidak membuang kuota.

5.  **Notifikasi Telegram**
    *   Laporan langkah demi langkah langsung ke Telegram dengan format rapi:
        *   🚀 Mulai Instalasi
        *   ☁️ Status DNS
        *   ✅ Status Nginx
        *   🔒 Status SSL
        *   🎉 Selesai / Gagal

6.  **Pembaruan Otomatis**
    *   Menu tersedia untuk mengunduh versi terbaru langsung dari repositori GitHub ini.

---

## 📋 PERSYARATAN

-   Sistem Operasi: **Ubuntu / Debian**
-   Akun Cloudflare dengan domain sudah terarah ke Cloudflare Nameserver
-   Token API Cloudflare (Izin: `Zone > DNS > Edit`)
-   Bot Telegram & Chat ID untuk notifikasi

---

## ⚡ CARA INSTALASI AWAL

Salin dan jalankan perintah berikut satu per satu di terminal:

```bash
# 1. Unduh Skrip dan simpan sebagai perintah 'cf'
curl -o /usr/local/bin/cf https://raw.githubusercontent.com/heruhendri/Installer-Pointing/refs/heads/menu/install.sh

# 2. Berikan izin eksekusi
chmod +x /usr/local/bin/cf

# 3. Buat folder konfigurasi sistem
mkdir -p /etc/cf

# 4. Buat berkas konfigurasi rahasia
nano /etc/cf/config.env
```

### 📝 Isi Berkas `config.env`

Salin kode di bawah, isi dengan data kamu, lalu simpan (`Ctrl+O` -> `Enter` -> `Ctrl+X`):

```env
CF_TOKEN=token_api_cloudflare_kamu
ZONE_ID=id_zone_domain_kamu
ROOT_DOMAIN=domainutama.web.id
BOT_TOKEN=token_bot_telegram_kamu
CHAT_ID=nomor_chat_id_telegram
```

> **Cara mendapatkan nilai:**
> *   `CF_TOKEN`: Buat di [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
> *   `ZONE_ID`: Ada di halaman ringkasan domain di Cloudflare
> *   `BOT_TOKEN`: Dapatkan dari [@BotFather](https://t.me/BotFather)
> *   `CHAT_ID`: Dapatkan dari [@getidsbot](https://t.me/getidsbot)

---

## 🚀 CARA PENGGUNAAN

Cukup ketik perintah berikut di direktori mana saja:

```bash
cf
```

### 📌 TAMPILAN MENU UTAMA
```
🚀 MENU UTAMA - CLOUDFLARE + SSL
==================================
1) Tambah / Ubah Konfigurasi
2) Hapus Konfigurasi
3) Lihat Daftar Konfigurasi
4) Perbarui Skrip dari GitHub
5) Keluar
```

#### 1️⃣ Tambah / Ubah Konfigurasi
1.  Masukkan nama subdomain (contoh: `panel`, `billing`, `acs-tabodok`).
2.  Pilih mode:
    *   **1) Port**: Masukkan nomor port aplikasi (contoh: `3000`, `4000`).
    *   **2) Folder**: Masukkan jalur lengkap folder website (contoh: `/var/www/html`).
3.  Proses berjalan otomatis: Deteksi IP ➔ Atur DNS ➔ Buat Konfigurasi Nginx ➔ Pasang SSL.
4.  Hasil proses akan dikirim ke Telegram kamu dengan format seperti ini:

    ```
    [5/19/2026 10:19 PM] cf-bot: 🚀 MULAI INSTALASI
    Domain: tabodok.hendrii.web.id
    IP: 51.79.231.130
    Status: Sedang diproses...

    [5/19/2026 10:19 PM] cf-bot: ☁️ DNS BERHASIL
    tabodok.hendrii.web.id ➡️ 51.79.231.130
    (Proxied: Non-Aktif)

    [5/19/2026 10:19 PM] cf-bot: ✅ NGINX SIAP
    Domain: tabodok.hendrii.web.id
    Mode: Port (4000)

    [5/19/2026 10:19 PM] cf-bot: 🔒 SSL AKTIF
    ✅ https://tabodok.hendrii.web.id

    [5/19/2026 10:19 PM] cf-bot: 🎉 INSTALASI SELESAI
    ✅ Domain: https://tabodok.hendrii.web.id
    ✅ Status: Berhasil diinstal
    ```

#### 2️⃣ Hapus Konfigurasi
*   Menghapus berkas konfigurasi domain dari Nginx dan memuat ulang layanan.
*   *Catatan: Tidak menghapus catatan DNS di Cloudflare agar tidak kehilangan rekam jejak.*

#### 3️⃣ Lihat Daftar Konfigurasi
*   Menampilkan semua domain yang sudah dikonfigurasi di `/etc/nginx/sites-available/`.

#### 4️⃣ Perbarui Skrip dari GitHub
*   Mengunduh versi terbaru langsung dari repositori ini dan mengganti skrip lama secara otomatis tanpa perlu instal ulang manual.

---

## 📂 LOKASI BERKAS PENTING

*   **Perintah Utama:** `/usr/local/bin/cf`
*   **Konfigurasi Rahasia:** `/etc/cf/config.env`
*   **Konfigurasi Nginx:** `/etc/nginx/sites-available/`
*   **Konfigurasi Aktif:** `/etc/nginx/sites-enabled/`

---

## 🔧 PEMECAHAN MASALAH

*   **Konfigurasi Nginx Bermasalah:**
    ```bash
    nginx -t
    ```
    Perintah ini akan memberi tahu baris mana yang salah penulisan.

*   **SSL Gagal:**
    *   Pastikan domain sudah benar-benar mengarah ke IP server.
    *   Cek kuota batas permintaan Let's Encrypt.
    *   Biasanya pesan `⚠️ SSL Gagal / Sudah Ada` itu normal, artinya sertifikat sudah terpasang sebelumnya.

*   **Izin Ditolak:**
    *   Skrip ini otomatis meminta hak akses, jika gagal jalankan sementara dengan `sudo cf`.

---

## 📄 LISENSI

Proyek ini dibuat untuk memudahkan manajemen server dan domain. Bebas digunakan, dimodifikasi, dan dikembangkan lebih lanjut.

---
