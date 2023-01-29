---
title: 树莓派2B安装Realtek 8188GU 无线网卡驱动
date: 2023-01-29 17:47:50
tags:
  - Linux
  - Raspberry
  - 树莓派
  - 驱动
---


<!--more-->

旧的树莓派想重新安装下系统，不小心买了一个8188GU的网卡，结果找了一圈，没 Linux 主线的驱动。在网上找了一波，找到了这个，[https://github.com/McMCCRU/rtl8188gu](https://github.com/McMCCRU/rtl8188gu)，看起来风评还不错。试了下，最终因为CPU资源占用高没用，把这个网卡退了，没有精力去研究驱动的问题。这里记录下编译使用过程的问题，希望能帮到需要的同学。


主要有以下3个问题：

1. 最新的 raspbian 内核为`Linux version 5.15.84-v7+`，想编译驱动，需要找对应的源码，官方apt仓库中还没有。需要去github上下载，[https://github.com/raspberrypi/linux](https://github.com/raspberrypi/linux)。教程见[https://forums.raspberrypi.com/viewtopic.php?t=342491](https://forums.raspberrypi.com/viewtopic.php?t=342491)。
2. 编译时出错提示 "No rule to make target 'scripts/module.lds"。原因是没有在源码中执行`make modules_prepare`。
3. 安装好驱动，成功连上了 Wifi。但有个问题，有个内核线程"RTW_CMD_THREAD"，一直在跑，占了快一个核心，这我接受不了。所以还是退了吧。


