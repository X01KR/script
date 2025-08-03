#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
echo “This script require root permission”
exit 1
fi

echo “Updating packages...”
apt update

echo “Installing rsync, nginx...”
apt install rsync nginx -y

echo “Removing default nginx config...”
rm -f /etc/nginx/sites-available/default
rm -f /etc/nginx/sites-enabled/default

echo “Downloading Nginx config...”
cd /etc/nginx/sites-enabled/
wget -O nginx-ubuntu-cd.conf https://raw.githubusercontent.com/x01kr/script/main/nginx-ubuntu-cd.conf

echo “Testing Nginx config...”
nginx -t

echo “Restarting Nginx...”
systemctl reload nginx

echo “Create mirror directory...”
mkdir -p /mirror/ubuntu-releases


ACTUAL_USER=${SUDO_USER:-$USER}
chown $ACTUAL_USER:$ACTUAL_USER /mirror/ubuntu-releases

mkdir -p /data/mirror/script

cd /data/mirror/script

wget -O ubuntu-cd-sync.sh https://raw.githubusercontent.com/x01kr/script/main/ubuntu-cd-sync.sh

chmod +x ubuntu-cd-sync.sh

CRON_JOB='0 4,10,16,22 * * * /data/mirror/script/ubuntu-cd-sync.sh >> /data/mirror/ubuntu-releases-sync.log'

(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

./ubuntu-cd-sync.sh

