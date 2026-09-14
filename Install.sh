#!/bin/bash
# FEZIWORLD - One Command Installer
# Official: bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/install.sh)
set -e
RED="\e[31m"; GREEN="\e[32m"; PINK="\e[38;5;213m"; YELLOW="\e[33m"; RESET="\e[0m"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root: sudo bash <(curl -fsSL ...)${RESET}"
  exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/festusagbedeme/feziworld/main"
INSTALL_PATH="/usr/local/bin/feziworld"

echo -e "${PINK}"
echo "  ███████╗███████╗███████╗██╗██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ "
echo "  ██╔════╝██╔════╝╚══███╔╝██║██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗"
echo "  █████╗  █████╗    ███╔╝ ██║██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║"
echo "  ██╔══╝  ██╔══╝   ███╔╝  ██║██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║"
echo "  ██║     ███████╗███████╗██║╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝"
echo -e "${RESET}"
echo -e "${GREEN}Installing FEZIWORLD VPN Manager...${RESET}"

apt-get update -y
apt-get install -y curl wget jq vnstat iproute2 net-tools cron lsof 2>/dev/null || true

echo -e "${YELLOW}-> Downloading core...${RESET}"
mkdir -p /usr/local/bin
mkdir -p /etc/feziworld

# Try GitHub first, fallback to embedded
if curl -fsSL "$REPO_RAW/feziworld.sh" -o /tmp/feziworld.sh; then
  echo "Downloaded from GitHub"
else
  echo "Using local installer payload..."
  # payload will be injected below if GitHub not ready
  cat > /tmp/feziworld.sh <<'CORE_EOF'
