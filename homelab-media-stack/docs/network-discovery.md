# Network discovery

Before exposing anything, I had to find out what my network actually looks like. I didn't have the room router's password, and the ISP gateway's web interface didn't answer. The conclusion: a real public IPv4 with no CGNAT, a single NAT layer, and a gateway that accepts UPnP.

| Question | Command | Finding |
| --- | --- | --- |
| Which subnet and gateway? | `ip -4 addr show`, `ip route` | Server in `192.168.128.0/23`, gateway `192.168.128.1`. A /23 covers `.128.0` to `.129.255`, which is why `192.168.1.1` timed out. |
| Is the room router doing NAT? | DHCP routes, `ip neigh show 192.168.128.1` | No. The gateway pushes ISP-specific host routes (DHCP option 121), and its MAC prefix `b8:8c:2b` is registered to Sagemcom, who make Proximus boxes. The room router only bridges. |
| What's on the path out? | `traceroute -n 1.1.1.1` | Hop 2 is `10.x.x.x`. On its own that could mean CGNAT, double NAT, or just private addressing inside the ISP network. The traceroute can't tell these apart. |
| CGNAT or a real public IP? | `upnpc -s` vs `curl -4 ifconfig.me` | The gateway's `ExternalIPAddress` equals the address the internet sees. No CGNAT, so hop 2 was ISP-internal. |
| Why no admin page? | `nmap -sV -p 1-10000 192.168.128.1` | 80 and 443 are closed on the gateway. Open: 53 (DNS), 5201 (iperf3) and a few management ports. Newer Proximus boxes are managed from the ISP's app. |
| Can I forward ports anyway? | `upnpc -s` | Yes: the gateway answers as a UPnP Internet Gateway Device. |

## Findings that shaped the design

- **ISP port blocking.** Proximus closes inbound 23, 80, 443, 992, 8023, 8080 and 8443 at network level by default. Unblocking them through the customer portal is unreliable, according to several forum threads. Using 44300 sidesteps this.
- **A second UPnP device.** `upnpc -s` also listed the room router as an Internet Gateway Device. It isn't the real gateway, so mappings on it expose nothing, but it's on the to-do list to reset.
- **No hairpinning.** The public URL may not work from inside the LAN, so I use the LAN address at home.

## End-to-end test before building anything

Before setting up the proxy, I confirmed that inbound traffic really arrives:

```bash
python3 -m http.server 8000                      # throwaway server
upnpc -e "porttest" -a <server-lan-ip> 8000 44300 TCP
# from a phone on mobile data: http://<public-ip>:44300 → directory listing
upnpc -d 44300 TCP                               # clean up
```
