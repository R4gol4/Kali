#!/bin/bash

# === CONFIGURATION ===
DEVICE="/dev/nvme0n1p2"
BACKUP_LOCATION="/mnt/external_hdd/backups"
BACKUP_NAME="system_backup_$(date +%Y-%m-%d).img"
FULL_PATH="$BACKUP_LOCATION/$BACKUP_NAME"
LOG_FILE="./backup_error.log"
MAX_BACKUPS=3
REBOOT_MARKER="/tmp/backup_after_reboot"

# === INITIALIZE LOG FILE ===
echo "Backup process started at $(date)" > $LOG_FILE

# === CHECK FOR ROOT PRIVILEGES ===
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo." | tee -a $LOG_FILE
    exit 1
fi

# === CHECK IF POST-REBOOT ===
if [ -f "$REBOOT_MARKER" ]; then
    echo "System rebooted, filesystem check complete. Continuing with backup..." | tee -a $LOG_FILE
    rm "$REBOOT_MARKER"   # Cleanup marker
else
    # === VALIDATE EXTERNAL HDD ===
    if ! mountpoint -q /mnt/external_hdd; then
        echo "External HDD is not connected or mounted. Please check and try again." | tee -a $LOG_FILE
        exit 1
    fi

    # Ensure the backup directory exists
    if [ ! -d "$BACKUP_LOCATION" ]; then
        echo "Backup directory does not exist. Creating it now..." | tee -a $LOG_FILE
        mkdir -p "$BACKUP_LOCATION"
    fi

    # === INITIALIZE LOG FILE ===
    echo "Backup started at $(date)" > $LOG_FILE
    echo "Backing up $DEVICE to $FULL_PATH" >> $LOG_FILE

    # === ROOT PARTITION DETECTION ===
    if grep -q " / " /proc/mounts | grep -q "$DEVICE"; then
        echo "Root partition detected. Scheduling filesystem check at next reboot..." | tee -a $LOG_FILE
        touch /forcefsck
        touch $REBOOT_MARKER
        echo "Rebooting now to run fsck..." | tee -a $LOG_FILE
        reboot
        exit 0
    fi

    # === FILESYSTEM CHECK (for non-root partitions) ===
    echo "Starting filesystem check on $DEVICE..."
    umount $DEVICE 2>> $LOG_FILE
    if ! fsck -y $DEVICE >> $LOG_FILE 2>&1; then
        echo "Filesystem check failed! Aborting backup." | tee -a $LOG_FILE
        exit 1
    fi
fi

# === CHECK SYSTEM INTEGRITY ===
echo "Filesystem OK. Running debsums..."
if ! debsums -s >> $LOG_FILE 2>&1; then
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
if ! dd if=$DEVICE of=$FULL_PATH bs=64K conv=noerror,sync status=progress >> $LOG_FILE 2>&1; then
    echo "Backup failed during the dd operation!" | tee -a $LOG_FILE
    exit 1
fi

echo "Backup complete! Saved to $FULL_PATH" | tee -a $LOG_FILE
echo "Backup finished at $(date)" >> $LOG_FILE
