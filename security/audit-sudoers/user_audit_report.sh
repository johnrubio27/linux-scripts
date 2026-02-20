#!/bin/bash
# ==============================================================================
# Script: Consolidated User Audit Report (CSV Input)
# Description: Collects user account info from servers listed in a CSV file
# ==============================================================================

# Input file containing server IPs/Hostnames (one per line)
INPUT_FILE="servers.csv"

# SSH User with required permissions
SSH_USER="audit_admin"

# Output file
OUTPUT="consolidated_user_report.csv"

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE not found."
    exit 1
fi

# CSV Header
echo "Server,User,UID,Creation_Date,Last_Login,Groups,Sudo_Roles,SELinux_Role" > "$OUTPUT"

# Read servers from CSV and skip empty lines
while IFS=, read -r srv || [ -n "$srv" ]; do
    [[ -z "$srv" || "$srv" =~ ^# ]] && continue

    echo "Connecting to $srv..."
    
    # Run the audit commands remotely
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_USER@$srv" 'bash -s' <<'EOF' | \
    awk -v server="$srv" -F, 'NR>1 {print server","$0}' >> "$OUTPUT"
#!/bin/bash
echo "User,UID,Creation_Date,Last_Login,Groups,Sudo_Roles,SELinux_Role"
# Filter real users (UID >= 1000)
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    uid=$(id -u "$user")
    home_dir=$(eval echo "~$user")
    
    if [ -d "$home_dir" ]; then
        created=$(stat -c %w "$home_dir" 2>/dev/null)
        [[ "$created" == "-" || -z "$created" ]] && created=$(stat -c %z "$home_dir")
    else
        created="N/A"
    fi

    last_login=$(lastlog -u "$user" | awk 'NR==2 {print $4,$5,$6,$7}')
    groups=$(id -nG "$user" | tr ' ' '|')
    sudo_roles=$(grep -rE "^$user\b" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | tr '\n' '|')
    selinux_role=$(semanage login -l 2>/dev/null | awk -v u="$user" '$1==u {print $2}')
    
    echo "$user,$uid,$created,$last_login,$groups,$sudo_roles,$selinux_role"
done
EOF
done < "$INPUT_FILE"

echo "--------------------------------------------------"
echo "Done! Consolidated report saved to: $OUTPUT"