#!/bin/bash
# ==============================================================================
# Script: Repository Sync & Kernel Cleanup Manager
# Description: Syncs remote repositories, prunes old kernels, and updates metadata.
# ==============================================================================

# Configuration
DEST_DIR="/var/www/html/repos/linux_repo"
LOG_FILE="/var/log/repo_sync_custom.log"
# Define your Repo IDs here
REPO_IDS=("baseos-repo-id" "appstream-repo-id")
KEEP_COUNT=3

log() {
    echo -e "[$(date +'%F %T')] $1" | tee -a "$LOG_FILE"
}

cleanup_old_kernels() {
    local repo_path=$1
    log "→ Pruning old kernels in: $repo_path"

    # Identify kernel packages
    kernels=($(ls "$repo_path"/Packages/k/ 2>/dev/null | grep -E '^kernel-[0-9].*\.rpm$' | sort -V))

    if [ ${#kernels[@]} -eq 0 ]; then
        log "   No kernels found in $repo_path"
        return
    fi

    # Extract unique versions
    versions=($(printf "%s\n" "${kernels[@]}" \
        | sed -E 's/^kernel-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*$/\1/' \
        | sort -V | uniq))

    # Keep only the latest N versions
    keep_versions=($(printf "%s\n" "${versions[@]}" | tail -n "$KEEP_COUNT"))
    log "   Keeping versions: ${keep_versions[*]}"

    for v in "${versions[@]}"; do
        if [[ ! " ${keep_versions[*]} " =~ " $v " ]]; then
            log "   → Removing kernel version: $v"
            rm -f "$repo_path"/Packages/k/kernel-*$v*.rpm
        fi
    done
}

log "===================================================="
log "Starting Manual Repository Synchronization"

# Sync Repositories
for repo in "${REPO_IDS[@]}"; do
    log "→ Syncing: $repo"
    /usr/bin/reposync \
        --repoid="$repo" \
        --arch=x86_64 \
        --download-metadata \
        --downloadcomps \
        --download-path="$DEST_DIR" 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log "ERROR: reposync failed for $repo"
        exit 1
    fi
done

# Cleanup old kernels (Usually found in BaseOS or equivalent)
# Adjust the subdirectory name as per your repo structure
cleanup_old_kernels "$DEST_DIR/BaseOS"

# Regenerate Metadata
log "→ Regenerating repository metadata"
for dir in "$DEST_DIR"/*/; do
    if [ -d "$dir" ]; then
        createrepo_c --update "$dir" 2>&1 | tee -a "$LOG_FILE"
    fi
done

# Permissions Management
log "→ Adjusting file permissions"
find "$DEST_DIR" -type d -exec chmod 755 {} \;
find "$DEST_DIR" -type f -exec chmod 644 {} \;

log "Synchronization completed successfully"
log "===================================================="