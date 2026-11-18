# Troubleshooting log

Every problem I hit while setting this up, in the order it came up.

| Symptom | Cause | Fix |
| --- | --- | --- |
| `192.168.1.1` times out | The network uses `192.168.128.0/23`; the gateway is `192.168.128.1` | Read the gateway from `ip route` instead of assuming the default |
| No admin page on the gateway | The box has no web UI on 80/443 | Port forwarding via UPnP from the server |
| deSEC sign-up unavailable | New `dedyn.io` registrations were suspended after abuse | Switched to DuckDNS |
| `KeyError: 'ContainerConfig'` when recreating Jellyfin | Compose v1 (`docker-compose` 1.29.2) is incompatible with current Docker Engine | Installed Compose v2, removed the broken container, uninstalled v1 |
| Jellyfin stuck in `Restarting` | Now runs as UID 1000, but the config and cache folders were owned by root | `chown -R 1000:1000` both folders |
| Browser: "can't provide a secure connection" | Caddy had no certificate for the hostname (the next three rows) | |
| `invalidContact ... forbidden domain "example.com"` | Placeholder email left in the Caddyfile | Removed the `email` line |
| Certificate requested for `*.yourname.duckdns.org` | Placeholder domain left in the Caddyfile | Replaced with the real name |
| DuckDNS answers `KO` to the TXT update | One-letter typo in the subdomain; the token belongs to the correctly spelled one | Fixed the name in the Caddyfile and the DDNS script |
| `no configuration file provided: not found` | Ran compose from the parent folder | Always run compose from the folder holding `docker-compose.yml` |
| "Site can't be reached" right after the fix | Stale DNS answer cached on the phone or resolver | Resolved by itself; airplane mode on and off clears the phone's cache |
| `The "…" variable is not set` warning | A `$` in a password was read by Compose as a variable | Use `$$` in the compose file, or a single-quoted value in `.env` |

## Habits that came out of it

- **Read logs from the bottom.** `docker logs` shows the container's whole history, including attempts from hours ago. `docker logs <name> --since 10m` shows only what's current.
- **Debug layer by layer from the inside out:** container (`curl --resolve ... 127.0.0.1`), host port (`docker ps`), LAN IP, UPnP mapping (`upnpc -l`), DNS (`dig @1.1.1.1`), then the client. The first layer that fails is where the problem is.
- **Read the client's exact error.** `NXDOMAIN` points to DNS, a timeout to forwarding, "connection refused" to nothing listening, and a TLS error to the certificate.
- **Grep for placeholders** (`yourname`, `example.com`) after copying any example config.
