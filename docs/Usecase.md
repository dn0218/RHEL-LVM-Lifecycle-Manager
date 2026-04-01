# LVM Management Use Case Report

This document provides a detailed walkthrough of testing the script across four real-world scenarios, along with low-level technical explanations and command analysis.

---

## 🔧 Environment Setup

Before running the script, the following test environment was prepared:

```bash
[danny@rhel ~]$ lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda             8:0    0    5G  0 disk 
sdb             8:16   0    5G  0 disk 
sdc             8:32   0    5G  0 disk 
sr0            11:0    1 12.7G  0 rom  /run/media/danny/RHEL-9-7-0-BaseOS-x86_64
nvme0n1       259:0    0   20G  0 disk 
├─nvme0n1p1   259:1    0  600M  0 part /boot/efi
├─nvme0n1p2   259:2    0    1G  0 part /boot
└─nvme0n1p3   259:3    0 18.4G  0 part 
  ├─rhel-root 253:0    0 16.4G  0 lvm  /
  └─rhel-swap 253:1    0    2G  0 lvm  [SWAP]
[danny@rhel ~]$ sudo mkdir -p /mnt/data1
[danny@rhel ~]$ sudo mkdir -p /mnt/data2
[danny@rhel ~]$ sudo mkdir -p /mnt/data3
```  
  Mount points:  
  /mnt/data1  
  /mnt/data2  
  /mnt/data3  
### /mnt/data1 (Clean New Directory)
```bash
[danny@rhel ~]$ sudo mkdir -p /mnt/data1
```

### /mnt/data2 (Partitioned Disk)
```bash
[danny@rhel /]$ sudo echo -e "n\np\n1\n\n+1G\nw" | sudo fdisk /dev/sdb

Welcome to fdisk (util-linux 2.37.4).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0xbc64fe42.

Command (m for help): Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): Partition number (1-4, default 1): First sector (2048-10485759, default 2048): Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-10485759, default 10485759): 
Created a new partition 1 of type 'Linux' and of size 1 GiB.

Command (m for help): The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

[danny@rhel /]$ sudo mkfs.ext4 /dev/sdb1
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 1571fe1d-fb70-46f1-95b1-f69934f90573
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done

[danny@rhel /]$ sudo mount /dev/sdb1 /mnt/data2
[danny@rhel /]$ lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda             8:0    0    5G  0 disk 
sdb             8:16   0    5G  0 disk 
└─sdb1          8:17   0    1G  0 part /mnt/data2
sdc             8:32   0    5G  0 disk 
sr0            11:0    1 12.7G  0 rom  /run/media/danny/RHEL-9-7-0-BaseOS-x86_64
nvme0n1       259:0    0   20G  0 disk 
├─nvme0n1p1   259:1    0  600M  0 part /boot/efi
├─nvme0n1p2   259:2    0    1G  0 part /boot
└─nvme0n1p3   259:3    0 18.4G  0 part 
  ├─rhel-root 253:0    0 16.4G  0 lvm  /
  └─rhel-swap 253:1    0    2G  0 lvm  [SWAP]
```

### /mnt/data3 (Create Logical Volume)
```bash
[danny@rhel /]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
[danny@rhel /]$ sudo vgcreate vg_test /dev/sdc
  Volume group "vg_test" successfully created
[danny@rhel /]$ sudo lvcreate -L 1G -n lv_test vg_test
  Logical volume "lv_test" created.
[danny@rhel /]$ sudo mkfs.xfs /dev/vg_test/lv_test
meta-data=/dev/vg_test/lv_test   isize=512    agcount=4, agsize=65536 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=262144, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=16384, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[danny@rhel /]$ sudo mount /dev/vg_test/lv_test /mnt/data3
[danny@rhel /]$ lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda             8:0    0    5G  0 disk 
sdb             8:16   0    5G  0 disk 
└─sdb1          8:17   0    1G  0 part /mnt/data2
sdc             8:32   0    5G  0 disk 
└─vg_test-lv_test
              253:2    0    1G  0 lvm  /mnt/data3
sr0            11:0    1 12.7G  0 rom  /run/media/danny/RHEL-9-7-0-BaseOS-x86_64
nvme0n1       259:0    0   20G  0 disk 
├─nvme0n1p1   259:1    0  600M  0 part /boot/efi
├─nvme0n1p2   259:2    0    1G  0 part /boot
└─nvme0n1p3   259:3    0 18.4G  0 part 
  ├─rhel-root 253:0    0 16.4G  0 lvm  /
  └─rhel-swap 253:1    0    2G  0 lvm  [SWAP]
```

📦 Scenario 1: Build LVM from Scratch (CLEAN_DIR)
🎯 Objective

