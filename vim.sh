#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
echo “This script require root permission”
exit 1
fi

echo “Create mirror directory...”
mkdir -p /mirror/vim

echo "Changing Permission..."
ACTUAL_USER=${SUDO_USER:-$USER}
chown $ACTUAL_USER:$ACTUAL_USER /mirror/vim

cd /data/mirror/script

echo "Downloading syncing script..."
wget -O ubuntu-cd-sync.sh https://raw.githubusercontent.com/x01kr/script/main/vim-sync.sh

echo "Changing Permission for syncing script..."
chmod +x vim-sync.sh

echo "Add script to Cron"
CRON_JOB='0 4,10,16,22 * * * /data/mirror/script/vim-sync.sh >> /data/mirror/vim-sync.log'

(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Syncing..."
./vim-sync.sh
