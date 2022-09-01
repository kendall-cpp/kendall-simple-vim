

-------

> linux-2.6.39

## 内核模块

### 模块加载过程

也就是使用 insmod demodev.ko 这样命令来向内核安装一个内核模块的加载过程

insmod 会首先利用文件系统的接口将其数据读取到用户空间的一段内存中，然后通过系统调用 sys_init_module 让内核去处理模块加载的整个过程。

**sys_init_module**

```c
static struct module *load_module(void __user *umod,                                                                                                                               
          unsigned long len, 
          const char __user *uargs)

// umod 向指定用户空间 demodev.ko 文件映像数据的内存地址
// len 该文件的数据大小
// uargs 传给模块的参数在用户空间下的内存地址
```

sys_init_module 有两部分工作

1. 调用 load_module 完成模块加载最核心的任务

2. 在模块被成功加载到系统之后的后续处理

- 调用 load_module 完成模块加载最核心的任务

```c
static struct module *load_module(void __user *umod, unsigned long len, const char __user *uargs)
```

先来看加载模块时使用的一个非常重要的数据结构 struct module

- enum module_state state 用来记录模块加载郭晨不同阶段的状态
- struct list_head list 用来将模块链接到系统维护的内核模块链表中，内核用一个链表来管理系统中所有被成功加载的模块。
- char name[MODULE_NAME_LEN] 模块的名称
- const struct kernel_symbol *syms 内核模块导出的符号所在起始地址
- int (*init)(void)  指向内核模块初始化函数的指针，在内核模块源码中由 module_init 宏指定。

#### load_module

- 模块 ELF 静态的内存内视图

用户空间程序 insmod 首先通过文件系统接口读取内核模块 demodev.ko 的文件数据，并将其放在一块用户空间的存储区域中，然后通过系统调用 sys_init_module 进入到内核态，同时将 umod 指针作为参数传递过去。

sys_init_module 调用 load_module , 通过 copy_from_user 函数将用户空间文件数据复制到内核空间中区。从而在内核空间构造出 demodev.ko 的一个 ELF 静态的内存试图（HDR试图）。

- 字符串表

字符串表是 ELF 文件中的一个 section ，用来保存 ELF 文件中各个 section 的名称或符号名。

|  index   | string  |
|  ----  | ----  |
| 0  | null string |
| 1  |  name       |
| 7  |  Variable  |
| 11 |  able      |
| 16 |  able     |
| 24 |  null string  |

字符串表一 '\0' 作为一个字符串的结束标记，由 index 指向的字符串是从字符串表第 index 个字符开始，直到遇到一个 '\n' 标记，如果有且只有一个 '\n'  ，那么 index 指向的就是个空串（null string）。

