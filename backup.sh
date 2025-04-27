#!/bin/bash

# === CONFIGURATION ===
DEVICE="/dev/nvme0n1p2"         # Partition to fsck
BACKUP_LOCATION="/mnt/external_hdd/backups"  # External HDD location
BACKUP_NAME="system_backup_$(date +%Y-%m-%d).img"
FULL_PATH="$BACKUP_LOCATION/$BACKUP_NAME"
LOG_FILE="./backup_error.log"   # Log file for errors and progress
MAX_BACKUPS=3                   # Maximum number of backups to keep

# === VALIDATE EXTERNAL HDD ===
if ! mountpoint -q /mnt/external_hdd; then
    echo "External HDD is not connected or mounted. Please check and try again." | tee -a $LOG_FILE
    exit 1
fi

# === INITIALIZE LOG FILE ===
echo "Backup started at $(date)" > $LOG_FILE
echo "Backing up $DEVICE to $FULL_PATH" >> $LOG_FILE

# === CHECKS ===
echo "Starting filesystem check on $DEVICE..."
sudo umount $DEVICE 2>> $LOG_FILE
if ! sudo fsck -y $DEVICE >> $LOG_FILE 2>&1; then
    echo "Filesystem check failed! Aborting backup." | tee -a $LOG_FILE
    exit 1
fi

echo "Filesystem OK. Running debsums..."
if ! sudo debsums -s >> $LOG_FILE 2>&1; then
    echo "Debsums detected corrupted packages! Please fix before backup." | tee -a $LOG_FILE
    exit 1
fi

# === BACKUP ROTATION ===
if [ "$(ls -1 $BACKUP_LOCATION | wc -l)" -ge "$MAX_BACKUPS" ]; then
    OLDEST_BACKUP=$(ls -1t $BACKUP_LOCATION | tail -n 1)
    echo "Deleting oldest backup: $OLDEST_BACKUP" | tee -a $LOG_FILE
    rm "$BACKUP_LOCATION/$OLDEST_BACKUP"
fi

# === BACKUP ===
echo "Both checks passed. Starting full backup..."
if ! sudo dd if=$DEVICE of=$FULL_PATH bs=64K conv=noerror,sync status=progress >> $LOG_FILE 2>&1; then
    echo "Backup failed during the dd operation!" | tee -a $LOG_FILE
    exit 1
fi

echo "Backup complete! Saved to $FULL_PATH" | tee -a $LOG_FILE
echo "Backup finished at $(date)" >> $LOG_FILE
