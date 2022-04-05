---
title: create-vue-app
date: 2022-04-06 00:01:36
tags:
---

## 0x01 背景

本人不是专门的前端开发人员，对js的理解一般。这个小应用是出于兴趣。起因是一个好朋友在带娃时，经常会在朋友圈出一些24点的题目，就是拿出4张扑克牌，通过加减乘除能否算出24来。我觉得这个题目可以用Python来实现。简单试了下，确实可以。不过Python写的，想要分享给别人的话，还要起一个服务，不是很方便。而js就很适合这样的场景。


单纯地觉得这样的小应用挺有趣的，可能没什么具体的用途。哈哈。


## 0x02 算法

算法也很简单，就是暴力循环递归求解，也不是最低级的那种。根据提供的4个数，依次查找与24的关系，最终找出一个合法的表达式来。

具体的算法描述如下：

函数的初始输入为：  
定义target=24，数组内容为[a1, a2, a3, a4]。

函数find定义如下，通过递归调用，找到一个解。针对和小孩做游戏的这个场景来说，找到一个解就足够了，感兴趣的同学可以试下找到所有的解。

1. 判断数组长度。为2，进入步骤2；否则进入步骤3。
2. 直接判断x，y与target的基本数学运算关系，不能找到返回空串；找到时，返回对应的表达式。
3. 取出左边第1个数x，判断target与其关系，先判断整除，可以整除，进入步骤4。
4. 如果可以被整除，tagert=target/x或者target=x/target，调用find，有结果时跳转10；不能整除进入第5步。
5. 判断taget与x的关系。大于，进入步骤6。小于时，步骤7。相等步骤8。
6. target=target-x，调用find，能找到结果时跳转10，不能找到时，继续第7步。
7. target=x-target，调用find，能找到结果时跳转10，不能找到时，继续8步。
8. target=x*target，调用find，能找到结果时跳转10。不能找到结果时，继续第9步。
9. target=x+target，调用find, 能找到结果时跳转10，不能找到时返回空。
10. 判断返回结果是否有效，而且当前的数组长度是否为4，是返回。不是，返回输出结果。


## 0x03 实现

js里实现这个算法也不复杂。
具体代码见：[24point.html](https://github.com/linsite/24point/blob/main/index.html)

作为非前端人员，对vue有一点点了解，这里基于vue来实现交互。原因很简单，这种输入变化后立刻给出响应的场景非常适合用vue这种模型数据绑定的技术。一个简单的应用，期望是输入的数字刚好是4个时，就立马能计算结果。当输入有更新时，也能及时更新结果。如果需要额外按一个按钮的话，就太low了。

页面布局是抄的Boostrap的示例。我们来定义的一个表格。它的父div，定义了id为app，用来与vue绑定。
输入为cards，输出为result，都通过`v-model`指令和form的输入框绑定起来。

```
        <div class="container" id="app">
            <div class="row">
                <nav class="navbar navbar-expand-lg navbar-light">
                    <a class="navbar-brand" href="#">首页</a>
                  </nav>
                
            </div>
            <div class="row align-items-start mx-auto" >
                <form class="form-horizontal" role="form">
                    <div class="alert alert-success">
                        输入4张扑克牌的点数：如2 3 5 8
                      </div>
                    <div class="form-group row">
                        <label class="col-5">4张扑克牌</label>
                        <div class="col">
                            <input type="text" v-model="cards" class="form-control" id="cards" value="">
                        </div>
                    </div>
                    <div class="form-group row">
                        <label class="col-5">结果</label>
                        <div class="col">
                            <input type="text" v-model="result" class="form-control">
                        </div>
                        
                    </div>
                    
                    
                </form>

            </div>
```

js部分的代码如下，通过watch机制，监听输入的变化，当输出的长度等于4时，就调用find函数计算结果。把计算的结果更新到result中。

```
            var app = new Vue({
                el: '#app',
                data: {
                    show: 'get',
                    cards: '',
                    result: '',
                },
                watch: {
                    cards: "cardsUpdated",
                },
                methods: {
                    cardsUpdated: function(newVal, oldVal) {
                        var stripped = newVal.trim();
                        var array = stripped.split(" ");
                        var args=[];
                        if (array.length == 4) {
                            for (i = 0; i < 4; i++) {
                                j = parseInt(array[i])
                                if (isNaN(j)) {
                                    return;
                                }
                                args[i] = j;
                            }
                            ret = find(args, 24);
                            if (ret.length > 0) {
                                app.result = ret + "=24";
                            } else {
                                app.result = "没有找到";
                            }
                        } else {
                            console.log("len: " + array.length)
                        }
                    }
                }
            });
```

最终的页面效果如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/4d7bd8bbf549413db06ef666e1fd22db.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5p6XaG9uZw==,size_20,color_FFFFFF,t_70,g_se,x_16)


## 0x04 部署

这种单页面不需要后端的应用部署起来就非常简单了。直接放到了我的github page上了。访问如下链接，即可看到效果。

[24point](https://blog.tkfun.site/fun/24point/)

## 0x05 总结

之前搞网络安全时学习的js都是用来测试XSS了，理解一般。这个小应用的编写过程中，踩了一些坑比如注释里提到使用var和不使用var的区别。总体来说还是达到了目标了，对js和vue的理解都有了一定的提升。代码在[github](https://github.com/linsite/24point)上，也欢迎感兴趣的同学围观批评。

