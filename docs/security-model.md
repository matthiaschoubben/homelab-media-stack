# Security model

One TCP port is open to the internet, and only one hostname on it reaches one service. Sonarr, Radarr, Prowlarr, Jackett, qBittorrent, Bazarr, Jellyseerr, Homarr, dashdot, Syncthing and AdGuard Home are reachable only from the LAN or over Tailscale.

## Defense in depth

| Layer | Control | Stops |
| --- | --- | --- |
| Exposure | Only TCP 44300 mapped; no 80, 8096 or admin UIs | Direct attacks on other services |
| Discovery | Wildcard cert, non-obvious hostname, high port, `abort` for unknown hosts | Most scanners, CT-log harvesting |
| Transport | Let's Encrypt TLS, HSTS | Eavesdropping, downgrade |
| Authentication | Per-friend accounts, strong passwords, lockout, admin LAN-only | Credential stuffing, admin takeover |
| Rate limiting | fail2ban on failed logins, banned in `DOCKER-USER` | Brute force |
| Containment | Separate Docker network, non-root, read-only media, `no-new-privileges` | Lateral movement, data destruction |

## Why Jellyfin's own login is the only authentication

The obvious extra layer would be SSO (Authelia, Authentik), Cloudflare Access, or client certificates. All of them break Jellyfin's native TV apps, which can't complete a browser-based login flow or present a certificate. That's exactly the client this project is for. So the design accepts Jellyfin's login as the gate, and concentrates on reducing who reaches it and on limiting what an attacker could do past it.

## Accepted risks

- **Jellyfin is the single authentication point.** Jellyfin has had API endpoints reachable without authentication in the past, so keeping it updated matters, and so does the containment layer.
- **The obscurity layers** (hostname, high port) slow attackers down. They aren't security on their own; the hostname is visible to anyone the URL is shared with.
- **UPnP is enabled on the gateway.** Any LAN device can open ports without authentication. It's the only way to manage the gateway here. Mitigation: periodic `upnpc -l` review.
- **The public IP is visible** to anyone who resolves the hostname. No geo-blocking yet.
- **DuckDNS outages** make the name unresolvable while they last. Nothing is exposed during an outage; friends just can't connect.
- **Homarr (Docker socket) and dashdot (`privileged`) are root-equivalent.** That's acceptable only because they're LAN-only. They must never be put behind Caddy.

## Rules I keep

- Never forward 8096 or any admin UI port.
- No secrets in `docker-compose.yml` or in git; they go in `.env` (mode 600).
- Redact tokens before sharing logs: `docker logs caddy 2>&1 | sed -E 's/token=[^&"]+/token=REDACTED/g'`.
- Rotate any token that has been pasted anywhere outside the server.
