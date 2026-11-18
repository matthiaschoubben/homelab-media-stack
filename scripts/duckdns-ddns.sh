#!/bin/bash
# Update the DuckDNS A record when the public IP changes.
# The public IP is read from the ISP gateway over UPnP, so no external
# "what is my IP" service is needed.
#
# Config: /etc/duckdns/env  (SUBDOMAIN=your-subdomain, without .duckdns.org)
# Token:  /etc/duckdns/token (mode 600, root only)
set -euo pipefail

SUBDOMAIN="${SUBDOMAIN:?set SUBDOMAIN in /etc/duckdns/env}"
TOKEN=$(cat /etc/duckdns/token)

CURRENT=$(upnpc -s 2>/dev/null | awk -F' = ' '/ExternalIPAddress/ {print $2}')
IN_DNS=$(dig +short A "$SUBDOMAIN.duckdns.org" @ns1.duckdns.org | tail -n1)

if [[ -z "$CURRENT" ]]; then
    echo "Could not read public IP from gateway" >&2
    exit 1
fi

if [[ "$CURRENT" != "$IN_DNS" ]]; then
    RESULT=$(curl -fsS "https://www.duckdns.org/update?domains=$SUBDOMAIN&token=$TOKEN&ip=$CURRENT")
    echo "IP '$IN_DNS' -> '$CURRENT': DuckDNS answered $RESULT"
    [[ "$RESULT" == "OK" ]] || exit 1
else
    echo "IP unchanged ($CURRENT)"
fi
