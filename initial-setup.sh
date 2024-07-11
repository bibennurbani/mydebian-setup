#!/bin/bash

# Function to get user input
get_input() {
    local prompt=$1
    local default=$2
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Step 1: Update and upgrade packages
echo "Updating and upgrading packages..."
apt update && apt upgrade -y

# Step 2: Install sudo and add user to sudo group
USER=$(get_input "Enter the username to add to sudo group" "user")
echo "Installing sudo and adding $USER to sudo group..."
apt install sudo -y
usermod -aG sudo "$USER"

# Step 3: Configure static IP
echo "Configuring static IP..."
INTERFACE=$(get_input "Enter the network interface name" "eth0")
IP_ADDRESS=$(get_input "Enter the static IP address" "192.168.1.100")
NETMASK=$(get_input "Enter the netmask" "255.255.255.0")
GATEWAY=$(get_input "Enter the gateway" "192.168.1.1")
DNS=$(get_input "Enter the DNS server" "8.8.8.8")

# Backup the current interfaces file
cp /etc/network/interfaces /etc/network/interfaces.bak

# Comment out existing configurations
sed -i 's/^\(iface\|auto\)/#&/' /etc/network/interfaces

# Add new static IP configuration
cat <<EOL >> /etc/network/interfaces

auto $INTERFACE
iface $INTERFACE inet static
    address $IP_ADDRESS
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS
EOL

# Step 4: Install and configure SSH
echo "Installing and configuring SSH..."
apt install ssh -y

SSH_PORT=$(get_input "Enter the SSH port" "2222")

# Backup the current sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Configure SSH settings
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config

# Step 5: Install and enable UFW
echo "Installing and enabling UFW..."
apt install ufw -y
ufw allow "$SSH_PORT"/tcp
ufw enable

# Restart services at the end
echo "Restarting networking and SSH services..."
systemctl restart networking
systemctl restart sshd

echo "Setup complete!"
