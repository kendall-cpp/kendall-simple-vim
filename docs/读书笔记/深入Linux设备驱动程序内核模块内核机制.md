

-------

## 内核模块

### 模块加载过程

也就是使用 insmod demodev.ko 这样命令来向内核安装一个内核模块的加载过程

- sys_init_module

```c
asmlinkage long sys_init_module(void __user *umod, unsigned long len, 
        const char __user *uargs);

// umod 向指定用户空间 demodev.ko 文件映像数据的内存地址
// len 该文件的数据大小
// uargs 传给模块的参数在用户空间下的内存地址
```

sys_init_module 主要通过调用 load_module 函数来完成的

```c
static int load_module(struct load_info *info, const char __user *uargs,  int flags)
```

先来看加载模块时使用的一个非常重要的数据结构 struct module

- enum module_state state 用来记录模块加载郭晨不同阶段的状态
- struct list_head list 用来将模块链接到系统维护的内核模块链表中，内核用一个链表来管理系统中所有被成功加载的模块。
- char name[MODULE_NAME_LEN] 模块的名称
- const struct kernel_symbol *syms 内核模块导出的符号所在起始地址
- 
