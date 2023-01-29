---
title: TCP/IP协议栈工作流1
date: 2016-12-20 21:16:02
tags:
- TCP/IP
- 操作系统
- Linux
categories:
- Linux
- TCP/IP
author: Lin
---

转自[我的CSDN](http://blog.csdn.net/u012520854/article/details/53750338)
### 1、引子
在C语言里，想要使用TCP/IP协议来实现一个客户端，必须要遵循以下步骤：
#### 1）创建一个socket
```
int socket(int family, int type, int protocol)
```
函数需要三个参数，分别是协议族的编号，socket的类型，和具体的协议类型。如果初始化时还有印象的话，我们的TCP/IP协议族属于PF_INET,而TCP socket则属于STREAM_SOCK，protocol这个参数一般是0,使用系统中该socket默认的协议类型。如STREAM_SOCK对应的默认协议就是TCP协议。这里只是内核里面的宏，具体到函数库中，可能会有别的表现形式。
函数执行完成，没有错误时，会返回一个int类型的变量，这个变量是socket的ID，与文件ID类似，后续的工作，都是通过对它的引用来开展的。
<!--more-->
#### 2）调用connect函数来连接到远程的服务器。
```
int connect(int sockfd, const struct sockaddr * addr, socklen_t addrlen) ```
sockfd 就是1）中生成的socket ID。
addr 类型为struct sockaddr，用来描述一个socket的数据结构。这里addr表示要连接的远程服务器的socket描述，包括其服务器的IP地址和端口。
当connect调用完成，没有发生错误时，socket已经完成了TCP/IP协议中的三次握手与服务器端的socket建议了连接。
我感兴趣的是TCP/IP如何完成的这样的一个过程。有了前面的初始化的基础，梳理它的工作流程显得没有那么困难。
### 2、创建
socket创建函数来自于一个glibc中，glibc是GNU版本的C函数库。C程序里的socket函数怎么到的系统调用，暂且不说。目前只需要最后进入内核的途径如下：
```
sys_socketcall(call, args) 			net/socket.c 2004
sys_socket(a0, a1, a[2])			net/socket.c 1202
sock_create(family, type, protocol, &sock)	net/socket.c
sock_map_fd(sock)				net/socket.c
```
我们假定传入的参数就是(PF_INET, STREAM_SOCK, 0)。
通过对ICMP协议初始化时的分析，我们知道，最终是sock_create是创建的socket。而后面的sock_map_fd(sock)只是把sock和一个文件关系起来，记得socket函数返回的是一个类似文件的ID。而sock_create返回的是 创建是否成功的标识。关于sock_create的流程有必要再次梳理下，因为这次要创建的是TCP类型的socket。
sock_create定义在net/socket.c中，它只是一个包装，真正调用的是__sock_create。传入的参数在ICMP初始化时已经说过不再说明。同样根据参数family解引用，从net_families数组中得到struct net_proto_family类型的变量inet_family_ops。最后执行的是inet_create函数。此时不同的是传入的参数不再一样了。
inet_create(struct net *net, struct socket *sock, int protocol);
此时，由于已经进入到inet内部，family参数已经不再需要了。type参数被包含进入sock中，protocol仍然是0。
``` 244 static int inet_create(struct net *net, struct socket *sock, int protocol)
245 {
246 	struct sock *sk;
247 	struct list_head *p;
248 	struct inet_protosw *answer;
249 	struct inet_sock *inet;
250 	struct proto *answer_prot;
251 	unsigned char answer_flags;
252 	char answer_no_check;
253 	int try_loading_module = 0;
254 	int err;
256 	if (net != &init_net)
257 		return -EAFNOSUPPORT;
259 	if (sock->type != SOCK_RAW &&
260 	    sock->type != SOCK_DGRAM &&
261 	    !inet_ehash_secret)
262 		build_ehash_secret();
264 	sock->state = SS_UNCONNECTED;
267 	answer = NULL;
268 lookup_protocol:
269 	err = -ESOCKTNOSUPPORT;
270 	rcu_read_lock();
271 	list_for_each_rcu(p, &inetsw[sock->type]) {
272 		answer = list_entry(p, struct inet_protosw, list);
275 		if (protocol == answer->protocol) {
276 			if (protocol != IPPROTO_IP)
277 				break;
278 		} else {
280 			if (IPPROTO_IP == protocol) {
281 				protocol = answer->protocol;
282 				break;
283 			}
284 			if (IPPROTO_IP == answer->protocol)
285 				break;
286 		}
287 		err = -EPROTONOSUPPORT;
288 		answer = NULL;
289 	}
313 	err = -EPERM;
314 	if (answer->capability > 0 && !capable(answer->capability))
315 		goto out_rcu_unlock;
317 	sock->ops = answer->ops;
318 	answer_prot = answer->prot;
319 	answer_no_check = answer->no_check;
320 	answer_flags = answer->flags;
```
此时需要详细说下这个函数了。
256 	同样是判断是不是属于init_net命名空间的socket，如是不是返回吧，不支持。
269-262	判断参数type的类型。如果既不是SOCK_RAW又不是SOCK_DGRAM，又没有建议过ehash的话，就悄悄地建立了一个散列。也就是说TCP socket也是需要建立这个散列的。也就是SOCK_RAW和SOCK_DGRAM这两种类型是不需要这种散列的。如果前面初始化有印象的话，这里建立的散列是为有连接状态的socket建立的。SOCK_RAW和SOCK_DGRAM都是无状态连接，所以不需要。
264	设置sock的状态为SS_UNCONNECTED，意为未连接。SS代表socket state。此时还没有创建完成，所以是未连接状态。
270-289	同样是一个协议的查找过程。此时sock->type为SOCK_STREAM,所以最后检索到的answer如下：
```
{
913 		.type =       SOCK_STREAM,
914 		.protocol =   IPPROTO_TCP,
915 		.prot =       &tcp_prot,
916 		.ops =        &inet_stream_ops,
917 		.capability = -1,
918 		.no_check =   0,
919 		.flags =      INET_PROTOSW_PERMANENT |
920 			      INET_PROTOSW_ICSK,
921 	}
```
314-320	同样用得到的answer来初始化sock的成员变量ops，同时记录其他成员到中间变量中。
inet_create上半部分又说完了。
