#!/bin/bash

# Swap creation script based on existing RAM size
# Author: (your-name-here)
# Date: (today's-date-here)

set -e

# Configurable Parameters
MULTIPLIER=2     # Swap size = RAM * MULTIPLIER
SWAPFILE="/swapfile"

# Check if swap already exists
if swapon --show | grep -q "$SWAPFILE"; then
  echo "Swap already exists at $SWAPFILE. Exiting."
  exit 0
fi

# Detect RAM size in MB
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
SWAP_MB=$(( RAM_MB * MULTIPLIER ))

echo "Detected RAM: ${RAM_MB}MB"
echo "Creating swap of size: ${SWAP_MB}MB"

# Create swap file
sudo fallocate -l "${SWAP_MB}M" $SWAPFILE

# Set permissions
sudo chmod 600 $SWAPFILE

# Format swap
sudo mkswap $SWAPFILE

# Enable swap
sudo swapon $SWAPFILE

# Persist swap in /etc/fstab
if ! grep -q "$SWAPFILE" /etc/fstab; then
  echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo "Swap successfully created and enabled!"
swapon --show
