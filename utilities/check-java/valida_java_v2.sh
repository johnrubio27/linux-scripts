#!/bin/bash
# ==============================================================================
# Script: check_remote_java_certs.sh
# Description: Audits Java versions and verifies the presence of a specific 
#              Certificate Alias in the Java Keystore across multiple hosts.
# ==============================================================================

set -euo pipefail

# --- Configuration (GENERALIZED) ---
SSH_USER="REPLACE_WITH_YOUR_USER"
HOSTS_FILE="inventory_hosts.txt"
OUTPUT_FILE="security_audit_report.csv"

# Certificate Settings
CERT_ALIAS_TO_FIND="REPLACE_WITH_CERT_ALIAS" # e.g., "Sectigo", "DigiCert", or "InternalRoot"
KEYSTORE_PATH="/etc/pki/java/cacerts"
KEYSTORE_PASS="changeit" # Default Java keystore password

# --- Pre-Checks ---
[[ -f "$HOSTS_FILE" ]] || { echo "Error: $HOSTS_FILE not found"; exit 1; }
command -v sshpass &>/dev/null || { echo "Error: sshpass is required for this script"; exit 1; }

# --- Credentials ---
echo -n "Enter SSH password for $SSH_USER: "
read -s PASSWORD
echo -e "\n"

# Initialize Report File
echo "IP,Hostname,Java_Version,Cert_Status" > "$OUTPUT_FILE"

# --- Main Loop ---
while IFS= read -r HOST || [[ -n "$HOST" ]]; do
    [[ -z "$HOST" || "$HOST" =~ ^# ]] && continue

    echo "[INFO] Auditing $HOST..."

    # 1. Get Hostname
    REMOTE_NAME=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "hostname" 2>/dev/null || echo "UNREACHABLE")

    if [[ "$REMOTE_NAME" == "UNREACHABLE" ]]; then
        echo "$HOST,UNREACHABLE,N/A,N/A" >> "$OUTPUT_FILE"
        continue
    fi

    # 2. Check Java Version
    JAVA_VER=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" \
        "java -version 2>&1 | head -n 1 | awk -F'\"' '{print \$2}'" 2>/dev/null || echo "")

    # 3. Check for Certificate in Keystore
    CERT_FOUND=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" \
        "keytool -list -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASS 2>/dev/null | grep -i '$CERT_ALIAS_TO_FIND'" 2>/dev/null || echo "")

    # --- Result Processing ---
    if [[ -z "$JAVA_VER" ]]; then
        JAVA_VER="NOT_INSTALLED"
        CERT_STATUS="N/A"
    else
        if [[ -n "$CERT_FOUND" ]]; then
            CERT_STATUS="FOUND"
        else
            CERT_STATUS="MISSING"
        fi
    fi

    # Write to CSV
    echo "$HOST,$REMOTE_NAME,$JAVA_VER,$CERT_STATUS" >> "$OUTPUT_FILE"
    echo "      Host: $REMOTE_NAME | Java: $JAVA_VER | Cert ($CERT_ALIAS_TO_FIND): $CERT_STATUS"

done < "$HOSTS_FILE"

echo -e "\n[DONE] Security report generated: $OUTPUT_FILE"