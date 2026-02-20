#!/bin/bash
# ============================================================
# Script: deploy_audit.sh (Generalized)
# ============================================================
set -euo pipefail

# --- Local Files and Remote Paths ---
HOSTS_FILE="./hosts.txt"
AUDIT_SCRIPT="./ssh_audit_local.sh"
USERS_FILE="./users.txt"
CURL_TARBALL="./curl-portable.tar.gz"
REMOTE_PATH="/opt/ssh_audit"

# --- Schedule Configuration ---
CRON_TIME="0 7 * * *" # Default: Every day at 7:00 AM

# --- Pre-Checks ---
[[ -f "$HOSTS_FILE" ]] || { echo "Error: $HOSTS_FILE not found"; exit 1; }
command -v sshpass &>/dev/null || { echo "Error: sshpass must be installed locally"; exit 1; }

# --- Credentials ---
read -p "Remote SSH Username: " SSH_USER
read -s -p "Remote SSH Password: " SSH_PASS
echo -e "\n"

mapfile -t HOSTS < <(grep -v '^\s*#' "$HOSTS_FILE" | grep -v '^$')

for HOST in "${HOSTS[@]}"; do
    echo ">>> Deploying to: $HOST"
    
    # 1. Create remote environment
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "mkdir -p $REMOTE_PATH/curl-static"
    
    # 2. Upload files
    sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no "$AUDIT_SCRIPT" "$USERS_FILE" "$CURL_TARBALL" "$SSH_USER@$HOST:$REMOTE_PATH/"
    
    # 3. Extract portable dependencies
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" \
        "tar -xzf $REMOTE_PATH/$(basename $CURL_TARBALL) -C $REMOTE_PATH/curl-static"
    
    # 4. Automate via Crontab
    CRON_CMD="bash $REMOTE_PATH/$(basename $AUDIT_SCRIPT)"
    
    # Logic: If current user can read logs, use their crontab; otherwise, use sudo for root crontab
    if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "test -r /var/log/secure" < /dev/null; then
        echo "   [INFO] Configuring user-level cron"
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" \
            "(crontab -l 2>/dev/null | grep -v \"$CRON_CMD\"; echo \"$CRON_TIME $CRON_CMD\") | crontab -"
    else
        echo "   [WARNING] Insufficient log permissions. Configuring root cron via sudo"
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" \
            "echo \"$SSH_PASS\" | sudo -S bash -c '(crontab -l 2>/dev/null | grep -v \"$CRON_CMD\"; echo \"$CRON_TIME $CRON_CMD\") | crontab -'"
    fi
done

echo "Deployment finished."