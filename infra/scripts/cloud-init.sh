#!/usr/bin/env bash
set -Eeuo pipefail

CF_TOKEN='${cloudflare_api_token}'
trap 'sed -i "s/^CF_TOKEN=.*/CF_TOKEN=REDACTED/" /var/lib/cloud/instance/scripts/part-* /var/lib/cloud/instance/user-data.txt* 2>/dev/null || true' EXIT

DOMAIN="capture-the-cup.ossec.me"
ADMIN_USER="evil"


THEME_REPO="https://github.com/O-S-S-E-C/capture-the-cup.git"
THEME_DIR="/srv/theme-repo"

export DEBIAN_FRONTEND=noninteractive

echo 'DPkg::Lock::Timeout "300";' > /etc/apt/apt.conf.d/99lock-timeout

DISK=/dev/disk/azure/scsi1/lun0
for _ in $(seq 60); do [ -b "$DISK" ] && break; sleep 5; done
[ -b "$DISK" ] || { echo "Data disk not found at $DISK" >&2; exit 1; }

blkid "$DISK" >/dev/null 2>&1 || mkfs.ext4 -F "$DISK"
DISK_UUID="$(blkid -s UUID -o value "$DISK")"
mkdir -p /srv
grep -q "$DISK_UUID" /etc/fstab || echo "UUID=$DISK_UUID /srv ext4 defaults,nofail 0 2" >> /etc/fstab
mountpoint -q /srv || mount /srv
mountpoint -q /srv || { echo "/srv is not mounted" >&2; exit 1; }

mkdir -p /srv/docker /srv/config /srv/letsencrypt

apt-get update
apt-get install -y ca-certificates curl git certbot python3-certbot-dns-cloudflare


mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "data-root": "/srv/docker",
  "features": { "containerd-snapshotter": false }
}
EOF
curl -fsSL https://get.docker.com | sh
usermod -aG docker "$ADMIN_USER" || true


if [ ! -L /etc/letsencrypt ]; then
  rm -rf /etc/letsencrypt
  ln -s /srv/letsencrypt /etc/letsencrypt
fi

if [ "$CF_TOKEN" != "REDACTED" ]; then
  install -m 600 /dev/null /srv/letsencrypt/cloudflare.ini
  echo "dns_cloudflare_api_token = $CF_TOKEN" > /srv/letsencrypt/cloudflare.ini
fi

mkdir -p /srv/letsencrypt/renewal-hooks/deploy
cat > /srv/letsencrypt/renewal-hooks/deploy/reload-nginx.sh <<'EOF'
#!/bin/sh
docker compose -f /srv/ctfd/docker-compose.yml exec -T nginx nginx -s reload || true
EOF
chmod 755 /srv/letsencrypt/renewal-hooks/deploy/reload-nginx.sh


if [ ! -d "/srv/letsencrypt/live/$DOMAIN" ]; then
  certbot certonly --non-interactive --agree-tos --register-unsafely-without-email \
    --dns-cloudflare --dns-cloudflare-credentials /srv/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 30 -d "$DOMAIN" \
    || echo "WARNING: certbot failed, see /var/log/letsencrypt/letsencrypt.log" >&2
fi


[ -d /srv/ctfd/.git ] || git clone --depth 1 https://github.com/CTFd/CTFd.git /srv/ctfd
mkdir -p /srv/ctfd/.data/CTFd/logs /srv/ctfd/.data/mysql /srv/ctfd/.data/redis


if [ -d "$THEME_DIR/.git" ]; then
  git -C "$THEME_DIR" pull --ff-only || echo "WARNING: theme repo pull failed" >&2
else
  git clone --depth 1 "$THEME_REPO" "$THEME_DIR" \
    || echo "WARNING: theme repo clone failed, falling back to default theme" >&2
fi


THEME_LINK="/srv/ctfd/CTFd/themes/mytheme"
if [ -L "$THEME_LINK" ]; then
  :
else
  rm -rf "$THEME_LINK"
  ln -s "$THEME_DIR/mytheme" "$THEME_LINK"
fi


