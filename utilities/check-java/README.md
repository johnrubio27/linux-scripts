# Java & Certificate Trust Auditor

This tool performs a centralized security audit to verify Java installations and the presence of specific Certificate Authority (CA) certs in the Java Keystore (`cacerts`) across an entire server fleet.

## 📋 Prerequisites
* **Local Machine:** `sshpass` installed.
* **Network:** SSH access to target servers.
* **Remote Hosts:** Linux-based (RHEL/CentOS preferred) with Java installed.

## ⚙️ Configuration
Open `check_remote_java_certs.sh` and set your environment variables:
* `CERT_ALIAS_TO_FIND`: The name or alias of the certificate you are looking for.
* `KEYSTORE_PATH`: The location of your Java `cacerts` file (usually `/etc/pki/java/cacerts`).
* `SSH_USER`: The username used to connect to remote hosts.

## 🚀 Execution
1.  **Populate `inventory_hosts.txt`** with your server IPs or Hostnames.
2.  **Run the script:**
    ```bash
    chmod +x check_remote_java_certs.sh
    ./check_remote_java_certs.sh
    ```
3.  Enter your password when prompted. The script will use this password for all SSH connections.

## 📊 Output Data
The script generates a CSV report named `security_audit_report.csv`:

| Column | Description |
| :--- | :--- |
| **IP** | Target IP address. |
| **Hostname** | Remote server name. |
| **Java_Version** | Detected version of Java Runtime. |
| **Cert_Status** | `FOUND` if the certificate exists, `MISSING` if not, `N/A` if Java is missing. |

## 🛡️ Security Notes
This script uses `StrictHostKeyChecking=no` to prevent automation hangs on new servers. Ensure you are running this in a trusted network environment.