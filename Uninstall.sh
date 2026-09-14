#!/bin/bash
# FEZIWORLD Uninstaller - One Command
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/uninstall.sh)
# Or: curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/uninstall.sh | bash

RED="\e[31m"; GREEN="\e[32m"; PINK="\e[38;5;213m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root: sudo bash${RESET}"
  exit 1
fi

clear
echo -e "${PINK}"
echo "  ███████╗███████╗███████╗██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ "
echo "  ██╔════╝██╔════╝╚══███╔╝██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗"
echo "  █████╗  █████╗    ███╔╝ ██║    ██║██║   ██║██████╔╝██║     ██║  ██║"
echo "  ██╔══╝  ██╔══╝   ███╔╝  ██║    ██║██║   ██║██╔══██╗██║     ██║  ██║"
echo "  ██║     ███████╗███████╗██║    ██║╚██████╔╝██║  ██║███████╗██████╔╝"
echo -e "${RESET}"
echo -e "${RED}  ⚠️  FEZIWORLD UNINSTALLER${RESET}"
echo ""
echo -e "${YELLOW}What do you want to remove?${RESET}"
echo -e "  ${GREEN}[1]${RESET} Remove ONLY FEZIWORLD script (keep VPN configs & users) - SAFE"
echo -e "  ${RED}[2]${RESET} FULL UNINSTALL (remove FEZIWORLD + Xray + Hysteria + WireGuard + fezi-* users) - DANGEROUS"
echo -e "  [3] Cancel"
echo ""
read -p "Select [1-3]: " choice

if [[ $choice == "3" || $choice == "0" ]]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo -e "${RED}Are you SURE? Type YES to confirm: ${RESET}"
read -p "> " confirm
if [[ $confirm != "YES" ]]; then
  echo "Cancelled - you must type YES"
  exit 0
fi

echo ""
echo -e "${YELLOW}Uninstalling...${RESET}"

if [[ $choice == "2" ]]; then
  echo "Stopping services..."
  systemctl stop xray 2>/dev/null || true
  systemctl disable xray 2>/dev/null || true
  systemctl stop hysteria-server 2>/dev/null || true
  systemctl stop hysteria-server.service 2>/dev/null || true
  systemctl disable hysteria-server 2>/dev/null || true
  systemctl disable hysteria-server.service 2>/dev/null || true
  wg-quick down wg0 2>/dev/null || true
  systemctl disable wg-quick@wg0 2>/dev/null || true

  echo "Removing VPN configs..."
  rm -rf /usr/local/etc/xray/ 2>/dev/null || true
  rm -rf /etc/hysteria/ 2>/dev/null || true
  rm -rf /etc/wireguard/ 2>/dev/null || true
  rm -f /usr/local/bin/xray 2>/dev/null || true
  rm -f /usr/local/bin/hysteria 2>/dev/null || true
  rm -f /usr/local/etc/xray/ 2>/dev/null || true

  echo "Removing fezi-* users..."
  for user in $(grep "^fezi-" /etc/passwd | cut -d: -f1); do
    userdel -r $user 2>/dev/null && echo "  Deleted $user" || true
  done
fi

echo "Removing FEZIWORLD binaries..."
rm -f /usr/local/bin/feziworld
rm -f /usr/local/bin/menu
rm -f /usr/local/bin/fezi
rm -f /usr/local/bin/feziworld.sh
rm -f /root/feziworld.sh
rm -f /tmp/feziworld.sh
rm -f /usr/local/bin/feziworld-backups -rf 2>/dev/null || true

if [[ $choice == "2" ]]; then
  echo "Removing FEZIWORLD data..."
  rm -rf /etc/feziworld/
  rm -f /var/log/feziworld.log
  rm -rf /root/feziworld-backups/
else
  echo "Keeping configs in /etc/feziworld/ (use Full uninstall to remove)"
fi

echo ""
echo -e "${GREEN}✅ FEZIWORLD uninstalled!${RESET}"
echo ""
if [[ $choice == "1" ]]; then
  echo "Kept: Xray, Hysteria, WireGuard configs and users"
else
  echo "Removed: Everything"
fi
echo ""
echo "To reinstall:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/install.sh)"
echo ""
