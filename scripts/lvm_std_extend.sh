#!/bin/bash
# =================================================================
# Project: Local LVM Lifecycle Manager (Final Stable Edition)
# Author: Danny (dn0218)
# Description: Final version with fixes for partition detection, size handling, and device busy issues
# =================================================================

[[ $EUID -ne 0 ]] && echo "❌ Please run with sudo" && exit 1

# --- Helper Function ---
get_input() {
    local prompt="$1" ; local var_name="$2" ; local input=""
    while [[ -z "$input" ]]; do
        read -p "$prompt: " input
        [[ -z "$input" ]] && echo "⚠️  Input cannot be empty. Please try again."
    done
    eval "$var_name=\"$input\""
}

# --- Step 1: Target Detection (Lock info before disk cleanup) ---
get_input "Enter mount point path (e.g. /mnt/data3)" TARGET_MOUNT
TARGET_MOUNT=$(echo "$TARGET_MOUNT" | sed 's:/*$::')

[[ ! -d "$TARGET_MOUNT" ]] && mkdir -p "$TARGET_MOUNT"

# Detect mount using findmnt
MOUNT_INFO=$(findmnt -nvo SOURCE,FSTYPE "$TARGET_MOUNT")

if [[ -z "$MOUNT_INFO" ]]; then
    SCENARIO="CLEAN_DIR"
    echo "🔍 Scenario detected: [1] Empty directory"
else
    DEVICE_PATH=$(echo "$MOUNT_INFO" | awk '{print $1}')
    FS_TYPE=$(echo "$MOUNT_INFO" | awk '{print $2}')
    DEV_TYPE=$(lsblk -dno TYPE "$DEVICE_PATH" | head -n 1)
    
    # Lock original size before wipefs affects lsblk
    ORIGINAL_SIZE=$(lsblk -no SIZE "$DEVICE_PATH" | head -n 1 | tr -d ' ')

    if [[ "$DEV_TYPE" == "lvm" ]]; then
        SCENARIO="LVM_EXTEND"
        echo "🔍 Scenario detected: [3] LVM volume ($DEVICE_PATH)"
    else
        SCENARIO="PARTITIONED"
        echo "🔍 Scenario detected: [2] Existing partition ($DEVICE_PATH), original size: $ORIGINAL_SIZE"
    fi
fi

# --- Step 2: Resource Assignment & Force Cleanup ---
echo "------------------------------------------------"
lsblk -pno NAME,SIZE,TYPE,MOUNTPOINTS | grep 'disk'
get_input "Enter the physical disk to use (e.g. /dev/sdb)" CHOSEN_DISK
[[ ! -b "$CHOSEN_DISK" ]] && echo "❌ Disk does not exist" && exit 1

if [[ "$SCENARIO" != "LVM_EXTEND" ]]; then
    echo "⚙️  Performing deep cleanup on disk $CHOSEN_DISK..."
    
    # 1. Force unmount all partitions (resolve device busy)
    lsblk -nlo MOUNTPOINT "$CHOSEN_DISK" | grep -v '^$' | xargs -r umount -l
    
    # 2. Remove existing VG conflicts
    OLD_VG=$(pvs --noheadings -o vg_name "$CHOSEN_DISK" 2>/dev/null | tr -d ' ')
    if [[ -n "$OLD_VG" ]]; then
        echo "⚠️  Removing existing volume group: $OLD_VG"
        vgremove -ff -y "$OLD_VG" &>/dev/null
    fi

    # 3. Force create PV
    wipefs -a "$CHOSEN_DISK" &>/dev/null
    pvcreate -ff -y "$CHOSEN_DISK" || { echo "❌ PV creation failed"; exit 1; }
fi

# --- Step 3: Business Logic ---
case $SCENARIO in
    "CLEAN_DIR")
        get_input "Enter new VG name" VG_NAME
        get_input "Enter new LV name" LV_NAME
        get_input "Enter size (e.g. 2G)" SIZE
        vgcreate "$VG_NAME" "$CHOSEN_DISK"
        lvcreate -L "$SIZE" -n "$LV_NAME" "$VG_NAME"
        LV_PATH="/dev/$VG_NAME/$LV_NAME"
        get_input "Enter filesystem type (ext4/xfs)" NEW_FS
        mkfs.$NEW_FS "$LV_PATH"
        mount "$LV_PATH" "$TARGET_MOUNT"
        ;;

    "PARTITIONED")
        echo "⚠️  Warning: $DEVICE_PATH will be overwritten. All data will be lost!"
        read -p "Confirm to proceed? (y/n): " CONFIRM
        [[ "$CONFIRM" != "y" ]] && exit 1
        
        umount -l "$TARGET_MOUNT" 2>/dev/null
        get_input "Enter new VG name" VG_NAME
        get_input "Enter new LV name" LV_NAME
        
        vgcreate "$VG_NAME" "$CHOSEN_DISK"
        lvcreate -L "$ORIGINAL_SIZE" -n "$LV_NAME" "$VG_NAME"
        LV_PATH="/dev/$VG_NAME/$LV_NAME"
        mkfs.$FS_TYPE "$LV_PATH"
        mount "$LV_PATH" "$TARGET_MOUNT"
        ;;

    "LVM_EXTEND")
        VG_NAME=$(lvs --noheadings -o vg_name "$DEVICE_PATH" | tr -d ' ')
        
        if ! pvs "$CHOSEN_DISK" &>/dev/null; then
            pvcreate -y "$CHOSEN_DISK"
        fi
        
        vgextend "$VG_NAME" "$CHOSEN_DISK" 2>/dev/null
        
        get_input "Enter size to extend (e.g. +1G)" ADD_SIZE
        lvextend -L "$ADD_SIZE" -r "$DEVICE_PATH"
        ;;
esac

# --- Step 4: Verification ---
echo "------------------------------------------------"
df -hT "$TARGET_MOUNT"
echo "✅ Task completed!"
