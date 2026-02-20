## Remote Directory Synchronization Tool

This script simplifies the process of synchronizing folders from a remote server to a local machine using `rsync` over `SSH`. It includes automated logging and error handling.

### 📋 Features
* **Efficient Transfer:** Uses `rsync` with compression and archive settings to preserve permissions.
* **Automated Logging:** Generates a detailed log file in `/var/log/` with timestamps for every execution.
* **Status Tracking:** Provides visual feedback and log entries for success or failure.
* **SSH Integration:** Uses secure shell for data transport.

### 🚀 Requirements
* `rsync` installed on both source and destination machines.
* SSH key-based authentication configured between the local and remote host.
* Write permissions on the destination directory and the log path.

### ⚙️ Setup
1. Update the `SOURCE_USER` and `SOURCE_HOST` variables with your remote credentials.
2. Define the `SOURCE_DIR` (remote) and `DEST_DIR` (local) paths.
3. Grant execution permissions:
   ```bash
   chmod +x remote_sync.sh
4. Run the script:
```bash
./remote_sync.sh
```
### 📊 Output

* **Terminal:** Real-time progress of the file transfer.
* **Log File:** A file named `sync_YYYYMMDD_HHMMSS.log` containing the full transfer summary and any errors encountered.

