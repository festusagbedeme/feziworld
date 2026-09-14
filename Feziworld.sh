#!/bin/bash
# ==============================================================================
# FEZIWORLD PRO v4.0 - Interactive Setup Wizard Edition
# Author: Festus Agbedeme (https://github.com/festusagbedeme)
# Repo: https://github.com/festusagbedeme/feziworld
# Feature: Now ASKS for IP / Domain / URL for EACH protocol during setup
# ==============================================================================

set -e
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  echo -e "\e[31m[!] Run as root: sudo bash feziworld.sh\e[0m"
  exit 1
fi

VERSION="4.0-INTERACTIVE"
DATA_DIR="/etc/feziworld"
CONFIG_FILE="$DATA_DIR/config.env"
USER_DB="$DATA_DIR/users.db"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HY_CONFIG="/etc/hysteria/config.yaml"
WG_DIR="/etc/wireguard"
BACKUP_DIR="/root/feziworld-backups"
LOG_FILE="/var/log/feziworld.log"

mkdir -p $DATA_DIR $BACKUP_DIR $WG_DIR
touch $USER_DB $LOG_FILE
chmod 600 $USER_DB 2>/dev/null || true

# Colors
R="\e[0m"; B="\e[1m"; DIM="\e[2m"
BLUE="\e[38;5;27m"; PINK="\e[38;5;213m"; YL="\e[38;5;222m"; BV="\e[38;5;75m"
CY="\e[38;5;80m"; RD="\e[38;5;203m"; GN="\e[38;5;84m"; GR="\e[38;5;245m"
BG="\e[48;5;235m"

log() { echo "[$(date '+%F %T')] $*" >> $LOG_FILE; }
pause() { echo -e "\n${GR}Press Enter to continue...${R}"; read -r; }
is_installed() { command -v "$1" &>/dev/null; }
auto_ip() { curl -fsSL4 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo ""; }
gen_uuid() { cat /proc/sys/kernel/random/uuid; }
gen_pass() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16; }

# --- Config Load / Save ---
load_config() {
  if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
  fi
  # defaults if not set
  SERVER_IP=${SERVER_IP:-$(auto_ip)}
  DOMAIN=${DOMAIN:-""}
  REALITY_SNI=${REALITY_SNI:-"www.microsoft.com"}
  REALITY_DEST=${REALITY_DEST:-"www.microsoft.com:443"}
  REALITY_PORT=${REALITY_PORT:-"443"}
  REALITY_SHORTID=${REALITY_SHORTID:-""}
  VMESS_DOMAIN=${VMESS_DOMAIN:-"${DOMAIN:-$SERVER_IP}"}
  VMESS_PORT=${VMESS_PORT:-"8443"}
  VMESS_PATH=${VMESS_PATH:-"/vmess"}
  VMESS_SNI=${VMESS_SNI:-"${DOMAIN:-$SERVER_IP}"}
  TROJAN_DOMAIN=${TROJAN_DOMAIN:-"${DOMAIN:-$SERVER_IP}"}
  TROJAN_PORT=${TROJAN_PORT:-"8444"}
  TROJAN_SNI=${TROJAN_SNI:-"${DOMAIN:-$SERVER_IP}"}
  HY_DOMAIN=${HY_DOMAIN:-"${DOMAIN:-$SERVER_IP}"}
  HY_PORT=${HY_PORT:-"4443"}
  WG_ENDPOINT=${WG_ENDPOINT:-"$SERVER_IP:51820"}
  SSH_DOMAIN=${SSH_DOMAIN:-"$SERVER_IP"}
  SSH_PORT=${SSH_PORT:-"22"}
}

save_config() {
  cat > $CONFIG_FILE <<EOF
# FEZIWORLD Config - Generated $(date)
SERVER_IP="$SERVER_IP"
DOMAIN="$DOMAIN"
REALITY_SNI="$REALITY_SNI"
REALITY_DEST="$REALITY_DEST"
REALITY_PORT="$REALITY_PORT"
REALITY_SHORTID="$REALITY_SHORTID"
VMESS_DOMAIN="$VMESS_DOMAIN"
VMESS_PORT="$VMESS_PORT"
VMESS_PATH="$VMESS_PATH"
VMESS_SNI="$VMESS_SNI"
TROJAN_DOMAIN="$TROJAN_DOMAIN"
TROJAN_PORT="$TROJAN_PORT"
TROJAN_SNI="$TROJAN_SNI"
HY_DOMAIN="$HY_DOMAIN"
HY_PORT="$HY_PORT"
WG_ENDPOINT="$WG_ENDPOINT"
SSH_DOMAIN="$SSH_DOMAIN"
SSH_PORT="$SSH_PORT"
EOF
  chmod 600 $CONFIG_FILE
}

