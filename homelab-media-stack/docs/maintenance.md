# Maintenance and roadmap

## Routine checks

| How often | Check | Command |
| --- | --- | --- |
| Monthly | Update Jellyfin and Caddy | `docker compose pull jellyfin && docker compose build --pull caddy && docker compose up -d jellyfin caddy` |
| Monthly | Unexpected UPnP mappings | `upnpc -l` |
| Monthly | Bans and timers running | `sudo fail2ban-client status jellyfin`, `systemctl list-timers` |
| After a reboot | DNS and mapping intact | `dig +short <host> @1.1.1.1`, `upnpc -l \| grep 44300` |

Caddy renews the certificate automatically, about 30 days before it expires.

## Roadmap

- **Hardware transcoding.** The Intel N95 has Quick Sync: it decodes H.264, HEVC 8/10-bit, VP9 and AV1, and encodes H.264 and HEVC. The plan is to pass `/dev/dri/renderD128` into the container with the host's `render` group, select Intel QuickSync in Jellyfin, enable tone mapping, and set a ~20 Mbps remote bitrate limit so three streams fit in a 90 Mbps upload.
- **An own domain** with Cloudflare DNS (DNS only, not proxied: proxying video conflicts with Cloudflare's terms), to remove the DuckDNS dependency.
- **Geo-blocking** in Caddy for countries outside where friends live.
- **A split-DNS rewrite** in AdGuard, so the public URL also works at home.
- **Backups** of the Jellyfin config and the compose folder.
- **Reset the room router** and turn off its UPnP.
