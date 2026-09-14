#!/bin/bash
# FEZIWORLD - One Command Installer
# Official: bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/install.sh)
set -e
RED="\e[31m"; GREEN="\e[32m"; PINK="\e[38;5;213m"; YELLOW="\e[33m"; RESET="\e[0m"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root: sudo bash${RESET}"
  exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/festusagbedeme/feziworld/main"
INSTALL_PATH="/usr/local/bin/feziworld"

echo -e "${PINK}  FEZIWORLD Installer${RESET}"
echo -e "${GREEN}Installing FEZIWORLD VPN Manager...${RESET}"

apt-get update -y
apt-get install -y curl wget jq vnstat iproute2 net-tools cron lsof 2>/dev/null || true

echo -e "${YELLOW}-> Downloading core...${RESET}"
mkdir -p /usr/local/bin
mkdir -p /etc/feziworld

if curl -fsSL "$REPO_RAW/feziworld.sh" -o /tmp/feziworld.sh; then
  echo "Downloaded from GitHub"
else
  echo "GitHub not yet ready, please push files first"
  exit 1
fi

chmod +x /tmp/feziworld.sh
cp /tmp/feziworld.sh $INSTALL_PATH
chmod +x $INSTALL_PATH
cp /tmp/feziworld.sh /root/feziworld.sh

ln -sf $INSTALL_PATH /usr/local/bin/menu
ln -sf $INSTALL_PATH /usr/local/bin/fezi

echo ""
echo -e "${GREEN}  FEZIWORLD Installed Successfully!${RESET}"
echo -e "  Run with: feziworld  or  menu  or  fezi"
echo ""

sleep 1
exec $INSTALL_PATH