# --- Interactive Setup Wizard ---
setup_wizard() {
  clear
  echo -e "${PINK}${B}"
  echo "  ███████╗███████╗███████╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗     SETUP"
  echo "  ██╔════╝██╔════╝╚══███╔╝██║   ██║██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗"
  echo "  █████╗  █████╗    ███╔╝ ██║   ██║██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║"
  echo -e "${R}"
  echo -e "${YL}  First time setup - We will ask for IP / Domain / URL for EACH protocol${R}"
  echo -e "${GR}  You can re-run this anytime from System & Settings -> [9] Setup Wizard${R}"
  line
  echo ""

  # --- Server IP ---
  DETECTED_IP=$(auto_ip)
  echo -e "${B}Step 1/7: Server IP${R} (for all protocols)"
  read -p "  Enter Server IP [detected: $DETECTED_IP]: " inp
  SERVER_IP=${inp:-$DETECTED_IP}
  echo -e "${GN}  -> Using IP: $SERVER_IP${R}\n"

  # --- Domain ---
  echo -e "${B}Step 2/7: Main Domain (optional but recommended for TLS)${R}"
  echo -e "${GR}  If you have a domain pointed to $SERVER_IP, enter it. Leave empty to use IP.${R}"
  read -p "  Enter Domain (e.g. vpn.feziworld.com) [empty=use IP]: " inp
  DOMAIN=${inp:-""}
  [[ -z $DOMAIN ]] && DOMAIN=$SERVER_IP
  echo -e "${GN}  -> Using Domain: $DOMAIN${R}\n"

  # --- VLESS Reality ---
  echo -e "${B}Step 3/7: VLESS + Reality (TCP)${R} - Most powerful, bypasses DPI"
  read -p "  Reality Port [443]: " inp; REALITY_PORT=${inp:-443}
  read -p "  Reality SNI (fake domain) [www.microsoft.com]: " inp; REALITY_SNI=${inp:-www.microsoft.com}
  read -p "  Reality Dest (real site) [www.microsoft.com:443]: " inp; REALITY_DEST=${inp:-www.microsoft.com:443}
  read -p "  Short ID (empty=auto): " inp; REALITY_SHORTID=${inp:-$(tr -dc '0-9a-f' </dev/urandom | head -c 8)}
  echo -e "${GN}  -> VLESS Reality will use: $SERVER_IP:$REALITY_PORT SNI=$REALITY_SNI Dest=$REALITY_DEST${R}\n"

  # --- VMess WS ---
  echo -e "${B}Step 4/7: VMess + WebSocket + TLS${R} - Good for CDN / Cloudflare"
  read -p "  VMess Domain / Host [$DOMAIN]: " inp; VMESS_DOMAIN=${inp:-$DOMAIN}
  read -p "  VMess Port [8443]: " inp; VMESS_PORT=${inp:-8443}
  read -p "  VMess WS Path [/vmess]: " inp; VMESS_PATH=${inp:-/vmess}
  read -p "  VMess SNI / TLS Server Name [$VMESS_DOMAIN]: " inp; VMESS_SNI=${inp:-$VMESS_DOMAIN}
  echo -e "${GN}  -> VMess WS: $VMESS_DOMAIN:$VMESS_PORT Path=$VMESS_PATH${R}\n"

  # --- Trojan ---
  echo -e "${B}Step 5/7: Trojan (TLS)${R}"
  read -p "  Trojan Domain [$DOMAIN]: " inp; TROJAN_DOMAIN=${inp:-$DOMAIN}
  read -p "  Trojan Port [8444]: " inp; TROJAN_PORT=${inp:-8444}
  read -p "  Trojan SNI [$TROJAN_DOMAIN]: " inp; TROJAN_SNI=${inp:-$TROJAN_DOMAIN}
  echo -e "${GN}  -> Trojan: $TROJAN_DOMAIN:$TROJAN_PORT${R}\n"

  # --- Hysteria 2 ---
  echo -e "${B}Step 6/7: Hysteria 2 (UDP Brutal)${R} - Fastest for lossy networks"
  read -p "  Hysteria Domain / IP [$DOMAIN]: " inp; HY_DOMAIN=${inp:-$DOMAIN}
  read -p "  Hysteria Port [4443]: " inp; HY_PORT=${inp:-4443}
  echo -e "${GN}  -> Hysteria2: $HY_DOMAIN:$HY_PORT${R}\n"

  # --- WireGuard & SSH ---
  echo -e "${B}Step 7/7: WireGuard & SSH${R}"
  read -p "  WireGuard Endpoint (IP:Port) [$SERVER_IP:51820]: " inp; WG_ENDPOINT=${inp:-$SERVER_IP:51820}
  read -p "  SSH Host / IP [$SERVER_IP]: " inp; SSH_DOMAIN=${inp:-$SERVER_IP}
  read -p "  SSH Port [22]: " inp; SSH_PORT=${inp:-22}
  echo -e "${GN}  -> WG: $WG_ENDPOINT | SSH: $SSH_DOMAIN:$SSH_PORT${R}\n"

  save_config
  echo -e "${BG}${GN}${B}  ✅ Setup saved to $CONFIG_FILE ${R}${BG}"
  echo -e "${GR}  You can edit it anytime: nano $CONFIG_FILE${R}"
  echo ""
  echo -e "${YL}Summary:${R}"
  cat $CONFIG_FILE
  pause
}

