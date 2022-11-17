# makefile 中符号


- "="

“=”是最普通的等号，然而在Makefile中确实是最容易搞错的赋值等号。使用”=”进行赋值，变量的值是整个makefile中最后被指定的值

```sh
VIR_A = A
VIR_B = $(VIR_A) B
VIR_A = AA
```

经过上面的赋值后，最后VIR_B的值是AAB，而不是AB。在make时，会把整个makefile展开，拉通决定变量的值

- “:=”

”:=”就表示直接赋值，赋予当前位置的值

```sh
VIR_A := A
VIR_B := $(VIR_A) B
VIR_A := AA
```

最后，变量VIR_B的值是AB，即根据当前位置进行赋值。因此相比于”=”，”:=”才是真正意义上的直接赋值。

- “?=”
 
“？=”表示如果该变量没有被赋值，则赋予等号后的值。举例：

```sh
 VIR ?= new_value
```

如果VIR在之前没有被赋值，那么现在VIR的值就为new_value

```sh
VIR := old_value
VIR ?= new_value
```

这种情况下，VIR 的值就是 old_value

- “+=”

“+=”和平时写代码的理解是一样的，表示将等号后面的值添加到前面的变量上

# makefile 打印调试

```sh
# info 是不带行号的
$(info “here is debug")

# warning 是带行号的
$(warning “here is debug")

# error 停止当前makefile的编译
$(error “here is debug")
```



