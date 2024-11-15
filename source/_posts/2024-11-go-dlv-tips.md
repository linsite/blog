---
title: go debug tips
date: 2024-11-15 20:16:31
tags:
- go
- debug
- gdb
---

When asking GPT, it's anwser is very obscure, like how print a variable without switch
to the stack frame, really frustrating. When we examine a core file, there is no way to switch to 
none-stack variables. So after some study, I found the right ways, recording them as such.

<!--more-->

The first tip, I learn that from dlv github repository document. It should be like this:

> p "github.com/xx/my/pkg".localVar"


Do remember the quote should be ", not ';


The second is how to use gdb Python extention. I use that to examine the Go's mspan status.

You can add it to the $GOROOT/src/runtime/runtime-gdb.py, then using following command to invoke
it in gdb.

```
source $GOROOT/src/runtime/runtime-gdb.py
info spans
```

```py

class SpanCmd(gdb.Command):
        "List all spans."

        def __init__(self):
                gdb.Command.__init__(self, "info spans", gdb.COMMAND_STACK, gdb.COMPLETE_NONE)

        def invoke(self, _arg, _from_tty):
                mheap = gdb.parse_and_eval("'runtime.mheap_'")
                for ptr in SliceValue(mheap['allspans']):
                        if find_bad(ptr):
                                break


def bitValue(obj, i):                            
    vp = gdb.lookup_type('uint8').pointer()         
    return int((obj.cast(vp) + i).dereference())    
                                                                 
                                                          
def find_bad(span):                          
    free = span['freeindex']            
    mark = span['gcmarkBits']                  
    alloc = span['allocBits']
    nelems = span['nelems']      
    if free >= nelems:  
        return                        
    obj = free                
    count = 0                                        
    bitMark = bitValue(mark, obj / 8)                       
    bitAlloc = bitValue(alloc, obj / 8)                              
    start = span['startAddr']                                              
    end = start + span['elemsize'] * nelems
    if start < 0xc0005dff00 and 0xc0005dff00 < end:
        print('found', hex(start), hex(end), 'elemsize', span['elemsize'])
        if (bitMark & ~bitAlloc) >> (obj % 8) != 0:
            print(mark.address, alloc.address)
            return True
        round = int((nelems + 7)) // 8
        for i in range(obj / 8 + 1, round):
            bitMark = bitValue(mark, i)
            bitAlloc = bitValue(alloc, i)
            if (bitMark & ~bitAlloc) >> (obj % 8) != 0:
                print('found bad',i, mark.address, alloc.address)
                continue
        return False
    else:
        return False
    # print(span['gcmarkBits'].type)
```

Cheers.
