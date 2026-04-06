*🌍 Leer esto en [Español](tailscale-setup.md)*

# 🔒 Tailscale Funnel Setup

Tailscale Funnel allows you to expose a local service securely to the internet via HTTPS, without opening router ports or buying a domain.

This is **essential** so n8n can receive Telegram Webhooks securely over TLS/SSL natively.

> **💡 Quick Shortcut**: You can automate steps 4 and 5 of this guide by running `sudo ./tailscale_config.sh` from the repository root.

---

## Why Tailscale?

| Alternative | Drawback |
|-------------|----------|
| Opening router ports | Insecure, exposes your home server |
| ngrok | Time limits on free tier, URL changes constantly |
| Cloudflare Tunnel | High configuration complexity |
| **Tailscale Funnel** | ✅ Free, Automatic HTTPS, Static URL, No ports opened |

---

## Setup

### 1. Install Tailscale

```bash
# Debian / Ubuntu
curl -fsSL https://tailscale.com/install.sh | sh

# Arch Linux
sudo pacman -S tailscale
```

### 2. Authenticate to your account

```bash
sudo tailscale up
```

This commands gives you a login link you must open in your browser to bind your machine to [login.tailscale.com](https://login.tailscale.com).

### 3. Enable Funnel Functionality

From the Tailscale Admin Console ([login.tailscale.com/admin](https://login.tailscale.com/admin)):

1. Open **DNS** and make sure MagicDNS and HTTPS generation are enabled.
2. Open **Access Controls** and allow Funnel attributes to your user/node.

### 4. Expose n8n with Funnel

```bash
# Exposes internal port 5678 (n8n) with a public HTTPS endpoint
sudo tailscale funnel 5678
```

This prints a URL like: `https://your-node-name.tail-net.ts.net`

### 5. Configure n8n Environment

Inside the `services/n8n/.env` file, configure the webhook URLs so n8n knows its public facing domain:

```env
WEBHOOK_URL=https://your-node-name.tail-net.ts.net
WEBHOOK_TUNNEL_URL=https://your-node-name.tail-net.ts.net
```

Restart n8n to apply changes:

```bash
cd services/n8n && docker-compose restart
```

### 6. Set up the Telegram trigger

1. In n8n, create a new **Telegram Trigger** node.
2. Setup your Bot Credentials (Token key).
3. n8n will automatically register the webhook securely against Telegram's API using the Tailscale HTTPS URL under the hood!

---

## Verification

```bash
# Check Tailscale auth status
tailscale status

# Check active Funnels
tailscale funnel status
```

You can now visit `https://your-node-name.tail-net.ts.net` from your smartphone or any outside network to verify n8n is live and responding securely via TLS.

---

## Persistence

To keep Funnel running securely in the background even if you close the terminal or reboot:

```bash
# Enable Tailscale service on startup
sudo systemctl enable tailscaled

# Deploy the funnel in the background (persistent mapping)
sudo tailscale funnel --bg 5678
```

---

## Notes

- Tailscale Funnel runs natively at the **OS System Level**, not inside a Docker container.
- Your Tailscale URL is statically assigned long-term.
- TLS Certificates are provisioned and renewed fully automated.
- Fully compatible and reachable by any external client natively.
