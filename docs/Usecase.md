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


