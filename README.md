# RHEL-LVM-Automation
## 📌 Project Overview
This project demonstrates advanced LVM (Logical Volume Manager) management on RHEL/Rocky Linux 9. It includes a comprehensive SOP for manual scaling and a Bash script to automate the process, specifically addressing real-world conflicts with **Autofs** and **Ext4** online resizing.

## 🚀 Key Features
- **Physical Volume Management**: Handling partitioned devices using `wipefs`.
- **Volume Group Expansion**: Adding new physical disks to existing pools.
- **Filesystem Awareness**: Intelligent resizing for both **XFS** and **Ext4**.
- **Autofs Integration**: Resolving mount point invisibility caused by automounter master maps.

## 📂 Project Structure
- `scripts/lvm_extend.sh`: The main automation script.
- `docs/troubleshooting.md`: Logs of common errors (e.g., Device is partitioned, fsck failures).
- `configs/auto.nfs`: Sample Autofs configuration for LVM devices.

## 🛠️ Manual SOP (Quick Steps)
1. **Prepare PV**: `sudo pvcreate /dev/sdb` (Use `wipefs -a` if partitioned).
2. **Extend VG**: `sudo vgextend vg_dev /dev/sdb`.
3. **Extend LV**: `sudo lvextend -L +1.5G /dev/vg_dev/lv_exam`.
4. **Resize FS**: `sudo resize2fs /dev/vg_dev/lv_exam` (for Ext4).

## ⚠️ Lessons Learned (The "Gotchas")
- **Autofs Conflict**: If `/mnt` is managed by Autofs, manual mounts will disappear after service restarts. Solution: Add the LV to `/etc/auto.nfs`.
- **Ext4 Online Resize**: Sometimes `lvextend -r` fails because it tries to run `fsck` on a mounted volume. Manual `resize2fs` is the reliable fallback.
