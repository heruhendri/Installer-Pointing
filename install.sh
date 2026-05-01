#!/bin/bash

clear
echo "🚀 INSTALLER AUTO POINTING"

mkdir -p /root/pointing
cd /root/pointing

echo "📥 Download script..."
wget -q https://raw.githubusercontent.com/heruhendri/Installer-Pointing/hendrii.web.id/v2/install.sh

chmod +x install.sh

echo "🚀 Run installer..."
./install.sh