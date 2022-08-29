

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
- 