# --- Stats ---
get_cpu() { awk '{print $1}' /proc/loadavg; }
get_ram() { free -m | awk '/^Mem:/{printf "%d/%d MB (%.0f%%)", $3,$2,$3*100/$2}'; }
get_disk() { df -h / | awk 'NR==2{print $3" / "$2" ("$5")"}'; }
get_uptime() { uptime -p | sed 's/up //'; }
get_total_data() { is_installed vnstat && vnstat --oneline 2>/dev/null | awk -F';' '{print $11}' || echo "N/A"; }
get_ssh_count() { grep -c "fezi-" /etc/passwd 2>/dev/null || echo 0; }
get_ssh_online() { who | wc -l; }
get_xray_count() { [[ -f $XRAY_CONFIG ]] && jq '.inbounds[].settings.clients | length' $XRAY_CONFIG 2>/dev/null | awk '{s+=$1} END{print s+0}' || echo 0; }
get_active_conns() { ss -tun 2>/dev/null | wc -l; }
get_hy_count() { [[ -f $HY_CONFIG ]] && echo 1 || echo 0; }

line() { echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${R}"; }
dline() { line; line; }

header() {
  clear
  load_config
  IP=$SERVER_IP
  CPU=$(get_cpu); RAM=$(get_ram); DISK=$(get_disk)
  UP=$(get_uptime); TOTAL=$(get_total_data)
  SSHC=$(get_ssh_count); SSHON=$(get_ssh_online)
  XRAYC=$(get_xray_count); CONN=$(get_active_conns); HY=$(get_hy_count)

  echo -e "${BG}"; dline
  echo -e "          🛡️  ${PINK}${B}FEZIWORLD PRO v${VERSION}${R}${BG}                     ${GR}${IP} | ${DOMAIN}${R}${BG}"
  dline; echo -e "${R}${BG}"
  printf "${BG}  ${YL}%-14s ${BV}: %-26s ${YL}%-14s ${BV}: %s${R}${BG}\n" "CPU Load" "$CPU" "Disk Usage" "$DISK"
  printf "${BG}  ${YL}%-14s ${BV}: %-26s ${YL}%-14s ${BV}: %s${R}${BG}\n" "RAM Usage" "$RAM" "Total Data" "$TOTAL"
  printf "${BG}  ${YL}%-14s ${BV}: %-26s ${YL}%-14s ${BV}: %s${R}${BG}\n" "SSH Users" "$SSHC ($SSHON online)" "Active Conns" "$CONN"
  printf "${BG}  ${YL}%-14s ${BV}: %-26s ${YL}%-14s ${BV}: %s${R}${BG}\n" "Xray Users" "$XRAYC" "Active Streams" "0"
  printf "${BG}  ${YL}%-14s ${BV}: %-26s ${YL}%-14s ${BV}: %s${R}${BG}\n" "Hysteria" "$HY" "Active HY2" "0"
  printf "${BG}  ${YL}%-14s ${BV}: %-26s ${YL}%-14s ${BV}: %s${R}${BG}\n" "Uptime" "$UP" "Config" "$(basename $CONFIG_FILE)"
  echo -e "${R}"; line; echo -e "${BG}"
  echo -e "    ${CY}[1] 🔐 SSH & Tunnels (Dropbear / WS / SSL)${R}${BG}"
  echo -e "    ${CY}[2] ⚡ Xray Core (VLESS / VMess / Trojan / Reality)${R}${BG}"
  echo -e "    ${CY}[3] 🚀 Hysteria 2 (UDP / Brutal)${R}${BG}"
  echo -e "    ${CY}[4] 🛡️  WireGuard VPN${R}${BG}"
  echo -e "    ${CY}[5] 📁 FTP / SFTP Management${R}${BG}"
  echo -e "    ${CY}[6] 📊 Monitoring & Real-time Status${R}${BG}"
  echo -e "    ${CY}[7] 💾 Backup / Restore / Migrate${R}${BG}"
  echo -e "    ${CY}[8] ⚙️  System & Security (BBR, Firewall, SWAP)${R}${BG}"
  echo -e "${R}${BG}"; line; echo ""; echo -e "    ${RD}[0] Exit${R}"; echo -e "  ${YL}Select category: ${R}\c"
}

# ==================== SSH MANAGER ====================
ssh_manager() {
  load_config
  while true; do
    clear; line; echo -e "  ${B}🔐 SSH Manager - FEZIWORLD PRO${R}"; line
    echo -e "  Current SSH Host: ${GN}$SSH_DOMAIN:$SSH_PORT${R} (from setup)"
    echo -e "  ${GN}[1]${R} Create SSH User"
    echo -e "  ${GN}[2]${R} Create Trial (1-day)"
    echo -e "  ${GN}[3]${R} Delete User"
    echo -e "  ${GN}[4]${R} List Users (detailed)"
    echo -e "  ${GN}[5]${R} Check Online"
    echo -e "  ${GN}[6]${R} Renew User"
    echo -e "  ${GN}[7]${R} Change SSH Host/IP (re-ask)"
    echo -e "  ${RD}[0] Back${R}"
    echo -n "  Select: "; read -r opt
    case $opt in
      1)
        read -p "  Username (prefix fezi- auto): " u; u="fezi-$u"
        if id "$u" &>/dev/null; then echo -e "${RD}Exists!${R}"; pause; continue; fi
        read -p "  Password (empty=random): " p; [[ -z $p ]] && p=$(gen_pass) && echo "  Generated: $p"
        read -p "  Expire days [30]: " d; d=${d:-30}
        # Ask for IP for this user (allow override)
        read -p "  Use Host [$SSH_DOMAIN]: " host; host=${host:-$SSH_DOMAIN}
        read -p "  Use Port [$SSH_PORT]: " port; port=${port:-$SSH_PORT}
        useradd -m -s /bin/false -e $(date -d "+$d days" +%Y-%m-%d) "$u"
        echo "$u:$p" | chpasswd
        echo "$u|$p|$(date +%F)|$(date -d "+$d days" +%F)|$host:$port" >> $USER_DB
        log "CREATE SSH $u $host:$port"
        echo -e "\n${GN}✅ Created:${R}\n  Host: $host:$port\n  User: $u\n  Pass: $p\n  Exp: $(date -d "+$d days" +%F)"
        pause
        ;;
      2) u="fezi-trial-$(shuf -i 1000-9999 -n 1)"; p=$(gen_pass); useradd -m -s /bin/false -e $(date -d "+1 days" +%Y-%m-%d) "$u"; echo "$u:$p" | chpasswd; echo -e "${GN}Trial: $u / $p @ $SSH_DOMAIN:$SSH_PORT${R}"; pause;;
      3) read -p "  Username to delete: " u; userdel -r "$u" 2>/dev/null; sed -i "/^$u|/d" $USER_DB; echo "Deleted"; pause;;
      4) cat $USER_DB 2>/dev/null | column -t -s '|' || echo "No users yet"; pause;;
      5) who; ss -tunap | grep sshd; pause;;
      6) read -p "  Username to renew: " u; read -p "  Add days [30]: " d; d=${d:-30}; chage -E $(date -d "+$d days" +%Y-%m-%d) "$u" && echo "Extended" || echo "Not found"; pause;;
      7)
        read -p "  New SSH Host/IP [$SSH_DOMAIN]: " inp; SSH_DOMAIN=${inp:-$SSH_DOMAIN}
        read -p "  New SSH Port [$SSH_PORT]: " inp; SSH_PORT=${inp:-$SSH_PORT}
        save_config; echo "Saved"; pause
        ;;
      0) break;;
    esac
  done
}

