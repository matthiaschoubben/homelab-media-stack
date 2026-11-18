#!/bin/bash
# Keep a UPnP port mapping on the ISP gateway pointing at this server.
# Re-run by a systemd timer: mappings can vanish on a gateway reboot, and the
# LAN IP is looked up on every run in case DHCP handed out a new one.
set -euo pipefail

IFACE="${IFACE:-enp1s0}"   # LAN interface of this server
EXT_PORT=44300             # port the internet connects to
INT_PORT=44300             # port Caddy listens on (published by Docker)
LEASE=3600                 # seconds; use 0 if the gateway answers error 725
                           # (OnlyPermanentLeasesSupported)

LAN_IP=$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)

# Remove a possibly stale mapping (e.g. pointing to an old IP), ignore errors
upnpc -d "$EXT_PORT" TCP >/dev/null 2>&1 || true
upnpc -e "caddy-https" -a "$LAN_IP" "$INT_PORT" "$EXT_PORT" TCP "$LEASE"
