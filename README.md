
---

# 📡 NAT VPS HTTPS Reverse Proxy Installer

**Auto Cloudflare DNS + SSL + Telegram Notification**

Installer ini digunakan untuk **pointing port lokal ke domain HTTPS publik** pada VPS (termasuk NAT VPS), dengan fitur otomatis:

* 🌐 Auto create subdomain via Cloudflare API
* 🔒 Auto SSL (Let's Encrypt via Certbot)
* ⚙️ Auto reverse proxy via Nginx
* 🔔 Notifikasi realtime ke Telegram Bot
* 🚀 Simple installer (cukup input beberapa parameter)

---

# 🧩 Use Case

Cocok untuk:

* GenieACS (TR-069) → port 7547
* Web panel internal (NodeJS, PHP, dll)
* API service lokal
* Monitoring tools
* Semua service berbasis port lokal

---

# 🏗️ Arsitektur

```
Internet (HTTPS)
       ↓
Cloudflare DNS
       ↓
Domain (acs.domain.com)
       ↓
Nginx Reverse Proxy (VPS)
       ↓
127.0.0.1:PORT (Service lokal)
```

---

# 📦 Instalasi

## 1. Download Script

```bash
wget https://raw.githubusercontent.com/USERNAME/REPO/main/install.sh
chmod +x install.sh
```

## 2. Jalankan Installer

```bash
./install.sh
```

---

# 🧾 Input yang Dibutuhkan

Saat menjalankan script, kamu akan diminta:

| Parameter    | Contoh        | Keterangan                  |
| ------------ | ------------- | --------------------------- |
| Domain Utama | `hendri.site` | Domain di Cloudflare        |
| Subdomain    | `acs`         | Akan jadi `acs.hendri.site` |
| Port Lokal   | `7547`        | Port service di VPS         |
| CF API Token | `xxxx`        | Token Cloudflare            |
| Zone ID      | `xxxx`        | Zone domain                 |
| IP VPS       | `1.1.1.1`     | IP publik VPS               |
| Bot Token    | `xxxx`        | Token Telegram bot          |
| Chat ID      | `xxxx`        | ID Telegram                 |

---

# 🔑 Cara Mendapatkan Data

## ☁️ Cloudflare API Token

1. Login ke Cloudflare
2. Buka: **My Profile → API Tokens**
3. Create Token dengan permission:

   * Zone → DNS → Edit
   * Zone → Zone → Read

---

## 📌 Zone ID

* Masuk ke domain di Cloudflare
* Lihat di sidebar (Overview)

---

## 🤖 Telegram Bot

1. Chat ke BotFather
2. Buat bot → dapatkan **BOT TOKEN**

### Ambil Chat ID

Kirim pesan ke bot, lalu buka:

```
https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
```

---

# 🔔 Contoh Notifikasi Telegram

```
🚀 INSTALL STARTED
Domain: acs.hendri.site

✅ DNS CREATED
✅ NGINX CONFIGURED
🔒 SSL SUCCESS

🎉 INSTALL DONE
https://acs.hendri.site
```

---

# 🌐 Hasil Akhir

Misalnya:

* Subdomain: `acs`
* Domain: `hendri.site`
* Port: `7547`

Maka:

```
https://acs.hendri.site → http://127.0.0.1:7547
```

---

# ⚠️ Persyaratan

* OS: Ubuntu / Debian
* Akses root
* Domain di Cloudflare
* Port service sudah aktif (`netstat -tulnp`)
* Port 80 & 443 terbuka

---

# 🚨 Troubleshooting

## ❌ SSL Gagal

* Pastikan domain resolve ke IP VPS
* Disable proxy Cloudflare (DNS Only) saat pertama install

## ❌ DNS Tidak Terbuat

* Cek API Token permission
* Cek Zone ID benar

## ❌ Nginx Error

```bash
nginx -t
systemctl status nginx
```

---

# 🔥 Roadmap (Next Feature)

* [ ] Multi-port auto (GenieACS full stack)
* [ ] Wildcard subdomain
* [ ] Dashboard monitoring Telegram
* [ ] Auto install GenieACS
* [ ] Rate limiting & security hardening

---

# 🤝 Kontribusi

Pull request terbuka untuk improvement.

---

# 📄 License

Free to use for personal & ISP internal use.

---

