## Repository Sync & Kernel Pruning Tool

This script manages local mirrors of Linux RPM repositories. It automates the download of new packages, maintains storage by deleting obsolete kernel versions, and refreshes the metadata for client consumption.

### 📋 Features
* **Multi-Repo Sync:** Downloads packages and metadata for multiple Repository IDs using `reposync`.
* **Smart Kernel Cleanup:** Automatically identifies kernel-related RPMs (core, modules, devel) and keeps only the **3 most recent versions** to save disk space.
* **Metadata Update:** Uses `createrepo_c` to regenerate repository XML metadata, ensuring clients see the latest packages.
* **Permission Enforcement:** Standardizes directory (755) and file (644) permissions for web server (Nginx/Apache) compatibility.

### 🚀 Requirements
* `yum-utils` (for `reposync`) and `createrepo_c` installed.
* Sufficient disk space in the destination directory.
* Root or sudo privileges to modify `/var/www/html` and write to `/var/log`.

### ⚙️ Setup
1. Define your target directory in the `DEST_DIR` variable.
2. List your specific Repository IDs in the `REPO_IDS` array.
3. Make the script executable:
   ```bash
   chmod +x repo_sync_manager.sh

```

4. Run the script manually or via cron:
```bash
sudo ./repo_sync_manager.sh

```


### 📊 Maintenance Details

* **Logs:** Every action is timestamped and recorded in `/var/log/repo_sync_custom.log`.
* **Cleanup Logic:** The script looks specifically for `kernel-` prefix files within the `Packages/k/` subdirectory of the repository.

