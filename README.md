###
➡️ **Pointing port lokal ke HTTPS domain (reverse proxy via Nginx + SSL Let's Encrypt)**
➡️ Cocok untuk **NAT VPS (port service internal → domain publik HTTPS)**
➡️ User hanya input: **domain + port**

---

## 🔧 Fitur

* Auto install Nginx + Certbot
* Auto generate config reverse proxy
* Auto SSL (Let's Encrypt)
* Support NAT VPS (port bebas, misal 7547 / 8080 / 3000 dll)
* Clean & idempotent (bisa rerun)

---

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
```

---

## 📦 Cara Pakai (untuk user GitHub kamu)

```json
wget https://raw.githubusercontent.com/heruhendri/Installer-Pointing/main/install.sh
chmod +x install.sh
./install.sh
```

---

## 📌 Contoh Penggunaan

Misalnya:

* Domain: `acs.hendri.site`
* Port: `7547` (GenieACS / TR-069)

➡️ Maka:

```
https://acs.hendri.site → http://127.0.0.1:7547
```

---

## ⚠️ Catatan Penting (NAT VPS)

* Pastikan:

  * Port lokal sudah listen (`netstat -tulnp`)
  * Domain sudah A record ke IP VPS
* Kalau pakai Cloudflare:

  * Gunakan **DNS Only (abu-abu)** saat SSL pertama kali

---
