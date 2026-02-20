## Consolidated User Audit Tool (Multi-Server)

This script automates the collection of security information and user account metadata from multiple remote Linux servers. Instead of hardcoding IPs, it reads the target list from an external CSV file.

### 📋 Features
* **External Input:** Reads server list from `servers.csv`.
* **User Identification:** Username and UID (filters for real users with UID >= 1000).
* **Timeline:** Tracks account creation and last login activity.
* **Privilege Escalation:** Lists group memberships and `/etc/sudoers` entries.
* **Security Context:** Captures SELinux login roles.

### 🚀 Requirements
* **SSH Keys:** Passwordless SSH access must be configured for the `SSH_USER`.
* **Permissions:** The remote user needs read access to system security files (`/etc/sudoers`, `/etc/shadow`).
* **Input File:** A file named `servers.csv` in the same directory.

### ⚙️ Setup
1. Create a `servers.csv` file with your server IPs:
   ```text
   10.0.0.1
   10.0.0.2

2. Set the `SSH_USER` variable in the script to your administrative user.
3. Run the script:
```bash
bash user_audit_report.sh
```

### 📊 Output

Results are saved to `consolidated_user_report.csv` with the following columns:

| Column | Description |
| --- | --- |
| **Server** | IP address or Hostname of the machine |
| **User** | System username |
| **UID** | User Identifier |
| **Creation_Date** | Estimated account creation timestamp |
| **Last_Login** | Timestamp of the last recorded session |
| **Groups** | List of secondary groups |
| **Sudo_Roles** | Specific permissions in `/etc/sudoers` |
| **SELinux_Role** | Security context assigned to the login |

---