Initialize /dev/sda and mount it to a new empty directory /mnt/data1.
```bash
[danny@rhel /]$ sudo ./lvm_std_extend.sh 
请输入挂载点路径 (例如 /mnt/data3): /mnt/data1
🔍 场景识别: [1] 纯空目录 - 准备从零创建 LVM
------------------------------------------------
/dev/sda                         5G disk 
/dev/sdb                         5G disk 
/dev/sdc                         5G disk 
/dev/nvme0n1                    20G disk 
请输入要使用的物理磁盘 (例如 /dev/sdb): /dev/sda
⚙️  正在清理磁盘 /dev/sda 签名...
  Physical volume "/dev/sda" successfully created.
新 VG 名称: vg_data1
新 LV 名称: lv_data1
初始大小 (例如 2G): 1G
  Volume group "vg_data1" successfully created
  Logical volume "lv_data1" created.
选择文件系统格式 (ext4/xfs): ext4
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 5981910a-cf3c-4a83-966b-32283ed93bad
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done

------------------------------------------------
Filesystem                    Type  Size  Used Avail Use% Mounted on
/dev/mapper/vg_data1-lv_data1 ext4  974M   24K  907M   1% /mnt/data1
✅ 任务完成！
[danny@rhel /]$ lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda               8:0    0    5G  0 disk 
└─vg_data1-lv_data1
                253:3    0    1G  0 lvm  /mnt/data1
sdb               8:16   0    5G  0 disk 
└─sdb1            8:17   0    1G  0 part /mnt/data2
sdc               8:32   0    5G  0 disk 
└─vg_test-lv_test
                253:2    0    1G  0 lvm  /mnt/data3
sr0              11:0    1 12.7G  0 rom  /run/media/danny/RHEL-9-7-0-BaseOS-x86_64
nvme0n1         259:0    0   20G  0 disk 
├─nvme0n1p1     259:1    0  600M  0 part /boot/efi
├─nvme0n1p2     259:2    0    1G  0 part /boot
└─nvme0n1p3     259:3    0 18.4G  0 part 
  ├─rhel-root   253:0    0 16.4G  0 lvm  /
  └─rhel-swap   253:1    0    2G  0 lvm  [SWAP]

[danny@rhel /]$ df -hT /mnt/data1
Filesystem                    Type  Size  Used Avail Use% Mounted on
/dev/mapper/vg_data1-lv_data1 ext4  974M   24K  907M   1% /mnt/data1
```
User input:
- Mount point: /mnt/data1
- Disk: /dev/sda
- VG: vg_data1
- LV: lv_data1
- Size: 1G
- Filesystem: ext4

🧠 Technical Insight
- pvcreate -ff ensures disk initialization even if old metadata exists.
- Demonstrates full LVM stack:
- Disk → PV → VG → LV → Filesystem → Mount

📦 Scenario 2: Partition Migration / Overwrite (PARTITIONED)
🎯 Objective

Convert existing partition /dev/sdb1 (mounted on /mnt/data2) into LVM.

