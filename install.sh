#!/bin/bash

clear
echo "🚀 INSTALLER NOC AUTO (1 COMMAND)"

# download v2
mkdir -p /root/noc
cd /root/noc

echo "📥 Download script..."

wget -q https://raw.githubusercontent.com/heruhendri/Installer-Pointing/main/v2/monitor.sh
wget -q https://raw.githubusercontent.com/heruhendri/Installer-Pointing/main/v2/dns-sync.sh
wget -q https://raw.githubusercontent.com/heruhendri/Installer-Pointing/main/v2/domains.conf
wget -q https://raw.githubusercontent.com/heruhendri/Installer-Pointing/main/v2/install.sh

chmod +x *.sh

echo "🚀 Jalankan setup..."
./install.sh