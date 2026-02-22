#!/bin/bash
# NexStack Ling Agents — Machine Bootstrap
# Usage: curl -fsSL setup.nexstack.sg/agent-bootstrap.sh | bash
#
# What this does:
# 1. Installs Tailscale
# 2. Connects to Headscale (tailscale.nexstack.sg)
# 3. Adds Forge's SSH key for remote management
# 4. Sets hostname (optional)

set -e

HEADSCALE_URL="https://tailscale.nexstack.sg"
HEADSCALE_AUTHKEY="hskey-auth-eV6lIxzkum22-_b8rcV9eoutiNTyN2uuFbl9ZqR2CLBl6oluekvAYAUroJDStFXRuSViEPCWPJ66J"
FORGE_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiSTix01kBg7lJauQ3LS4ayfUMMfrdmw7xsbH+gBeH+ forge-ling@nexstack.sg"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔥 NexStack Ling Agents — Bootstrap${NC}"
echo "======================================="

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi
echo -e "OS: ${YELLOW}${OS}${NC}"

# Ask for hostname
read -p "Enter agent hostname (e.g. forge-ling, lume-ling): " AGENT_NAME
if [ -z "$AGENT_NAME" ]; then
    echo -e "${RED}Hostname required. Exiting.${NC}"
    exit 1
fi

# Step 1: Install Tailscale
echo ""
echo -e "${GREEN}[1/4] Installing Tailscale...${NC}"
if command -v tailscale &> /dev/null; then
    echo "Tailscale already installed, skipping."
else
    if [ "$OS" == "linux" ]; then
        curl -fsSL https://tailscale.com/install.sh | sh
    elif [ "$OS" == "macos" ]; then
        if command -v brew &> /dev/null; then
            brew install --cask tailscale
        else
            echo -e "${RED}Install Tailscale manually: https://tailscale.com/download/mac${NC}"
            exit 1
        fi
    fi
fi

# Step 2: Connect to Headscale
echo ""
echo -e "${GREEN}[2/4] Connecting to Headscale...${NC}"
if [ "$OS" == "linux" ]; then
    sudo tailscale up --login-server="$HEADSCALE_URL" --hostname="$AGENT_NAME" --authkey="$HEADSCALE_AUTHKEY"
elif [ "$OS" == "macos" ]; then
    tailscale up --login-server="$HEADSCALE_URL" --hostname="$AGENT_NAME" --authkey="$HEADSCALE_AUTHKEY"
fi

# Verify connection
echo ""
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
echo -e "Tailscale IP: ${YELLOW}${TAILSCALE_IP}${NC}"

# Step 3: Set hostname
echo ""
echo -e "${GREEN}[3/4] Setting hostname to ${AGENT_NAME}...${NC}"
if [ "$OS" == "linux" ]; then
    sudo hostnamectl set-hostname "$AGENT_NAME"
    sudo sed -i "s/127.0.1.1.*/127.0.1.1\t${AGENT_NAME}/" /etc/hosts
elif [ "$OS" == "macos" ]; then
    sudo scutil --set HostName "$AGENT_NAME"
    sudo scutil --set LocalHostName "$AGENT_NAME"
    sudo scutil --set ComputerName "$AGENT_NAME"
fi

# Step 4: Add Forge's SSH key
echo ""
echo -e "${GREEN}[4/4] Adding Forge's SSH key...${NC}"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if ! grep -q "forge-ling@nexstack.sg" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "$FORGE_SSH_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "SSH key added."
else
    echo "SSH key already present, skipping."
fi

# Done
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ Bootstrap complete!${NC}"
echo -e "  Hostname:  ${YELLOW}${AGENT_NAME}${NC}"
echo -e "  Tailscale: ${YELLOW}${TAILSCALE_IP}${NC}"
echo -e "  SSH:       ${YELLOW}Forge can now SSH in${NC}"
echo ""
echo -e "Verify with: ${YELLOW}tailscale status${NC}"
echo -e "${GREEN}🔥 Welcome to the Ling network.${NC}"
