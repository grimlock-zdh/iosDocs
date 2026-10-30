#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
remote="root@8.159.136.59"
ssh_key="${SSH_KEY:-$HOME/.ssh/ali_grimlock.pem}"

ssh_cmd=(ssh -i "$ssh_key" "$remote")

"${ssh_cmd[@]}" 'mkdir -p /srv/grimlock.com.cn /opt/clockwork-deploy'

tar -C "$repo_root/docs" -czf - . |
  "${ssh_cmd[@]}" 'tar -xzf - -C /srv/grimlock.com.cn'

tar -C "$repo_root/deploy" -czf - Caddyfile caddy.service README.md legacy-nginx-proxy-manager.yml |
  "${ssh_cmd[@]}" 'tar -xzf - -C /opt/clockwork-deploy'

"${ssh_cmd[@]}" '
  set -e
  install -m 0644 /opt/clockwork-deploy/Caddyfile /etc/caddy/Caddyfile
  install -m 0644 /opt/clockwork-deploy/caddy.service /etc/systemd/system/caddy.service
  chown -R root:root /srv/grimlock.com.cn
  find /srv/grimlock.com.cn -type d -exec chmod 0755 {} +
  find /srv/grimlock.com.cn -type f -exec chmod 0644 {} +
  /usr/local/bin/caddy validate --config /etc/caddy/Caddyfile
  systemctl daemon-reload
  systemctl enable caddy >/dev/null
  systemctl restart caddy
'

for endpoint in /healthz /privacy.html /terms.html /support.html /version.json; do
  curl -fsS "https://grimlock.com.cn${endpoint}" >/dev/null
done

echo "Deployed https://grimlock.com.cn"