# ==================== XRAY MANAGER WITH PROMPTS ====================
ensure_xray_config() {
  if [[ ! -f $XRAY_CONFIG ]]; then
    mkdir -p $(dirname $XRAY_CONFIG)
    cat > $XRAY_CONFIG <<'XJSON'
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {"port": 443, "protocol": "vless", "settings": {"clients": [], "decryption": "none"}, "streamSettings": {"network": "tcp", "security": "reality", "realitySettings": {"show": false, "dest": "www.microsoft.com:443", "xver": 0, "serverNames": ["www.microsoft.com"], "privateKey": "", "shortIds": [""]}}},
    {"port": 8443, "protocol": "vmess", "settings": {"clients": []}, "streamSettings": {"network": "ws", "security": "tls"}},
    {"port": 8444, "protocol": "trojan", "settings": {"clients": []}, "streamSettings": {"network": "tcp", "security": "tls"}}
  ],
  "outbounds": [{"protocol": "freedom"}]
}
XJSON
  fi
}

xray_manager() {
  load_config; ensure_xray_config
  while true; do
    clear; line; echo -e "  ${B}⚡ Xray Manager - FEZIWORLD PRO${R}"; line
    echo -e "  Current Config: IP=${GN}$SERVER_IP${R} Domain=${GN}$DOMAIN${R}"
    echo -e "  Reality: ${GN}$REALITY_SNI -> $REALITY_DEST : $REALITY_PORT${R}"
    echo -e "  VMess: ${GN}$VMESS_DOMAIN:$VMESS_PORT Path $VMESS_PATH${R}"
    echo -e "  Trojan: ${GN}$TROJAN_DOMAIN:$TROJAN_PORT${R}"
    echo ""
    echo -e "  ${GN}[1]${R} Install / Update Xray-core"
    echo -e "  ${GN}[2]${R} Add VLESS Reality User (ask IP/URL/SNI)"
    echo -e "  ${GN}[3]${R} Add VMess WS User (ask Domain/Path/Port)"
    echo -e "  ${GN}[4]${R} Add Trojan User (ask Domain/Port)"
    echo -e "  ${GN}[5]${R} Add VLESS Vision Reality (ask all)"
    echo -e "  ${GN}[6]${R} List Users"
    echo -e "  ${GN}[7]${R} Delete User"
    echo -e "  ${GN}[8]${R} Re-configure IPs/URLs for protocols (setup wizard)"
    echo -e "  ${GN}[9]${R} Show Config + Generate Reality Keys"
    echo -e "  ${GN}[10]${R} Restart Xray"
    echo -e "  ${RD}[0] Back${R}"
    echo -n "  Select: "; read -r opt
    case $opt in
      1) bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install; systemctl enable xray; pause;;
      2)
        echo -e "${YL}-- VLESS Reality User Creation --${R}"
        read -p "  Username/Email: " email; email=${email:-user-$(date +%s)}
        read -p "  Use IP/Host [$SERVER_IP]: " use_ip; use_ip=${use_ip:-$SERVER_IP}
        read -p "  Use Port [$REALITY_PORT]: " use_port; use_port=${use_port:-$REALITY_PORT}
        read -p "  SNI [$REALITY_SNI]: " use_sni; use_sni=${use_sni:-$REALITY_SNI}
        read -p "  Dest [$REALITY_DEST]: " use_dest; use_dest=${use_dest:-$REALITY_DEST}
        uuid=$(gen_uuid)
        tmp=$(mktemp); jq --arg em "$email" --arg id "$uuid" '.inbounds[0].settings.clients += [{"id": $id, "email": $em, "flow": "xtls-rprx-vision"}]' $XRAY_CONFIG > $tmp && mv $tmp $XRAY_CONFIG
        systemctl restart xray 2>/dev/null || true
        echo -e "\n${GN}✅ VLESS Reality Created${R}"
        echo -e "${CY}vless://$uuid@$use_ip:$use_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$use_sni&fp=chrome&pbk=YOUR_PUBLIC_KEY&sid=$REALITY_SHORTID&type=tcp#${email}-FEZIWORLD${R}"
        echo -e "${GR}  Note: Replace YOUR_PUBLIC_KEY with output from 'xray x25519' and set privateKey in config${R}"
        log "XRAY VLESS $email $use_ip:$use_port"
        pause
        ;;
      3)
        echo -e "${YL}-- VMess WS User Creation --${R}"
        read -p "  Username: " email; email=${email:-user-$(date +%s)}
        read -p "  VMess Domain [$VMESS_DOMAIN]: " d; d=${d:-$VMESS_DOMAIN}
        read -p "  Port [$VMESS_PORT]: " p; p=${p:-$VMESS_PORT}
        read -p "  WS Path [$VMESS_PATH]: " path; path=${path:-$VMESS_PATH}
        read -p "  SNI/TLS Host [$VMESS_SNI]: " sni; sni=${sni:-$VMESS_SNI}
        uuid=$(gen_uuid)
        tmp=$(mktemp); jq --arg em "$email" --arg id "$uuid" '.inbounds[1].settings.clients += [{"id": $id, "email": $em}]' $XRAY_CONFIG > $tmp && mv $tmp $XRAY_CONFIG
        systemctl restart xray 2>/dev/null || true
        vmess_json="{\"v\":\"2\",\"ps\":\"$email-FEZIWORLD\",\"add\":\"$d\",\"port\":\"$p\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$sni\",\"path\":\"$path\",\"tls\":\"tls\",\"sni\":\"$sni\"}"
        link=$(echo "$vmess_json" | base64 -w 0 | sed 's/^/vmess:\/\//')
        echo -e "${GN}✅ VMess Created${R}\n$link"
        pause
        ;;
      4)
        echo -e "${YL}-- Trojan User --${R}"
        read -p "  Username: " email; email=${email:-user-$(date +%s)}
        read -p "  Trojan Domain [$TROJAN_DOMAIN]: " d; d=${d:-$TROJAN_DOMAIN}
        read -p "  Port [$TROJAN_PORT]: " p; p=${p:-$TROJAN_PORT}
        read -p "  SNI [$TROJAN_SNI]: " sni; sni=${sni:-$TROJAN_SNI}
        pass=$(gen_pass)
        tmp=$(mktemp); jq --arg em "$email" --arg pw "$pass" '.inbounds[2].settings.clients += [{"password": $pw, "email": $em}]' $XRAY_CONFIG > $tmp && mv $tmp $XRAY_CONFIG
        systemctl restart xray 2>/dev/null || true
        echo -e "${GN}✅ Trojan Created${R}"
        echo -e "${CY}trojan://$pass@$d:$p?sni=$sni#${email}-FEZIWORLD${R}"
        pause
        ;;
      5) # same as 2 but asks all again
        echo -e "${YL}-- VLESS Vision Reality (full custom) --${R}"
        read -p "  Username: " email; email=${email:-user-$(date +%s)}
        read -p "  IP [$SERVER_IP]: " ip; ip=${ip:-$SERVER_IP}
        read -p "  Port [443]: " port; port=${port:-443}
        read -p "  SNI [www.microsoft.com]: " sni; sni=${sni:-www.microsoft.com}
        read -p "  Dest [www.microsoft.com:443]: " dest; dest=${dest:-www.microsoft.com:443}
        uuid=$(gen_uuid)
        tmp=$(mktemp); jq --arg em "$email" --arg id "$uuid" '.inbounds[0].settings.clients += [{"id": $id, "email": $em, "flow": "xtls-rprx-vision"}]' $XRAY_CONFIG > $tmp && mv $tmp $XRAY_CONFIG
        systemctl restart xray 2>/dev/null || true
        echo -e "${CY}vless://$uuid@$ip:$port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$sni&type=tcp#${email}${R}"
        pause
        ;;
      6) jq -r '.inbounds[] | "\(.protocol) (\(.port)) -> \(.settings.clients[]?.email // "none")"' $XRAY_CONFIG 2>/dev/null || cat $XRAY_CONFIG | grep email; pause;;
      7) read -p "  Email to delete: " del; tmp=$(mktemp); jq --arg em "$del" '(.inbounds[].settings.clients) |= map(select(.email != $em))' $XRAY_CONFIG > $tmp && mv $tmp $XRAY_CONFIG; systemctl restart xray; echo "Deleted"; pause;;
      8) setup_wizard; pause;;
      9) cat $XRAY_CONFIG | head -n 120; echo ""; echo "Reality keys:"; xray x25519 2>/dev/null || echo "Install xray first"; pause;;
      10) systemctl restart xray; systemctl status xray --no-pager | head -30; pause;;
      0) break;;
    esac
  done
}

