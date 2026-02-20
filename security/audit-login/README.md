# Multi-Host SSH Access Audit Suite

A centralized security solution to monitor SSH logins across a Linux infrastructure. It correlates session events with source IP addresses and delivers automated MIME-formatted email reports, even on servers without native mail utilities.

## 📦 Required Components
1. **`hosts.txt`**: A text file containing remote server IPs/Hostnames (one per line).
2. **`users.txt`**: A text file containing the list of usernames to monitor.
3. **`ssh_audit_local.sh`**: The audit engine script.
4. **`curl-portable.tar.gz`**: A pre-compiled static `curl` binary (enables SMTP on restricted hosts).
5. **`deploy_audit.sh`**: The automation script used to install the suite across the network.

## 🚀 Execution Workflow

### Step 1: Configuration
Before deploying, edit the `Configuration` section in `ssh_audit_local.sh`:
- Update `SMTP_SERVER` and `SMTP_PORT`.
- Set `MAIL_FROM` and `MAIL_TO`.

### Step 2: Deployment
From your management workstation, run:
```bash
chmod +x deploy_audit.sh
./deploy_audit.sh

```

**This process will:**

* Create the installation directory (`/opt/ssh_audit`) on each remote host.
* Transfer the audit engine and dependencies.
* Extract the portable `curl` binary.
* **Set the Schedule:** Automatically add a Crontab entry (default: 7:00 AM daily).

### Step 3: Automated Monitoring

The systems will now operate autonomously. Every 24 hours:

* The script analyzes `/var/log/secure` for login/logout events.
* It extracts the **Source IP** by matching the process PID.
* It formats a MIME email and sends it via the provided SMTP relay.

## 📊 Data Mapping

| Feature | Implementation |
| --- | --- |
| **Log Source** | `/var/log/secure` (RHEL/CentOS) or `/var/log/auth.log` (Debian/Ubuntu) |
| **IP Detection** | Correlated via `sshd` PID matching |
| **Email Protocol** | SMTP (Raw MIME over TCP via Curl) |
| **Permissions** | Automatic fallback to `sudo` for Crontab if logs are restricted |

## 🛠 Troubleshooting

* **No Email Received:** Check if the remote host has outbound access to the SMTP port (usually 25 or 587).
* **Log Access Denied:** Ensure the user running the script (or the root cron) has read access to system authentication logs.

```

Would you like me to create a sample `curl-portable` structure or explain how to compile the static binary for the `tar.gz` package?

```