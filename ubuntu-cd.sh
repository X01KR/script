#!/bin/bash

apt update

echo apt updated

apt install rsync nginx -y

echo installed rsync, nginx

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

echo removed default nginx config

cd /etc/nginx/sites-enabled/

wget https://raw.githubusercontent.com/x01kr/script/main/nginx-ubuntu-cd.conf >> /dev/null

echo downloaded nginx config for mirror

nginx -s reload

echo success to reload nginx

mkdir -p /mirror/ubuntu-releases

echo made /mirror/ubuntu-releases

chown $USER:$USER /mirror/ubuntu-releases

rsync -av --delete --progress rsync://ftp.kaist.ac.kr/ubuntu-cd/ /mirror/ubuntu-releases/