HAVE_CERT=no
[ -f "/srv/letsencrypt/live/$DOMAIN/fullchain.pem" ] && HAVE_CERT=yes
[ "$HAVE_CERT" = yes ] || echo "WARNING: no certificate yet, nginx will serve HTTP only" >&2

{
cat <<'EOF'
worker_processes auto;

events {
  worker_connections 1024;
}

http {
  upstream app_servers {
    server ctfd:8000;
  }

  # Use the scheme Cloudflare reports, so CTFd knows the visitor used HTTPS.
  map $http_x_forwarded_proto $fwd_proto {
    default $scheme;
    https   https;
  }

  # Traffic always arrives from Cloudflare's edge, so $remote_addr would
  # otherwise be Cloudflare's IP for every visitor. These ranges tell nginx
  # to trust the real client IP Cloudflare passes in CF-Connecting-IP.
  # Ranges from https://www.cloudflare.com/ips/ (IPv4); update if they change.
  set_real_ip_from 173.245.48.0/20;
  set_real_ip_from 103.21.244.0/22;
  set_real_ip_from 103.22.200.0/22;
  set_real_ip_from 103.31.4.0/22;
  set_real_ip_from 141.101.64.0/18;
  set_real_ip_from 108.162.192.0/18;
  set_real_ip_from 190.93.240.0/20;
  set_real_ip_from 188.114.96.0/20;
  set_real_ip_from 197.234.240.0/22;
  set_real_ip_from 198.41.128.0/17;
  set_real_ip_from 162.158.0.0/15;
  set_real_ip_from 104.16.0.0/13;
  set_real_ip_from 104.24.0.0/14;
  set_real_ip_from 172.64.0.0/13;
  set_real_ip_from 131.0.72.0/22;
  set_real_ip_from 2400:cb00::/32;
  set_real_ip_from 2606:4700::/32;
  set_real_ip_from 2803:f800::/32;
  set_real_ip_from 2405:b500::/32;
  set_real_ip_from 2405:8100::/32;
  set_real_ip_from 2a06:98c0::/29;
  set_real_ip_from 2c0f:f248::/32;
  real_ip_header CF-Connecting-IP;
EOF

if [ "$HAVE_CERT" = yes ]; then
  cat <<'EOF'

  # Plain HTTP: send everyone to HTTPS.
  server {
    listen 80;
    return 301 https://$host$request_uri;
  }

  server {
    listen 443 ssl;
EOF
  echo "    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;"
  echo "    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"
else
  cat <<'EOF'

  server {
    listen 80;
EOF
fi
cat <<'EOF'

    gzip on;
    client_max_body_size 4G;

    location /events {
      proxy_pass http://app_servers;
      proxy_set_header Connection '';
      proxy_http_version 1.1;
      chunked_transfer_encoding off;
      proxy_buffering off;
      proxy_cache off;
      proxy_redirect off;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Host $server_name;
      proxy_set_header X-Forwarded-Proto $fwd_proto;
      proxy_set_header X-Forwarded-Prefix "";
    }

    location / {
      proxy_pass http://app_servers;
      proxy_redirect off;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Host $server_name;
      proxy_set_header X-Forwarded-Proto $fwd_proto;
      proxy_set_header X-Forwarded-Prefix "";
    }
  }
}
EOF
} > /srv/config/nginx.conf


[ -f /srv/config/secret_key ] || openssl rand -hex 32 > /srv/config/secret_key
chmod 600 /srv/config/secret_key

cd /srv/ctfd
cat > docker-compose.override.yml <<EOF
services:
  ctfd:
    environment:
      - SECRET_KEY=$(cat /srv/config/secret_key)
    volumes:
      - /srv/theme-repo/mytheme:/opt/CTFd/CTFd/themes/mytheme:ro

  nginx:
    ports:
      - 443:443
    volumes:
      - /srv/config/nginx.conf:/etc/nginx/nginx.conf:ro
      - /srv/letsencrypt:/etc/letsencrypt:ro
EOF
chmod 600 docker-compose.override.yml

docker compose up -d --build
docker compose restart nginx
docker compose ps