hysteria_manager() {
  load_config
  clear; line; echo -e "  Hysteria 2 Manager - Current: $HY_DOMAIN:$HY_PORT"; line
  if [[ ! -f /usr/local/bin/hysteria ]]; then echo "Installing..."; bash <(curl -fsSL https://get.hy2.sh/); fi
  echo "[1] Create new config (ask IP/Domain/Port) [2] Show config"; read -p "Select: " s
  if [[ $s == "1" ]]; then
    read -p "  Hysteria Domain/IP [$HY_DOMAIN]: " d; d=${d:-$HY_DOMAIN}
    read -p "  Port [$HY_PORT]: " p; p=${p:-$HY_PORT}
    HY_DOMAIN=$d; HY_PORT=$p; save_config
    pass=$(gen_pass); mkdir -p /etc/hysteria
    cat > $HY_CONFIG <<EOF
listen: :$p
tls:
  cert: /etc/hysteria/cert.crt
  key: /etc/hysteria/key.key
auth:
  type: password
  password: $pass
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF
    echo -e "${GN}Link: hy2://$pass@$d:$p/?insecure=1#FEZIWORLD-HY2${R}"
  fi
  cat $HY_CONFIG 2>/dev/null; systemctl restart hysteria-server 2>/dev/null || true; pause
}

wireguard_manager() {
  load_config
  clear; line; echo -e "  WireGuard - Current Endpoint: $WG_ENDPOINT"; line
  is_installed wg || apt-get install -y wireguard
  wg show 2>/dev/null || echo "No WG up"
  echo "[1] Create wg0 [2] Add peer (ask endpoint) [3] Change endpoint"; read -p "Select: " w
  case $w in
    1)
      read -p "  Endpoint IP:Port for clients [$WG_ENDPOINT]: " ep; ep=${ep:-$WG_ENDPOINT}
      WG_ENDPOINT=$ep; save_config
      priv=$(wg genkey); pub=$(echo $priv | wg pubkey)
      cat > $WG_DIR/wg0.conf <<EOF
[Interface]
PrivateKey = $priv
Address = 10.7.0.1/24
ListenPort = $(echo $ep | cut -d: -f2)
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
      chmod 600 $WG_DIR/wg0.conf; wg-quick up wg0 && systemctl enable wg-quick@wg0; echo "WG Pub: $pub Endpoint: $ep"
      ;;
    2) read -p "Peer name: " pn; read -p "Endpoint [$WG_ENDPOINT]: " ep; ep=${ep:-$WG_ENDPOINT}; echo "Creating peer $pn for $ep"; ppriv=$(wg genkey); ppub=$(echo $ppriv | wg pubkey); echo "Priv: $ppriv Pub: $ppub";;
    3) read -p "  New Endpoint [$WG_ENDPOINT]: " ep; WG_ENDPOINT=${ep:-$WG_ENDPOINT}; save_config; echo "Saved";;
  esac
  pause
}


