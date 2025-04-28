#!/bin/bash

# ================================================
#  setup-swap-and-tune.sh
#  - Removes old swap safely
#  - Creates new swap based on RAM size
#  - Tunes vm.swappiness and vm.vfs_cache_pressure
#  - Author: (Atul Bhatt)
# ================================================

set -e

# Configurable Parameters
MULTIPLIER=2             # Swap size = RAM x MULTIPLIER
SWAPFILE="/swapfile"
SWAPPINESS_VALUE=10
VFS_CACHE_PRESSURE_VALUE=50

echo "---------------------------------------------------"
echo " Swap Reset, Creation & System Tuning Script Starting..."
echo "---------------------------------------------------"

# ---------------------------------------------------
# STEP 1: Remove any existing swap
# ---------------------------------------------------

echo "[1/4] Disabling any existing swap..."
sudo swapoff -a || true

echo "[2/4] Cleaning swap entries from /etc/fstab..."
sudo sed -i '/ swap /d' /etc/fstab

echo "[3/4] Removing old swap file if it exists..."
if [ -f "$SWAPFILE" ]; then
  sudo rm -f "$SWAPFILE"
  echo "Old swap file $SWAPFILE deleted."
else
  echo "No existing swap file found. Skipping deletion."
fi

# ---------------------------------------------------
# STEP 2: Create new swap
# ---------------------------------------------------

# Detect RAM size in MB
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
SWAP_MB=$(( RAM_MB * MULTIPLIER ))

echo "Detected RAM: ${RAM_MB}MB"
echo "Creating swap of size: ${SWAP_MB}MB..."

# Create swap file
if sudo fallocate -l "${SWAP_MB}M" $SWAPFILE; then
  echo "Swap file created with fallocate."
else
  echo "fallocate failed. Falling back to dd..."
  sudo dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAP_MB
fi

# Set permissions
sudo chmod 600 $SWAPFILE

# Format swap
sudo mkswap $SWAPFILE

# Enable swap
sudo swapon $SWAPFILE

# Persist swap in fstab
if ! grep -q "$SWAPFILE" /etc/fstab; then
  echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo "Swap created and enabled successfully!"

# ---------------------------------------------------
# STEP 3: Tune system performance
# ---------------------------------------------------

echo "---------------------------------------------------"
echo " Tuning system settings..."
echo "---------------------------------------------------"

# Set swappiness temporarily
sudo sysctl vm.swappiness=$SWAPPINESS_VALUE

# Persist swappiness
if grep -q "^vm.swappiness" /etc/sysctl.conf; then
  sudo sed -i "s/^vm\.swappiness=.*/vm.swappiness=$SWAPPINESS_VALUE/" /etc/sysctl.conf
else
  echo "vm.swappiness=$SWAPPINESS_VALUE" | sudo tee -a /etc/sysctl.conf
fi

# Set vfs_cache_pressure temporarily
sudo sysctl vm.vfs_cache_pressure=$VFS_CACHE_PRESSURE_VALUE

# Persist vfs_cache_pressure
if grep -q "^vm.vfs_cache_pressure" /etc/sysctl.conf; then
  sudo sed -i "s/^vm\.vfs_cache_pressure=.*/vm.vfs_cache_pressure=$VFS_CACHE_PRESSURE_VALUE/" /etc/sysctl.conf
else
  echo "vm.vfs_cache_pressure=$VFS_CACHE_PRESSURE_VALUE" | sudo tee -a /etc/sysctl.conf
fi

# Apply changes
sudo sysctl -p

# ---------------------------------------------------
# STEP 4: Final status
# ---------------------------------------------------

echo "---------------------------------------------------"
echo " Setup Complete! Final Status:"
echo "---------------------------------------------------"

swapon --show
echo ""
echo "Current vm.swappiness: $(cat /proc/sys/vm/swappiness)"
echo "Current vm.vfs_cache_pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"

echo "---------------------------------------------------"
echo " Done! System optimized 🚀"
echo "---------------------------------------------------"
