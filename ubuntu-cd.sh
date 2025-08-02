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

fatal() {
  echo "$1"
  exit 1
}

warn() {
  echo "$1"
}

# Find a source mirror near you which supports rsync on
# https://launchpad.net/ubuntu/+cdmirrors
# rsync://<iso-country-code>.rsync.releases.ubuntu.com/releases should always work
RSYNCSOURCE=rsync://ftp.kaist.ac.kr/ubuntu-cd

# Define where you want the mirror-data to be on your mirror
BASEDIR=/mirror/ubuntu-releases

if [ ! -d ${BASEDIR} ]; then
  warn "${BASEDIR} does not exist yet, trying to create it..."
  mkdir -p ${BASEDIR} || fatal "Creation of ${BASEDIR} failed."
fi

rsync --verbose --recursive --times --links --safe-links --hard-links \
  --stats --delete-after \
  ${RSYNCSOURCE} ${BASEDIR} || fatal "Failed to rsync from ${RSYNCSOURCE}."

date -u > ${BASEDIR}/.trace/$(hostname -f)