uninstall_manager() {
  clear; line
  echo -e "  ${B}${RD}⚠️  UNINSTALL FEZIWORLD${R}"
  line
  echo -e "  This will remove FEZIWORLD from this server."
  echo ""
  echo -e "  ${YL}What do you want to remove?${R}"
  echo -e "  ${GN}[1]${R} Remove ONLY FEZIWORLD script (keep VPN configs, users, Xray, Hysteria, WireGuard)"
  echo -e "  ${RD}[2]${R} FULL UNINSTALL (remove FEZIWORLD + Xray + Hysteria + WireGuard configs + fezi-* users)"
  echo -e "  ${GR}[3]${R} Cancel"
  echo ""
  read -p "  Select [1-3]: " uchoice

  if [[ $uchoice == "3" || $uchoice == "0" ]]; then
    echo "Cancelled"; pause; return
  fi

  echo ""
  echo -e "${RD}  Are you SURE? This cannot be undone!${R}"
  read -p "  Type YES to confirm: " confirm
  if [[ $confirm != "YES" ]]; then
    echo "Cancelled - you must type YES"; pause; return
  fi

  echo -e "${YL}  Uninstalling...${R}"

  # Stop services if full
  if [[ $uchoice == "2" ]]; then
    echo "  Stopping services..."
    systemctl stop xray 2>/dev/null || true
    systemctl disable xray 2>/dev/null || true
    systemctl stop hysteria-server 2>/dev/null || true
    systemctl stop hysteria-server.service 2>/dev/null || true
    systemctl disable hysteria-server 2>/dev/null || true
    systemctl disable hysteria-server.service 2>/dev/null || true
    wg-quick down wg0 2>/dev/null || true
    systemctl disable wg-quick@wg0 2>/dev/null || true

    echo "  Removing VPN configs..."
    rm -rf /usr/local/etc/xray/ 2>/dev/null || true
    rm -rf /etc/hysteria/ 2>/dev/null || true
    rm -rf /etc/wireguard/ 2>/dev/null || true
    rm -rf /usr/local/bin/xray 2>/dev/null || true
    rm -rf /usr/local/bin/hysteria 2>/dev/null || true
    rm -f /usr/local/bin/hy2 2>/dev/null || true

    echo "  Removing fezi-* users..."
    for user in $(grep -o "^fezi-[^:]*" /etc/passwd 2>/dev/null); do
      userdel -r $user 2>/dev/null || true
      echo "    Deleted $user"
    done
  fi

  echo "  Removing FEZIWORLD binaries..."
  rm -f /usr/local/bin/feziworld /usr/local/bin/menu /usr/local/bin/fezi /usr/local/bin/feziworld.sh
  rm -f /root/feziworld.sh /root/feziworld-backups -rf 2>/dev/null || true
  rm -f /tmp/feziworld.sh /tmp/feziworld.sh.*

  if [[ $uchoice == "2" ]]; then
    echo "  Removing FEZIWORLD data..."
    rm -rf /etc/feziworld/
    rm -f /var/log/feziworld.log
    rm -rf /root/feziworld-backups/
  else
    echo "  Keeping configs in /etc/feziworld/ (use Full uninstall to remove)"
  fi

  echo ""
  echo -e "${GN}${B}  ✅ FEZIWORLD uninstalled!${R}"
  if [[ $uchoice == "1" ]]; then
    echo -e "  Kept: Xray, Hysteria, WireGuard configs and users"
  else
    echo -e "  Removed: Everything including VPN configs and users"
  fi
  echo ""
  echo -e "  To reinstall: bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/install.sh)"
  echo ""
  exit 0
}


