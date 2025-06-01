#!/bin/bash

# CONFIGURATION
BACKUP_DIR="/mnt/external_hdd/backups"
BACKUP_PREFIX="backup"
TODAY=$(date +%F)
BACKUP_NAME="${BACKUP_PREFIX}-${TODAY}.tar.gz"
FULL_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
SOURCE_DIR="/"
EXCLUDES=(
  --exclude=/proc
  --exclude=/tmp
  --exclude=/mnt
  --exclude=/dev
  --exclude=/sys
  --exclude=/run
  --exclude=/media
  --exclude=/lost+found
  --exclude=/swapfile
)

# 1. CHECK: Ensure backup directory is mounted and writable
if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: Backup directory $BACKUP_DIR does not exist or is not mounted."
  exit 1
fi

if [ ! -w "$BACKUP_DIR" ]; then
  echo "ERROR: Cannot write to $BACKUP_DIR."
  exit 1
fi

# 2. CHECK: Source directories are readable
echo "Checking source directories for readability..."
for dir in /bin /boot /etc /home /lib /opt /root /sbin /srv /usr /var; do
  if [ ! -r "$dir" ]; then
    echo "ERROR: Cannot read $dir"
    exit 1
  fi
done

# 3. DELETE: Remove oldest backup if more than 5 exist
BACKUP_COUNT=$(ls -1 ${BACKUP_DIR}/${BACKUP_PREFIX}-*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -ge 5 ]; then
  OLDEST=$(ls -1 ${BACKUP_DIR}/${BACKUP_PREFIX}-*.tar.gz | head -n 1)
  echo "Deleting oldest backup: $OLDEST"
  rm "$OLDEST"
fi

# 4. BACKUP: Create new compressed tarball
echo "Creating backup: $FULL_PATH"
sudo tar -czvf "$FULL_PATH" "${EXCLUDES[@]}" "$SOURCE_DIR"

# 5. DONE
echo "Backup completed successfully at $FULL_PATH"
