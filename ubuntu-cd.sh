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

echo “동기화 스크립트 생성 중…”
cat > /usr/local/bin/ubuntu-mirror-sync.sh << ‘EOF’
#!/bin/bash

# 로그 파일 설정

LOG_FILE=”/var/log/ubuntu-mirror-sync.log”
DATE=$(date ‘+%Y-%m-%d %H:%M:%S’)

# 로그 함수

log() {
echo “[$DATE] $1” | tee -a “$LOG_FILE”
}

# 동기화 시작 로그

log “Ubuntu 미러 동기화 시작”

# rsync 실행 (백그라운드에서)

if rsync -av –delete –timeout=3600 –contimeout=60 rsync://ftp.kaist.ac.kr/ubuntu-cd/ /mirror/ubuntu-releases/ >> “$LOG_FILE” 2>&1; then
log “동기화 완료”
else
log “동기화 실패 (종료 코드: $?)”
fi

log “동기화 작업 종료”
EOF

# 동기화 스크립트 실행 권한 부여

chmod +x /usr/local/bin/ubuntu-mirror-sync.sh

# 로그 파일 생성 및 권한 설정

touch /var/log/ubuntu-mirror-sync.log
chmod 644 /var/log/ubuntu-mirror-sync.log

# cron 작업 추가 (4시간마다 실행)

echo “cron 작업 설정 중…”
CRON_JOB=“0 */4 * * * /usr/local/bin/ubuntu-mirror-sync.sh”

# 기존 cron 작업이 있는지 확인하고 추가

(crontab -l 2>/dev/null | grep -v ubuntu-mirror-sync.sh; echo “$CRON_JOB”) | crontab -

# cron 서비스 재시작

systemctl restart cron

echo “초기 Ubuntu 릴리스 동기화 시작…”
/usr/local/bin/ubuntu-mirror-sync.sh &

echo “”
echo “=========================================”
echo “설정 완료!”
echo “=========================================”
echo “• Ubuntu 미러가 /mirror/ubuntu-releases에 설정되었습니다”
echo “• 4시간마다 자동 동기화됩니다 (매일 0시, 4시, 8시, 12시, 16시, 20시)”
echo “• 동기화 로그: /var/log/ubuntu-mirror-sync.log”
echo “• 수동 동기화: /usr/local/bin/ubuntu-mirror-sync.sh”
echo “”
echo “cron 상태 확인: systemctl status cron”
echo “cron 작업 확인: crontab -l”
echo “로그 확인: tail -f /var/log/ubuntu-mirror-sync.log”
echo “=========================================”