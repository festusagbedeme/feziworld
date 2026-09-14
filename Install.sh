#!/bin/bash
# FEZIWORLD PRO v4.0 - Interactive Edition Installer
# bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/install.sh)
set -e
RED="\e[31m"; GREEN="\e[32m"; PINK="\e[38;5;213m"; YELLOW="\e[33m"; RESET="\e[0m"

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Run as root${RESET}"; exit 1; fi

REPO_RAW="https://raw.githubusercontent.com/festusagbedeme/feziworld/main"
INSTALL_PATH="/usr/local/bin/feziworld"

echo -e "${PINK}FEZIWORLD PRO v4.0 - Interactive Setup Edition${RESET}"
echo -e "${YELLOW}This version ASKS for IP/Domain/URL for each protocol!${RESET}"

apt-get update -y
apt-get install -y curl wget jq vnstat iproute2 net-tools cron lsof git 2>/dev/null || true

mkdir -p /usr/local/bin /etc/feziworld /root/feziworld-backups

echo "Downloading..."
if curl -fsSL "$REPO_RAW/feziworld.sh" -o /tmp/feziworld.sh; then
  echo "Downloaded feziworld.sh"
elif curl -fsSL "$REPO_RAW/Feziworld.sh" -o /tmp/feziworld.sh; then
  echo "Downloaded Feziworld.sh (capital) - rename to lowercase please!"
else
  echo -e "${RED}Failed - make sure repo is public and feziworld.sh exists${RESET}"
  exit 1
fi

chmod +x /tmp/feziworld.sh
cp /tmp/feziworld.sh $INSTALL_PATH
chmod +x $INSTALL_PATH
cp /tmp/feziworld.sh /root/feziworld.sh
ln -sf $INSTALL_PATH /usr/local/bin/menu
ln -sf $INSTALL_PATH /usr/local/bin/fezi

echo -e "${GREEN}Installed! First run will launch Setup Wizard asking for IP/Domain for each protocol.${RESET}"
echo -e "To uninstall: ${RED}bash <(curl -fsSL https://raw.githubusercontent.com/festusagbedeme/feziworld/main/uninstall.sh)${RESET}"
sleep 1
exec $INSTALL_PATH
