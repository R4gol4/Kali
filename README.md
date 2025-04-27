# Kali



1. Configuration Section

DEVICE = the partition you want to backup (your system partition).
BACKUP_LOCATION = folder on your external HDD where backups are stored.
BACKUP_NAME = today's backup filename, with current date (e.g., system_backup_2025-04-27.img).
FULL_PATH = full path where backup will be saved.
LOG_FILE = local file where all output (success and errors) are recorded.
MAX_BACKUPS = maximum number of backup files to keep (older ones will be deleted automatically).



2. Validate External HDD is Mounted

Checks if the external HDD mount point exists and is properly mounted.
If not, it aborts immediately with a clear error message logged to the log file.



3. Initialize the Log File

Records timestamp and what device is being backed up.



4. Run Filesystem Check

Runs fsck on it.
If fsck fails, the script exits immediately and logs the failure.



5. Run debsums Integrity Check

If corrupted packages are detected, aborts the backup process.
makes sure you're not backing up a broken system image.



6. Backup Rotation

only stores three backups



7. Take Full Backup

If the dd operation fails, script exits safely.



8. Final Success Message

Logs end time.
