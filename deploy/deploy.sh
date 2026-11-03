#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
remote="root@8.159.136.59"
ssh_key="${SSH_KEY:-$HOME/.ssh/ali_grimlock.pem}"

ssh_cmd=(ssh -i "$ssh_key" "$remote")

"${ssh_cmd[@]}" 'mkdir -p /srv/grimlock.com.cn /opt/clockwork-deploy'

tar -C "$repo_root/docs" -czf - . |
  "${ssh_cmd[@]}" 'tar -xzf - -C /srv/grimlock.com.cn'

tar -C "$repo_root/deploy" -czf - \
  Caddyfile caddy.service clockwork-holiday-sync \
  clockwork-holiday-sync.service clockwork-holiday-sync.timer \
  README.md legacy-nginx-proxy-manager.yml |
  "${ssh_cmd[@]}" 'tar -xzf - -C /opt/clockwork-deploy'

"${ssh_cmd[@]}" '
  set -e
  install -m 0644 /opt/clockwork-deploy/Caddyfile /etc/caddy/Caddyfile
  install -m 0644 /opt/clockwork-deploy/caddy.service /etc/systemd/system/caddy.service
  install -m 0755 /opt/clockwork-deploy/clockwork-holiday-sync /usr/local/bin/clockwork-holiday-sync
  install -m 0644 /opt/clockwork-deploy/clockwork-holiday-sync.service /etc/systemd/system/clockwork-holiday-sync.service
  install -m 0644 /opt/clockwork-deploy/clockwork-holiday-sync.timer /etc/systemd/system/clockwork-holiday-sync.timer
  chown -R root:root /srv/grimlock.com.cn
  find /srv/grimlock.com.cn -type d -exec chmod 0755 {} +
  find /srv/grimlock.com.cn -type f -exec chmod 0644 {} +
  /usr/local/bin/caddy validate --config /etc/caddy/Caddyfile
  systemctl daemon-reload
  systemctl enable caddy >/dev/null
  systemctl restart caddy
  systemctl enable --now clockwork-holiday-sync.timer >/dev/null
  systemctl start clockwork-holiday-sync.service
'

for endpoint in /healthz /privacy.html /terms.html /support.html /version.json \
                /holiday-data/holiday-data-china.json; do
  curl -fsS "https://grimlock.com.cn${endpoint}" >/dev/null
done

echo "Deployed https://grimlock.com.cn"
