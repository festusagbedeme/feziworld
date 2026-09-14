# 🛡️ FEZIWORLD - Ubuntu VPN Manager

> By **Festus Agbedeme** - https://github.com/festusagbedeme

Powerful Ubuntu VPN Dashboard - Clean TUI like ITZDAJOHN, branded for FEZIWORLD.

## 🚀 One-Command Install (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/install.sh)
```

The installer will:
- Install dependencies (curl, jq, vnstat, etc.)
- Install FEZIWORLD to `/usr/local/bin/feziworld`
- Create shortcuts `menu` and `fezi`
- Auto-launch the dashboard

After install, run anytime:
```bash
feziworld
# or
menu
# or
fezi
```

## 📊 Dashboard Features

```
🛡️ FEZIWORLD - MAIN MENU
CPU Load    : 0.64         Disk Usage   : 18%
RAM Usage   : 944/5899 MB  Total Data   : 154.13 GB
SSH Users   : 3            Active Conns : 10
Xray Users  : 1            Active Streams: 0
Hysteria    : 1            Active HY2   : 0

[1] 🔐 SSH & Tunnels
[2] ⚡ Xray (VLESS / VMess / Trojan / Reality)
[3] 🚀 Hysteria 2
[4] 🛡️ WireGuard
[5] 📁 FTP
[6] 📊 Monitoring & Status
[7] 💾 Backup / Restore / Migrate
[8] ⚙️ System & Settings
```

## 📋 What Each Menu Does

- **[1] SSH & Tunnels**: Create/delete users, set expiry, online check, Dropbear/WS
- **[2] Xray**: Install Xray-core, VLESS/VMess/Trojan/Reality user management
- **[3] Hysteria 2**: One-click install via get.hy2.sh
- **[4] WireGuard**: Install + peer management
- **[5] FTP**: vsftpd setup
- **[6] Monitoring**: htop-like stats, ss -tulpn
- **[7] Backup**: Tar backup to /root/feziworld-backup-*.tar.gz
- **[8] System**: apt upgrade, BBR enable, reboot

## 🛠️ Manual Install

```bash
git clone https://github.com/festusagbedeme/feziworld.git
cd feziworld
chmod +x feziworld.sh
sudo bash feziworld.sh
```

## 📦 Files

- `feziworld.sh` - Main script
- `install.sh` - One-line installer
- `README.md` - This file

## 🔧 Requirements

- Ubuntu 20.04 / 22.04 / 24.04
- Root access (sudo)
- 512MB RAM minimum

## 👑 Author

**Festus Agbedeme (FEZIWORLD)**
GitHub: https://github.com/festusagbedeme
Location: Lagos, Nigeria

## 📄 License

MIT - Free to use and modify.
