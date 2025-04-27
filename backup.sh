#!/bin/bash

# === CONFIGURATION ===
DEVICE="/dev/nvme0n1p2"         # Partition to fsck
BACKUP_LOCATION="/backups"       # Where to save the backup
BACKUP_NAME="system_backup_$(date +%Y-%m-%d).img"
FULL_PATH="$BACKUP_LOCATION/$BACKUP_NAME"

# === CHECKS ===

echo "Starting filesystem check on $DEVICE..."
sudo umount $DEVICE 2>/dev/null
sudo fsck -y $DEVICE

if [ $? -ne 0 ]; then
    echo "Filesystem check failed! Aborting backup."
    exit 1
fi

echo "Filesystem OK. Running debsums..."
sudo debsums -s

if [ $? -ne 0 ]; then
    echo "Debsums detected corrupted packages! Please fix before backup."
    exit 1
fi

# === BACKUP ===

echo "Both checks passed. Starting full backup..."
sudo dd if=$DEVICE of=$FULL_PATH bs=64K conv=noerror,sync status=progress

echo "Backup complete! Saved to $FULL_PATH"
