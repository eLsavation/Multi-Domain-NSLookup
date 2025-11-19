# 📡 DNS Monitor CLI

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

**A robust, real-time DNS monitoring tool for DevOps and Sysadmins.**

This script continuously checks the resolution status of multiple domains against multiple DNS servers. It features a live dashboard, smart error detection, automatic log rotation, and instant notifications to Microsoft Teams.

---

## 📸 Dashboard Preview

```text
██████╗ ███╗   ██╗███████╗    ███████╗ ██████╗ █████╗ ███╗   ██╗
██╔══██╗████╗  ██║██╔════╝    ██╔════╝██╔════╝██╔══██╗████╗  ██║
██║  ██║██╔██╗ ██║███████╗    ███████╗██║     ███████║██╔██╗ ██║
██║  ██║██║╚██╗██║╚════██║    ╚════██║██║     ██╔══██║██║╚██╗██║
██████╔╝██║ ╚████║███████║    ███████║╚██████╗██║  ██║██║ ╚████║
╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝

──────────────────────────────────────────────────────────────────
  :: SYSTEM STATUS ::
  ▶ Iteration : #42
  ▶ Servers   : 8.8.8.8 1.1.1.1 10.17.x.x
  ▶ Config    : LIVE (Delay: 1s | Loop: 60s)
──────────────────────────────────────────────────────────────────
  SCAN PROGRESS: 45%
  [█████████████████░░░░░░░░░░░░░░░░░░░░░] (12/27)

  🔎 TARGET DOMAIN: example.com
  --------------------------------------------------
  ✔️ 8.8.8.8     : 93.184.216.34 (24ms)
  ❌ 10.17.x.x   : NXDOMAIN (12ms)
```
## ✨ Key Features

🖥️ Live Dashboard: Glitch-free terminal UI with progress bars and status indicators.

🧠 Smart Regex Parser: Intelligently extracts target IPs and filters out DNS server headers or comments.

⚡ Latency Monitoring: Color-coded latency indicators (Green <300ms, Yellow <1s, Red >1s).

🛡️ Circuit Breaker: Automatically pauses scanning if the internet connection is lost to prevent false alarms.

🔒 Single Instance Lock: Prevents multiple instances from running simultaneously and corrupting logs.

🧹 Auto Log Rotation: Automatically rotates failure logs when they exceed a specified size (default 5MB).

🔔 Teams Integration: Sends formatted JSON notifications to Microsoft Teams Webhooks upon failure.

🛑 Graceful Exit: Handles Ctrl+C signals cleanly without leaving temporary files.

## 🚀 Installation
1. Clone the repository:

```Bash

git clone [https://github.com/username/dns-monitor-cli.git](https://github.com/username/dns-monitor-cli.git)
cd dns-monitor-cli
```

2. Make the script executable:

```Bash
chmod +x dns-check.sh
```

3. Prepare your domain list: Create a file named list-domain.txt and add domains (one per line).

```
google.com
facebook.com
internal-app.local
```
## ⚙️ Configuration
Create a config.env file:
```bash
# config.env

# DNS Servers (Space separated)
SOURCE_SERVERS="8.8.8.8 1.1.1.1 10.x.x.x"

# Paths
DOMAIN_LIST_PATH="./list-domain.txt"
FAILURE_OUTPUT="./failure-lookup.txt"

# Integrations
TEAMS_WEBHOOK_URL="[https://outlook.office.com/webhook/](https://outlook.office.com/webhook/)..."

# Settings
PER_DOMAIN_DELAY="1"    # Delay between domains (seconds)
SCAN_INTERVAL="60"      # Delay between full cycles (seconds)
MAX_LOG_SIZE_MB="5"     # Log rotation limit
```

## 🎮 Usage
Manual Run
```Bash
./dns-check.sh
```
Run in Background (Screen)
```Bash
screen -S dns-monitor ./dns-check.sh
# Ctrl+A, D to detach
```

Run as Service (Systemd)
1. Create ```/etc/systemd/system/dns-monitor.service```
2. Enable: ```sudo systemctl enable --now dns-monitor```

## 📝 Log Format
Failure Log (failure-lookup.txt):

```Plaintext
=========================
ITERATION        : #15
DOMAIN           : broken-domain.com
SOURCE SERVER    : 8.8.8.8
LAST CHECKED     : 2025-01-01 12:00:00
REASON           : NXDOMAIN
=========================
```

## 🤝 Contributing
Contributions are welcome! Please fork the repository and submit a pull request.
