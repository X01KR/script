#!/bin/bash

apt update
apt install rsync nginx -y

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

cd /etc/nginx/sites-enabled/

wget https://raw.githubusercontent.com/x01kr/script/main/nginx-ubuntu-cd.conf

nginx -s reload

mkdir -p /mirror/ubuntu-releases

chown $USER:$USER /mirror/ubuntu-releases

rsync -av --delete --progress rsync://ftp.kaist.ac.kr/ubuntu-cd/ /mirror/ubuntu-releases/