```bash
[danny@rhel /]$ lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda               8:0    0    5G  0 disk 
└─vg_data1-lv_data1
                253:3    0    1G  0 lvm  /mnt/data1
sdb               8:16   0    5G  0 disk 
└─sdb1            8:17   0    1G  0 part /mnt/data2
sdc               8:32   0    5G  0 disk 
└─vg_test-lv_test
                253:2    0    2G  0 lvm  /mnt/data3
sr0              11:0    1 12.7G  0 rom  /run/media/danny/RHEL-9-7-0-BaseOS-x86_64
nvme0n1         259:0    0   20G  0 disk 
├─nvme0n1p1     259:1    0  600M  0 part /boot/efi
├─nvme0n1p2     259:2    0    1G  0 part /boot
└─nvme0n1p3     259:3    0 18.4G  0 part 
  ├─rhel-root   253:0    0 16.4G  0 lvm  /
  └─rhel-swap   253:1    0    2G  0 lvm  [SWAP]
[danny@rhel /]$ sudo ./lvm_std_extend.sh
请输入挂载点路径 (例如 /mnt/data3): /mnt/data2
🔍 场景识别: [2] 普通分区 (/dev/sdb1)，原大小: 1G
------------------------------------------------
/dev/sda                           5G disk 
/dev/sdb                           5G disk 
/dev/sdc                           5G disk 
/dev/nvme0n1                      20G disk 
请输入要使用的物理磁盘 (例如 /dev/sdb): /dev/sdb
⚙️  正在深度清理磁盘 /dev/sdb...
  WARNING: adding device /dev/sdb with idname /dev/sdb which is already used for missing device.
  Physical volume "/dev/sdb" successfully created.
⚠️  注意：即将覆盖 /dev/sdb1。数据将丢失！
确认继续? (y/n): y
新 VG 名称: vg_migration1
新 LV 名称: lv_migration1
  WARNING: adding device /dev/sdb with idname /dev/sdb which is already used for missing device.
  Volume group "vg_migration1" successfully created
WARNING: ext4 signature detected on /dev/vg_migration1/lv_migration1 at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/vg_migration1/lv_migration1.
  Logical volume "lv_migration1" created.
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 39958461-0c75-4e16-83ab-3c9b00161357
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done

------------------------------------------------
Filesystem                              Type  Size  Used Avail Use% Mounted on
/dev/mapper/vg_migration1-lv_migration1 ext4  974M   24K  907M   1% /mnt/data2
✅ 任务完成！
[danny@rhel /]$ sudo pvs
  PV             VG            Fmt  Attr PSize  PFree 
  /dev/nvme0n1p3 rhel          lvm2 a--  18.41g     0 
  /dev/sda       vg_data1      lvm2 a--  <5.00g <4.00g
  /dev/sdb       vg_migration1 lvm2 a--  <5.00g <4.00g
  /dev/sdc       vg_test       lvm2 a--  <5.00g <3.00g
[danny@rhel /]$ lsblk
NAME             MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                8:0    0    5G  0 disk 
└─vg_data1-lv_data1
                 253:3    0    1G  0 lvm  /mnt/data1
sdb                8:16   0    5G  0 disk 
└─vg_migration1-lv_migration1
                 253:4    0    1G  0 lvm  /mnt/data2
sdc                8:32   0    5G  0 disk 
└─vg_test-lv_test
                 253:2    0    2G  0 lvm  /mnt/data3
sr0               11:0    1 12.7G  0 rom  /run/media/danny/RHEL-9-7-0-BaseOS-x86_64
nvme0n1          259:0    0   20G  0 disk 
├─nvme0n1p1      259:1    0  600M  0 part /boot/efi
├─nvme0n1p2      259:2    0    1G  0 part /boot
└─nvme0n1p3      259:3    0 18.4G  0 part 
  ├─rhel-root    253:0    0 16.4G  0 lvm  /
  └─rhel-swap    253:1    0    2G  0 lvm  [SWAP]
```
User input:
- Mount point: /mnt/data2
- Disk: /dev/sdb
- Confirm overwrite: y
- VG: vg_migration1
- LV: lv_migration1

🧠 Technical Insight
🔥 Key Problem Solved: device or resource busy
- Direct pvcreate fails on mounted partitions
- Solution:
```bash
umount -l
```
⚠️ Data Safety
- Full disk overwrite
- Requires explicit user confirmation

📦 Scenario 3: Online LVM Extension (Same Disk)
🎯 Objective

Extend existing LVM /mnt/data3 from 1G → 2G
```bash
[danny@rhel /]$ sudo ./lvm_std_extend.sh
请输入挂载点路径 (例如 /mnt/data3): /mnt/data3
🔍 场景识别: [3] 已是 LVM 卷 (/dev/mapper/vg_test-lv_test) - 准备扩容
------------------------------------------------
/dev/sda                           5G disk 
/dev/sdb                           5G disk 
/dev/sdc                           5G disk 
/dev/nvme0n1                      20G disk 
请输入要使用的物理磁盘 (例如 /dev/sdb): /dev/sda
📦 目标物理卷组: vg_test
  Physical volume '/dev/sda' is already in volume group 'vg_data1'
  Unable to add physical volume '/dev/sda' to volume group 'vg_data1'
  /dev/sda: physical volume not initialized.
增加的大小 (例如 +1G): +1G
  File system xfs found on vg_test/lv_test mounted at /mnt/data3.
  Size of logical volume vg_test/lv_test changed from 1.00 GiB (256 extents) to 2.00 GiB (512 extents).
  Extending file system xfs to 2.00 GiB (2147483648 bytes) on vg_test/lv_test...
xfs_growfs /dev/vg_test/lv_test
meta-data=/dev/mapper/vg_test-lv_test isize=512    agcount=4, agsize=65536 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=262144, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=16384, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 262144 to 524288
xfs_growfs done
  Extended file system xfs on vg_test/lv_test.
  Logical volume vg_test/lv_test successfully resized.
------------------------------------------------
Filesystem                  Type  Size  Used Avail Use% Mounted on
/dev/mapper/vg_test-lv_test xfs   2.0G   47M  1.9G   3% /mnt/data3
✅ 任务完成！
[danny@rhel /]$ sudo vgs vg_test
  VG      #PV #LV #SN Attr   VSize  VFree 
  vg_test   1   1   0 wz--n- <5.00g <3.00g
[danny@rhel /]$ df -h /mnt/data3
Filesystem                   Size  Used Avail Use% Mounted on
/dev/mapper/vg_test-lv_test  2.0G   47M  1.9G   3% /mnt/data3
```
