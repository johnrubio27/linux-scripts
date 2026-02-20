#!/bin/bash
# ============================================================
# Script: ssh_audit_local.sh
# Description: Analyzes SSH logs and sends reports via SMTP
# ============================================================
set -euo pipefail

# --- Configuration (GENERALIZED) ---
INSTALL_DIR="/opt/ssh_audit"
USERS_FILE="$INSTALL_DIR/users.txt"
CURL_BIN="$INSTALL_DIR/curl-static/curl"
LOGSRC="/var/log/secure"  # Use /var/log/auth.log for Debian/Ubuntu

# Email Settings
SMTP_SERVER="REPLACE_WITH_SMTP_IP"
SMTP_PORT="25"
MAIL_FROM="REPLACE_WITH_SENDER_EMAIL"
MAIL_TO="REPLACE_WITH_RECIPIENT_EMAIL"

# Work Paths
DATE_STR="$(date +%F)"
ORIG_HOST="$(hostname)"
RESULTS_DIR="/tmp/ssh_audit"
mkdir -p "$RESULTS_DIR"
OUTPUT_FILE="$RESULTS_DIR/${ORIG_HOST}-${DATE_STR}.txt"
MAIL_MIME="/tmp/mail_${DATE_STR}.eml"

# --- Audit Logic ---
[[ -s "$USERS_FILE" ]] || { echo "[ERROR] User list missing or empty"; exit 1; }
mapfile -t USERS_LOCAL < <(grep -v '^\s*$' "$USERS_FILE" | grep -v '^\s*#')

{
  echo "[INFO] SSH Audit Report: $ORIG_HOST - $DATE_STR"
  echo "======================================"
  for USER in "${USERS_LOCAL[@]}"; do
    echo "Checking User: $USER"
    OPENED=$(grep "pam_unix(sshd:session): session opened for user $USER" "$LOGSRC" | tail -n 500 || true)
    if [[ -z "$OPENED" ]]; then
      echo "  No activity detected in the current log."
    else
      grep -E "pam_unix\(sshd:session\): session (opened|closed) for user $USER" "$LOGSRC" | while read -r line; do
        pid=$(grep -oP 'sshd\[\K[0-9]+' <<<"$line" || true)
        ip=$(grep "sshd\[$pid\].*Accepted" "$LOGSRC" | grep -oP 'from \K\S+' | head -n1 || true)
        echo "  $line [Source IP: ${ip:-Unknown}]"
      done
    fi
    echo "--------------------------------------"
  done
} > "$OUTPUT_FILE"

# --- Build MIME Message ---
ACCESS_DETECTED=$(grep -q "session opened" "$OUTPUT_FILE" && echo 1 || echo 0)
STATUS_TXT=$([[ $ACCESS_DETECTED -eq 1 ]] && echo "ACCESS DETECTED" || echo "NO ACCESS")
SUBJECT="[SSH AUDIT - $STATUS_TXT] - $ORIG_HOST - $DATE_STR"
BOUNDARY="BNDRY_$(date +%s)"

{
  printf 'From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary="%s"\r\n\r\n' "$MAIL_FROM" "$MAIL_TO" "$SUBJECT" "$BOUNDARY"
  printf '--%s\r\nContent-Type: text/plain; charset="UTF-8"\r\n\r\n' "$BOUNDARY"
  echo -e "Automated SSH Audit Report\nServer: $ORIG_HOST\nDate: $DATE_STR\nStatus: $STATUS_TXT\n"
  cat "$OUTPUT_FILE"
  if [[ $ACCESS_DETECTED -eq 1 ]]; then
    printf '\r\n--%s\r\nContent-Type: text/plain; name="%s"\r\nContent-Disposition: attachment; filename="%s"\r\nContent-Transfer-Encoding: base64\r\n\r\n' "$BOUNDARY" "$(basename "$OUTPUT_FILE")" "$(basename "$OUTPUT_FILE")"
    base64 "$OUTPUT_FILE"
  fi
  printf '\r\n--%s--\r\n' "$BOUNDARY"
} > "$MAIL_MIME"

# --- Delivery ---
if [[ -f "$CURL_BIN" ]]; then
    $CURL_BIN -s --url "smtp://$SMTP_SERVER:$SMTP_PORT" --mail-from "$MAIL_FROM" \
    $(echo "$MAIL_TO" | tr ',' ' ' | sed 's/[^ ]* /--mail-rcpt & /g') -T "$MAIL_MIME"
else
    echo "[ERROR] Portable curl not found at $CURL_BIN"
fi