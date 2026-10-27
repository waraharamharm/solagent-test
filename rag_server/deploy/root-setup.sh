#!/usr/bin/env bash
# Run as root, once:  DOMAIN=rag.example.com bash root-setup.sh
# Needs: an A record for $DOMAIN pointing at this server, nginx and certbot installed.
# Changes: linger for the solagent user, one new nginx site, one Let's Encrypt certificate.
set -euo pipefail
: "${DOMAIN:?set DOMAIN=your.domain}"
SITE=/etc/nginx/sites-available/solrag
HERE="$(cd "$(dirname "$0")" && pwd)"

loginctl enable-linger solagent

mkdir -p /var/www/solrag-acme
HTTP_ONLY=$(sed -e "s/__DOMAIN__/$DOMAIN/g" "$HERE/nginx-solrag.conf" | awk '/^server \{/{n++} n<2')
printf '%s\n' "$HTTP_ONLY" > "$SITE"
ln -sf "$SITE" /etc/nginx/sites-enabled/solrag
nginx -t
systemctl reload nginx

certbot certonly --webroot -w /var/www/solrag-acme -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email

sed -e "s/__DOMAIN__/$DOMAIN/g" "$HERE/nginx-solrag.conf" > "$SITE"
nginx -t
systemctl reload nginx
echo "ok: https://$DOMAIN/v1/health"