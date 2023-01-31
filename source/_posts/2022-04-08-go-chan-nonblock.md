---
title: Go非阻塞通道探究
date: 2022-04-08 20:33:26
author: linlin
tags:
- go
catergories:
- 编程语言
description: Go 非阻塞通道的研究。
---

## 0x01 通道阻塞介绍

了解Go的同学都清楚，无论通道是有无缓冲的，发送或者接收某些场景下都有可能阻塞。

对于无缓冲： 
* 默认阻塞，直到对方也准备好接收或者发送。

有缓冲：
1. 通道满了，发送阻塞。
2. 通道空了，接收阻塞。

有意思的是，Go里提供了基本的非阻塞接收方式，但没有提供非阻塞的发送方式。
可以使用如下方式非阻塞接收。通过判断返回的ok确认，是否真的接收到元素了。

```go
a, ok := <- ch
```

所以在这里抛出问题，如何以高效非阻塞方式发送一个元素呢？

<!--more-->
## 0x02 非阻塞方式发一个元素

第一个想到的是，通过select调用，很简单，代码如下：

```go
select {
    case ch <- 3:
        break
    default:
    }
}
```

一开始理解这里应该是没有加锁操作，因为select上下文中，发送操作是非阻塞的，可以从源码中得到印证，来自`runtime/chan.go`中。通过注释知道，select中send操作最终对应的是`selectnbsend`函数，而它会调用`chansend`，传入的第3个参数是指定是否阻塞，值为`false`，即非阻塞的。

```go
func selectnbsend(c *hchan, elem unsafe.Pointer) (selected bool) {
	return chansend(c, elem, false, getcallerpc())
}
```

chansend中的fastpath如下。就是说，当通道已满的情况下，直接返回了`false`，告知select当前分支未准备好。而且从注释可以得知，这里没有加锁，看起来非常高效。

```go
	if !block && c.closed == 0 && ((c.dataqsiz == 0 && c.recvq.first == nil) ||
		(c.dataqsiz > 0 && c.qcount == c.dataqsiz)) {
		return false
```

当然还有个前提没厘清。就是select是怎么实现的，如果它也没有加锁，那么就可以确认是真的没有加锁操作。select的实现就在`runtime/select.go`中。从函数`selectgo`一路看下去，感觉没发现问题，虽然看的不是很懂。直到看到下面一条语句和注释。

```go
	// lock all the channels involved in the select
	sellock(scases, lockorder)
```

额，原来还是有加锁。
而且看到加锁前还有那么多操作，感觉select没有想象中的那么高效。有更合适的方式吗？

想了下，可以自己判断通道是否满了，没满的话，就向里面放元素，可以最大可能避免调用select。这种方式最合理，不过看起来不是那么好看优雅。而且前提是，这是一个有缓冲的通道。

```go
if len(ch) < cap(ch) {
    select {
        case ch <- 3:
            break
        default:
    }
}
```


## 0x03 小结与后记

可以通过以下2种方式之一实现向有缓冲通道中非阻塞方式发元素。

1. 使用select方式，但会有额外锁操作。
2. 要求高的话，可以和长度判断一起用。


梳理过程中，又发现一个问题。按照官方文档里描述的select会随机选择一个就绪的分支执行，没有找到的话，走default。这里感觉像是，select会把各个case遍历一次，找出就绪的，然后从当中选一个。

真正看过别人总结的文档后，发现上面的理解有偏差。它是把case顺序打乱，然后遍历，找到一个就绪的就返回了。参考[https://draveness.me/golang/docs/part2-foundation/ch05-keyword/golang-select/](https://draveness.me/golang/docs/part2-foundation/ch05-keyword/golang-select/)。

## 0x04 参考文档

1. [Go语言设计与实现](https://draveness.me/golang/docs/part2-foundation/ch05-keyword/golang-select/)