#!/bin/bash
# FEZIWORLD - MAIN MENU - Ubuntu VPN Manager v2.0
RESET="\e[0m"; BOLD="\e[1m"; BLUE_LINE="\e[38;5;27m"; PINK="\e[38;5;213m"; YELLOW_LABEL="\e[38;5;222m"; BLUE_VALUE="\e[38;5;75m"; CYAN_MENU="\e[38;5;80m"; RED_EXIT="\e[38;5;203m"; DB_BG="\e[48;5;235m"
get_cpu_load() { awk '{print $1}' /proc/loadavg; }
get_ram() { free -m | awk '/^Mem:/{print $3"/"$2" MB"}'; }
get_disk_usage() { df -h / | awk 'NR==2{print $5}' | tr -d '%'; }
get_total_data() { if command -v vnstat &>/dev/null; then vnstat --oneline 2>/dev/null | awk -F';' '{print $11}' || echo "N/A"; else awk '/eth0|ens|enp/ {rx+=$2; tx+=$10} END {printf "%.2f GB", (rx+tx)/1024/1024/1024}' /proc/net/dev; fi; }
get_ssh_users() { grep -E -c "/bin/bash|/bin/sh" /etc/passwd 2>/dev/null || echo 0; }
get_active_conns() { ss -tun 2>/dev/null | wc -l; }
get_xray_users() { [ -f /usr/local/etc/xray/config.json ] && grep -c '"email"' /usr/local/etc/xray/config.json 2>/dev/null || echo 0; }
get_hysteria_count() { [ -f /etc/hysteria/config.yaml ] && echo 1 || echo 0; }
line() { echo -e "${BLUE_LINE}════════════════════════════════════════════════════════════════════════${RESET}"; }
double_line() { line; line; }
header() {
  clear; echo -e "${DB_BG}"; double_line
  echo -e "          🛡️  ${PINK}${BOLD}FEZIWORLD - MAIN MENU${RESET}${DB_BG}                             "
  double_line; echo -e "${RESET}${DB_BG}"
  CPU=$(get_cpu_load); RAM=$(get_ram); SSHU=$(get_ssh_users); XRAYU=$(get_xray_users); HYST=$(get_hysteria_count); DISK=$(get_disk_usage); TOTAL=$(get_total_data); CONNS=$(get_active_conns)
  printf "${DB_BG}  ${YELLOW_LABEL}%-14s ${BLUE_VALUE}: %-20s ${YELLOW_LABEL}%-15s ${BLUE_VALUE}: %s${RESET}${DB_BG}\n" "CPU Load" "$CPU" "Disk Usage" "${DISK}%"
  printf "${DB_BG}  ${YELLOW_LABEL}%-14s ${BLUE_VALUE}: %-20s ${YELLOW_LABEL}%-15s ${BLUE_VALUE}: %s${RESET}${DB_BG}\n" "RAM Usage" "$RAM" "Total Data" "$TOTAL"
  printf "${DB_BG}  ${YELLOW_LABEL}%-14s ${BLUE_VALUE}: %-20s ${YELLOW_LABEL}%-15s ${BLUE_VALUE}: %s${RESET}${DB_BG}\n" "SSH Users" "$SSHU" "Active Conns" "$CONNS"
  printf "${DB_BG}  ${YELLOW_LABEL}%-14s ${BLUE_VALUE}: %-20s ${YELLOW_LABEL}%-15s ${BLUE_VALUE}: %s${RESET}${DB_BG}\n" "Xray Users" "$XRAYU" "Active Streams" "0"
  printf "${DB_BG}  ${YELLOW_LABEL}%-14s ${BLUE_VALUE}: %-20s ${YELLOW_LABEL}%-15s ${BLUE_VALUE}: %s${RESET}${DB_BG}\n" "Hysteria" "$HYST" "Active HY2" "0"
  echo -e "${RESET}"; line; echo -e "${DB_BG}"
  echo -e "    ${CYAN_MENU}[1] 🔐 SSH & Tunnels${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[2] ⚡ Xray  (VLESS / VMess / Trojan / Reality)${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[3] 🚀 Hysteria 2${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[4] 🛡️  WireGuard${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[5] 📁 FTP${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[6] 📊 Monitoring & Status${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[7] 💾 Backup / Restore / Migrate${RESET}${DB_BG}"
  echo -e "    ${CYAN_MENU}[8] ⚙️  System & Settings${RESET}${DB_BG}"
  echo -e "${RESET}${DB_BG}"; line; echo ""; echo -e "    ${RED_EXIT}[0] Exit${RESET}"; echo -e "  ${YELLOW_LABEL}Select category: ${RESET}\c"
}
ssh_menu() { while true; do clear; line; echo -e "  ${BOLD}SSH Manager - FEZIWORLD${RESET}"; line; echo "[1] Create User"; echo "[2] Delete User"; echo "[3] List Users"; echo "[4] Online"; echo "[0] Back"; echo -n "Select: "; read opt; case $opt in 1) read -p "Username: " u; read -p "Password: " p; read -p "Days [30]: " d; d=${d:-30}; id $u &>/dev/null || useradd -m -s /bin/false $u; echo "$u:$p" | chpasswd; chage -E $(date -d "+$d days" +%Y-%m-%d) $u; echo "✅ $u created"; sleep 2;; 2) read -p "Username: " u; userdel -r $u; echo "Deleted"; sleep 1;; 3) awk -F: '$7!~/nologin|false/{print $1}' /etc/passwd; read -p "Enter...";; 4) who; ss -tunap | grep sshd; read -p "Enter...";; 0) break;; esac; done; }
xray_menu() { while true; do clear; line; echo -e "  ${BOLD}Xray Manager${RESET}"; line; echo "[1] Install Xray"; echo "[2] Add User"; echo "[6] List"; echo "[8] Restart"; echo "[0] Back"; echo -n "Select: "; read opt; case $opt in 1) bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install;; 2) echo "UUID: $(cat /proc/sys/kernel/random/uuid)"; read -p "Enter...";; 6) grep '"email"' /usr/local/etc/xray/config.json 2>/dev/null || echo "No config"; read -p "Enter...";; 8) systemctl restart xray; systemctl status xray --no-pager | head -20;; 0) break;; esac; done; }
hysteria_menu() { bash <(curl -fsSL https://get.hy2.sh/) 2>/dev/null; read -p "Enter..."; }
wireguard_menu() { command -v wg &>/dev/null || apt install wireguard -y; wg show; read -p "Enter..."; }
ftp_menu() { apt install vsftpd -y; systemctl enable --now vsftpd; systemctl status vsftpd --no-pager | head -10; read -p "Enter"; }
monitoring_menu() { echo "CPU: $(get_cpu_load) RAM: $(get_ram) Disk: $(get_disk_usage)%"; ps aux --sort=-%cpu | head -15; ss -tulpn | head -30; read -p "Enter..."; }
backup_menu() { tar -czf /root/feziworld-backup-$(date +%F).tar.gz /usr/local/etc/xray/ /etc/hysteria/ /etc/wireguard/ 2>/dev/null; ls -lh /root/*.tar.gz; read -p "Enter"; }
system_menu() { echo "[1] Update [2] BBR [3] Reboot"; read -p "Select: " s; case $s in 1) apt update && apt upgrade -y;; 2) echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf; echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf; sysctl -p;; 3) reboot;; esac; }
if [ "$EUID" -ne 0 ]; then echo "Run as root: sudo bash $0"; exit 1; fi
for pkg in curl wget jq vnstat; do command -v $pkg &>/dev/null || apt install -y $pkg &>/dev/null; done
while true; do header; read choice; case $choice in 1) ssh_menu;; 2) xray_menu;; 3) hysteria_menu;; 4) wireguard_menu;; 5) ftp_menu;; 6) monitoring_menu;; 7) backup_menu;; 8) system_menu;; 0) clear; echo "FEZIWORLD - Bye!"; exit 0;; *) sleep 1;; esac; done

CORE_EOF
fi

chmod +x /tmp/feziworld.sh
cp /tmp/feziworld.sh $INSTALL_PATH
chmod +x $INSTALL_PATH
cp /tmp/feziworld.sh /root/feziworld.sh

# Create shortcut 'menu' and 'fezi'
ln -sf $INSTALL_PATH /usr/local/bin/menu
ln -sf $INSTALL_PATH /usr/local/bin/fezi

echo ""
echo -e "${GREEN}══════════════════════════════════════════════${RESET}"
echo -e "${GREEN}  FEZIWORLD Installed Successfully!${RESET}"
echo -e "${GREEN}══════════════════════════════════════════════${RESET}"
echo ""
echo -e "  Run with: ${PINK}feziworld${RESET}  or  ${PINK}menu${RESET}  or  ${PINK}fezi${RESET}"
echo ""
echo -e "  File location: /root/feziworld.sh"
echo -e "  Binary: /usr/local/bin/feziworld"
echo ""

# Auto start menu
sleep 1
exec /usr/local/bin/feziworld
