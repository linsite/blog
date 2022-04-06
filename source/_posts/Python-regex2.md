---
title: 读书笔记-Python正则表达式2
date: 2017-06-21 21:00:38
tags:
- 正则表达式
author: Lin
---
上一篇中介绍了Python中基本的表达式。这些文字都是学习Python核心编程时，做下的一些笔记，只挑个人认为有意思的地方。这次来到15.2.6节，介绍的是比较高级的一些知识点：闭包操作。
<!--more-->
## 什么是闭包
上学时，出于兴趣曾经自学过编译原理，这门学科真的不是一般的枯燥，许多概念是相当抽象。闭包也是其中的一个。这个概念是用来描述token组成的。后来的JavaScript和Python语言中也出现了闭包，只是这些语言中的闭包与编译原理和正则表达式里的闭包不再是一个概念了。
* 正则表达式/编译原理中的闭包Kleene
指的一个字符集｛A｝中，任意元素可以组成的字符串的集合，就叫做闭包。我们知道，C语言、Python对其变量名都有一定的要求，只能是数字、下划线(_)、和字母的组成的字符串，比较适合用闭包来描述。同样正则表达式里，如果对字符进行匹配时，会用到的*，+，？，{}进行多次匹配与闭包的概念一样，所以才会有这样的叫法。
* 编程语言里的闭包Closure
JS闭包是指那些可以访问自由变量的函数。自由变量指在函数中使用的，但既不是函数参数也不是函数局部变量的变量。个人认为JS中的闭包是比较有趣的一个地方。
Python中的闭包概念跟JS中的一样。Python与JS一样的地方是，函数也是对象。Python里面最典型的闭包就是装饰器。
```
def wrapper(func):
	def inner(*args, **kwargs):
		return func
	return inner
```
在wrapper函数中返回了inner函数，形成了一个闭包。

## ?的两种含义
* ?单独出现时，表示匹配前面的字符1次或者0次。
* 如果跟在+，表示重复的字符的后面时，表示要求匹配尽可能少的字符。也就是上一篇中提到的非贪婪模式。
书中说到这里，没有立马举一个非贪婪模式的例子，而是把例子放到了本章的最后中。这一点有点不太合适。
我把例子提前看了，加深对这两种模式的理解。
贪婪模式下，可以看到.*会把6之前的数字全部匹配走。
```
>>> patt = '.*(\d+-\d+-\d+)'
>>> data = 'Thu Feb 15 17:46:04 2007::uzifzf@dpyivihw.gov::1171590364-6-8'
>>> re.match(patt, data).group(1)
'4-6-8'
```
当在*后加上了？后，变为了非贪婪模式，就只匹配到了::结束的位置
```
>>> patt = '.*?(\d+-\d+-\d+)'
>>> re.match(patt, data).group(1)
'1171590364-6-8'
```
通过上面这个例子，可以看出，非贪婪模式下，.*匹配的优先级会低于\d+。我们知道.*的匹配范围是比\d+要大的，可以这样理解，非贪婪模式下，小范围匹配单元优先级高于大范围匹配单元。