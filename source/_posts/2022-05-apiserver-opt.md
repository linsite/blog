---
title: k8s-apiserver调优
date: 2022-05-11 22:32:05
tags: 
  - k8s
  - apiserver
author: linlin
description: k8s APIServer 的相关选项总结。
---

apiserver设计比较复杂，直接去看源码效果较差。尝试从特性角度梳理其设计背后的考量。

了解一个服务最好的入口就是看它的选项。选的版本是v1.21.5。

## 0x01 选项

选项分为如下几类：

1. 通用标志(Generic flags) *
2. 与Etcd相关的配置 *
3. 安全配置
4. 审计配置
5. 特性配置
6. 认证配置
7. 授权配置
8. 云提供商配置
9. API开关配置
9. 网络出口配置
10. 准入配置
11. metrics配置，用于监控
12. 日志配置 *
13. 其他杂项配置 *

加`*`的为影响性能的参数。为重点学习项。

## 0x02 详细各部分配置

### 2.1 通用配置

看下顶级社区项目是如何考虑性能和可靠性的。整体感觉是非常灵活，把决定权交给使用者。

`--goaway-chance`
一定机率，随机关掉一个客户端的连接，防止其卡死，强制重连。不影响正常执行的客户端连接。当然这会牺牲一定的性能。
<!--more-->

`--max-mutating-requests-inflight`
同一时刻修改类的请求数量上限。限流熔断机制，防止大量请求把服务打跨，设计上可以借鉴下其实现。
`--max-requests-inflight`
同一时刻非修改类请求数量上限。同上。
`--livez-grace-period`
从服务启动到`livez`正常的时间。超出后，认为那些post start Hook不影响apiserver的功能。
`--min-request-timeout`
最小请求超时时间，watch请求连接适用。
`--request-timeout`
服务商认定的请求超时时间。
`--shutdown-delay-duration`
优雅退出时的延迟时间。这段时间里，通过设置`/readyz`返回`false`不再从LB接收新请求，同时`/healthz`和`/livez`正常返回，防止被kubelet杀死。已经在处理的请求，还正常完成。
`--feature-gates`
开关特性，默认会开启很多特性。特性越多，资源消耗（计算、内存）就越多，可以适当关闭不需要的特性。

### 2.2 Etcd相关的配置

apiserver是整个系统的核心，所有的其他组件都在与其通信。很容易成为性能的瓶颈点。通过Etcd配置看如何调优，需要使用者在资源使用和性能两者之间抉择。

`--default-watch-cache-size`
监听缓存数量，默认是100。某些场景性能不是关键考虑点时，可以设置为0禁掉。

`--delete-collection-workers`
清理worker数量。同样，为减少消耗，不关注清理速度时，默认的1即可。

`--enable-garbage-collector`
开启GC，用来清理没有关联的孤立资源，不是Go的GC。默认是开启的，不开启需要确认是真的不需要了。

`--etcd-db-metric-poll-interval`
etcd监控选项，有别的监控手段时，也可以关闭。

`--etcd-compaction-interval`
压缩间隔。可以节省磁盘空间，但会占用一定的CPU。需要考虑选择合适的数值。

`--etcd-healthcheck-timeout`
健康检查。不敏感时，可适当调大一些，默认为2秒。

`--lease-reuse-duration-seconds`
lease的重用间隔，本身是为用于节省lease资源。默认60，太小会影响性能，太大会造成个对象共用一个lease，两者失效相互干扰。

`--storage-media-type`
存储的类型，默认是protobuf，紧凑型的，更高效。不需要修改。

`--watch-cache`
开启watch缓存。性能不关心，但在意内存使用量时，可以关闭。

`--watch-cache-sizes`
指定不同资源的watch缓存数量。

### 2.3 日志

`--experimental-logging-sanitization`
日志脱敏，过滤掉密码、serect等敏感信息。会耗费一定的计算，某认关闭。

`--logging-format`
日志格式。默认为string。个人理解如果设置为json时，相对string格式json的序列化会有额外的计算消耗。


### 2.4 杂项

`--event-ttl`
事件保留的时间。默认为1h，k8s运行过程中，产生许多事件，事件的保存会消耗一定的内存资源，可以根据需要调节。

`--identity-lease-renew-interval-seconds`
更新自己的lease的周期。对性能有一定影响，太高会对etcd造成压力。

`--max-connection-bytes-per-sec`
限制长连接的流量，会影响性能，但可以保证整体的可用性。默认不限制。


## 0x03 小结

顶级开源项目要考虑各种使用场景，不能给出普适的模型，如资源消耗与性能的平衡。所以尽可能各方面都可配置，让使用者自己去选择（trade-off）。了解这些参数，对apiserver调优有一定的参考意义。同时可借鉴其设计上的优点，如优雅退出；如某个参数可能影响影响性能，就提供一个配置项。