ftp_manager() { clear; apt-get install -y vsftpd 2>/dev/null; systemctl enable --now vsftpd; systemctl status vsftpd --no-pager | head -20; pause; }
monitoring_manager() { clear; load_config; echo "IP: $SERVER_IP Domain: $DOMAIN"; ps aux --sort=-%cpu | head -15; ss -tulpn | head -30; pause; }
backup_manager() { clear; fname="feziworld-backup-$(date +%F-%H%M).tar.gz"; tar -czf $BACKUP_DIR/$fname /usr/local/etc/xray/ $DATA_DIR $WG_DIR /etc/hysteria/ 2>/dev/null; ls -lh $BACKUP_DIR/$fname; pause; }
system_manager() {
  while true; do
    clear; line; echo -e "  System & Security"; line
    echo "[1] Update [2] BBR [3] Firewall [4] SWAP [5] Timezone [6] Change Banner [7] Re-run Setup Wizard [8] Show Config [9] UNINSTALL FEZIWORLD [0] Back"
    read -p "Select: " s
    case $s in
      1) apt-get update -y && apt-get upgrade -y;;
      2) echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf; echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf; sysctl -p; pause;;
      3) apt-get install -y ufw fail2ban; ufw allow 22,80,443,109,143,8443,8444/tcp; ufw --force enable; pause;;
      4) fallocate -l 2G /swapfile; chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile; echo "/swapfile none swap sw 0 0" >> /etc/fstab; pause;;
      5) dpkg-reconfigure tzdata;;
      6) read -p "New Banner: " nb; sed -i "s/FEZIWORLD/$nb/g" $0; exit;;
      7) setup_wizard;;
      8) cat $CONFIG_FILE; pause;;
      9) uninstall_manager;;
      0) break;;
    esac
  done
}

# --- First run detection ---
for pkg in curl wget jq vnstat iproute2 net-tools lsof cron; do is_installed $pkg || apt-get install -y $pkg &>/dev/null; done

if [[ ! -f $CONFIG_FILE ]]; then
  echo -e "${YL}First run detected - launching setup wizard...${R}"
  sleep 1
  setup_wizard
else
  load_config
fi

# --- Main Loop ---
while true; do
  header
  read -r choice
  case $choice in
    1) ssh_manager;;
    2) xray_manager;;
    3) hysteria_manager;;
    4) wireguard_manager;;
    5) ftp_manager;;
    6) monitoring_manager;;
    7) backup_manager;;
    8) system_manager;;
    9) uninstall_manager;;
    0) clear; echo -e "${PINK}FEZIWORLD PRO v$VERSION - Bye!${R}"; exit 0;;
    *) sleep 0.5;;
  esac
done
