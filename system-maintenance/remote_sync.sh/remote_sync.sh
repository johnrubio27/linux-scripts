#!/bin/bash
# ==============================================================================
# Script: Remote Directory Synchronization
# Description: Syncs a directory from a remote server to a local path using rsync
# ==============================================================================

# Source User and Host
SOURCE_USER="remote_user"
SOURCE_HOST="192.168.1.100"

# Source and Destination paths
SOURCE_DIR="/path/to/source/directory/"
DEST_DIR="/path/to/destination/directory/"

# Log file with timestamp
LOG_FILE="/var/log/sync_$(date +%Y%m%d_%H%M%S).log"

# Log Header
{
    echo "== SYNC START =="
    echo "Date: $(date)"
    echo "Source: ${SOURCE_USER}@${SOURCE_HOST}:${SOURCE_DIR}"
    echo "Destination: ${DEST_DIR}"
    echo ""
} | tee -a "$LOG_FILE"

# Execute rsync via SSH
# -a: archive mode, -v: verbose, -z: compress, -h: human-readable
rsync -avzh -e "ssh" "${SOURCE_USER}@${SOURCE_HOST}:${SOURCE_DIR}" "$DEST_DIR" \
    2>&1 | tee -a "$LOG_FILE"

# Result validation (PIPESTATUS[0] catches rsync exit code before the pipe)
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "\nSynchronization completed successfully." | tee -a "$LOG_FILE"
else
    echo -e "\nAn error occurred during synchronization." | tee -a "$LOG_FILE"
fi

echo "== END ==" | tee -a "$LOG_FILE"