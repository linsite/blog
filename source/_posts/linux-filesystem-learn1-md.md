---
title: Linux文件系统学习1
date: 2018-10-10 08:27:52
tags:
- 内核
- Linux
- 文件系统
author: Lin
---

# 0x01 简介
这是学习操作系统中，针对Linux文件系统学习的一些总结。文件系统作为操作系统的一个基础组件之一，承担了与硬盘交
互，数据的持久化实现。其重要性不言而喻。这里我以ext2文件系统代码为样本，一步步探索文件系统的实现与原理。
下面是我理解的文件系统。  
```
文件系统是负责如何在硬盘上存贮、管理数据的。
```
这里的管理，包括删除，新建，目录及文件。
# 0x02 必要的背景
我个人觉得去理解技术发展的历史，一定程度上可以辅助理解一些技术的细节，而且这些技术对于现在的我们来说可能
过于复杂，如果我们从计算机历史追溯的话，发现有些发展是趋势所致，理所当然。比如，加载器和连接器的技术发展过程。
就是因为从手工（打孔卡片）输入计算机指令操作中，遇到的指令
修改操作时，手工修改指令的地址极其繁琐，才慢慢出现了机器自动重定位，进而演变出现在的加载器和定位器。
插入一句相对无关的话，在现代操作系统技术成熟之前，其他基础技术，在西方计算机工业中已经很成熟了，这些已经成熟的技术中就包含有文件系统技术。  
文件系统的背景介绍同时依赖，块设备，下面介绍下块设备。

<!--more-->
## 2.1 块设备
块设备属于一种存贮设备，支持按块存取数据。以前流行的软件，现在的机械硬盘，固态硬盘，USB移动U盘都属于块设备。
以目前的技术水平来说，软盘的容量相对硬盘要小的多，它的块大小是512Byte，现在主要硬盘块大小都是1024Byte。  
块设备只提供了一个存贮空间，就如同图书馆里的空房子一样，可以用来存放书（数据），你想怎么存都可以，
你可以分出一些小区域（分区），也可以放一些书架（目录）。怎么存放与管理书，就像是文件系统对于块设备一样。  
块设备为存贮和管理大量数据提供了可能。
## 2.2 文件系统的历史
油管上Crash Cource of Computor Science里面详细介绍了文件系统的历史。感兴趣的可以看下，这里我只简要介绍下。  
出现块设备以后，人们开始用它来存数据了， 这个时候还没有文件系统。
* 1 将数据转化二进制
* 2 通过串口写入块设备
* 3 需要的时候，从块设备取出。  
* 4 在块设备上加一个标签，说明这里存放了什么数据，是谁在用的  
这样人们发现，一个块设备只能存贮一个文件。而且很难确切知道，这个块设备还有多少空间没有用。
文件系统就应运而生了。文件系统会使用一部分块设备的存贮空间，将块设备的存贮空间如何使用做了
详细的划分。总体上分为2块，元数据空间和数据空间。一块用来存贮关于数据空间使用情况的的信息，另外一部分用来存贮真正的数据。
* 元数据：关于数据的信息，也叫关于数据的数据，metadata，是一个常见到的计算机专业词汇。
* 数据：比如一个文件的内容，所有者，修改时间，大小。  

随着计算机技术的发展出现了许多文件系统格式，常见的有Linux下的extN,Windows下的FAT，NTFS，不同的文件格式适用的操作系统不同，
特点也不同。一个基本的规律是，文件系统支持的特性越多，就越复杂，这里我挑针对Linux开发的第一个文件系统Ext2来介绍，
因为它最简单，这个系列最新的Ext4非常庞大，暂不涉及了。
# 0x03 写文件
write(syscall)
    fdget_pos
    file_pos_read
    vfs_write
        rw_verify_area
        file_start_write:加锁
        __vfs_write
            new_sync_write
                call_write_iter
                    ext2_file_write_iter
                        generic_file_write_iter
                            __generic_file_write_iter
                                generic_file_direct_write
                                    filemap_write_and_wait_range
                                    ext2_direct_IO
                                    blockdev_direct_IO
                                    __blockdev_direct_IO
                                    do_blockdev_direct_IO
                            generic_write_sync
        fsnotify_modify
        add_wchar
        inc_syscw
        file_end_write

# 0x04 加载文件系统
```
mount -t ext2 -o loop a.hd /mnt
```
mount(syscall)
    do_mount
        do_new_mount
            vfs_kern_mount
                mount_fs
                    type->mount

struct super_block *sb:VFS的超级块对象
struct ext2_sb_info *sbi: ext2的超级块描述对象。
struct ext2_super_block *es: ext2位于磁盘上的超级块。
ext2_fill_super:
1. get_sb_block, 加载时用户可以指定sb的块位置，没有设置的，默认在第1个块上（从0开始）
2. 分配struct ext2_sb_info对象。
3. 分配一个block_group锁
4. 关联3个对象。将sbi挂到sp,将sb_block设置到的sbi。
5. 初始化sbi的锁成员
6. 确定块长度
7. 读取磁盘上的超级块
8. 将es关联上sbi的s_es成员
9. 设置加载选项
10. 检查功能项支持情况
11. 根据读取到超级块的信息，重新计算blocksize
12. 根据读到的信息设置sbi的成员
13. 计算块组数量：总可用的块数/每个块组里的块数 + 1
14. 计算为保存块组描述符需要的内存大小：组数量 + 每块中的组描述符数量-1/每块中组描述符数量
15. 为每个组描述符分配了一个字节的s_debts
16. 1091-1101：从磁盘上读入每个组描述符块。
17. 1102-1105：检查各个组描述符是否合法
18. 1111-1123:初始化预留窗口RB的锁，和根节点
19. 1125-1138:各个PERCPU变量的初始化，涉及freeblock,freeinode, dir等计数
20. 1150-1152：赋值3个操作函数集合，超级块的操作函数，导出函数集合，xattr操作函数集合
21. 1160-1176：读取root inode，赋值到sb中（方便VFS从sb直接找到根结点的dentry）。
22. 1182：回写超级块

ext2_iget(struct supber_block *sb, unsigned long ino):读取一个结点
1. 获取节点iget_locked
   1. 新生成的inode，没有数据，只有一个ino编号
2. 调用ext2_get_inode获取到raw inode
3. 1417-1480：根据raw inode信息，设置inode和ei的属性
4. 1482-1520：根据inode的类型设置不同的操作函数集合。根目录的i_op为ext2_dir_inode_operations, i_fop为ext2_dir_operations, i_mapping->a_ops为ext2_aops
