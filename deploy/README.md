# `grimlock.com.cn` static site

Primary host for ClockWork legal/support pages and the update manifest.
GitHub Pages remains the read-only backup.

## Public endpoints

- `https://grimlock.com.cn/`
- `https://grimlock.com.cn/privacy.html`
- `https://grimlock.com.cn/terms.html`
- `https://grimlock.com.cn/support.html`
- `https://grimlock.com.cn/version.json`
- Compatibility aliases: prefix any page with `/clockwork/`
- Health check: `https://grimlock.com.cn/healthz`
- Backup: `https://grimlock-zdh.github.io/iosDocs/`

The version manifest is cacheable for 30 seconds and uses no query string,
cookies, device identifiers, or access logs.

## Update a release

Edit `docs/version.json`, commit/push the `iosDocs` repository, then deploy:

```bash
tar -C docs -czf - . |
  ssh -i ~/.ssh/ali_grimlock.pem root@8.159.136.59 \
  'mkdir -p /srv/grimlock.com.cn && tar -xzf - -C /srv/grimlock.com.cn'
```

For legal-page changes, deploy the whole `docs/` directory the same way.

## Server layout

- Binary: `/usr/local/bin/caddy`
- Service: `/etc/systemd/system/caddy.service`
- Config: `/etc/caddy/Caddyfile`
- Static files: `/srv/grimlock.com.cn`
- Caddy state/certificates: `/var/lib/caddy/.local/share/caddy`
- Legacy Nginx Proxy Manager is retained for its existing admin service on
  port `5003`; its web ports are bound to localhost only.

## Operations

```bash
systemctl status caddy --no-pager
journalctl -u caddy -n 100 --no-pager
/usr/local/bin/caddy validate --config /etc/caddy/Caddyfile
/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
curl -fsS https://grimlock.com.cn/healthz
curl -fsS https://grimlock.com.cn/version.json
```

Rollback from the server:

```bash
systemctl disable --now caddy
cd /clouddream/nginx-proxy-manage
docker compose up -d
```

The rollback restores Nginx Proxy Manager on ports 80/443. Its data and
certificate directories are never removed by the ClockWork deployment.
