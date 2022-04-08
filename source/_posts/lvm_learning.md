---
title: Linux动态扩展LVM分区
date: 2018-6-26  21:19:00
tags: 
- 运维
- Linux
author: Lin
---
## 0x00 LVM介绍
LVM是Linux中一个很有用的特性，可以动态地扩展磁盘逻辑分区的大小，而不会对磁盘上已有的数据造成影响。下面是整个操作的流程。
## 0x01 查看要添加的磁盘
```
[root@localhost ~]# ls /dev/sd*
/dev/sda /dev/sda1 /dev/sda2 /dev/sdb /dev/sdb1 /dev/sdc
```
目标是sdc

## 0x02 对其进行分区

使用CentOS中的命令fdisk

<!--more-->
```
[root@localhost ~]# fdisk /dev/sdc
Device contains neither a valid DOS partition table, nor Sun, SGI or OSF disklabel
Building a new DOS disklabel with disk identifier 0x9b098cfe.
Changes will remain in memory only, until you decide to write them.
After that, of course, the previous content won't be recoverable.

Warning: invalid flag 0x0000 of partition table 4 will be corrected by w(rite)

WARNING: DOS-compatible mode is deprecated. It's strongly recommended to
         switch off the mode (command 'c') and change display units to
         sectors (command 'u').
<!--more-->
Command (m for help): n
Command action
   e   extended
   p   primary partition (1-4)
p
Partition number (1-4): 1
First cylinder (1-522, default 1): 
Using default value 1
Last cylinder, +cylinders or +size{K,M,G} (1-522, default 522): 
Using default value 522

Command (m for help): t
Selected partition 1
Hex code (type L to list codes): 8e
Changed system type of partition 1 to 8e (Linux LVM)

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks
```
## 0x03 查看现有的逻辑卷组
```
[root@localhost ~]# vgs -a
VG #PV #LV #SN Attr VSize VFree
VolGroup 2 2 0 wz--n- 15.50g 2.00g

[root@localhost ~]# df -h
Filesystem                    Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root   13G  727M   12G   6% /
tmpfs                         499M     0  499M   0% /dev/shm
/dev/sda1                     485M   32M  428M   7% /boot
```
现在有2个逻辑卷，目标是把/dev/mapper/VolGroup-lv_root这个逻辑卷再增大一个/dev/sdc的空间。
## 0x04 创建物理卷
```
[root@localhost ~]# pvcreate /dev/sdc1
  dev_is_mpath: failed to get device for 8:33
  Physical volume "/dev/sdc1" successfully create
```
不知道为什么会有报错，但不影响。
## 0x05 添加物理卷到目标卷组
```
[root@localhost ~]# vgextend VolGroup /dev/sdc1
  Volume group "VolGroup" successfully extended
```
## 0x06 扩展目标逻辑卷
因为加的磁盘大小为4G，为了实验。所以扩展空间也是4G
```
[root@localhost ~]# lvextend -L +4G /dev/VolGroup/lv_root 
  Extending logical volume lv_root to 16.71 GiB
  Logical volume lv_root successfully resized
```
## 0x07 增长文件系统
如果分区的FS类型为ext系的话，使用的命令是resize2fs, 如果是xfs的话，使用的命令是xfs_growfs
```
[root@localhost ~]# resize2fs /dev/VolGroup/lv_root 
resize2fs 1.41.12 (17-May-2010)
Filesystem at /dev/VolGroup/lv_root is mounted on /; on-line resizing required
old desc_blocks = 1, new_desc_blocks = 2
Performing an on-line resize of /dev/VolGroup/lv_root to 4380672 (4k) blocks.
The filesystem on /dev/VolGroup/lv_root is now 4380672 blocks long.
```
再次查看df
```
[root@localhost ~]# df -h
Filesystem                    Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root   17G  728M   15G   5% /
tmpfs                         499M     0  499M   0% /dev/shm
/dev/sda1                     485M   32M  428M   7% /boot
```  
