

- [4.Linux内核模块](#4linux内核模块)
	- [Linux内核的编译](#linux内核的编译)
		- [Kconfig](#kconfig)
			- [配置选项](#配置选项)
- [5.Linux文件系统与设备文件](#5linux文件系统与设备文件)
	- [linux 文件系统](#linux-文件系统)
		- [file结构体](#file结构体)
		- [devfs 设备文件系统](#devfs-设备文件系统)
		- [udev](#udev)
- [6.字符设备](#6字符设备)

----

# 4.Linux内核模块

## Linux内核的编译

```sh
#make config（基于文本的最为传统的配置界面，不推荐使用）
#make menuconfig（基于文本菜单的配置界面)
```

内核配置包含的条目相当多，`arch/arm/configs/xxx_defconfig`文件包含了许多电路板的默认配置。只需要运行 `make ARCH=arm xxx_defconfig` 就可以为 xxx 开发板配置内核。

```sh
linux-5.6.14/arch/arm/configs
```

编译模块和方法是

```sh
make ARCH=arm zImage
make ARCH=arm modules
```

执行完上述命令后，在源代码的根目录下会得到未压缩的内核映像 vmlinux 和内核符号表文件 System.map，在 arch/arm/boot/ 目录下会得到压缩的内核映像 zImage，在内核各对应目录内得到选中的内核模块。

使用 make config 或者 make menuconfig 命令后，会生成一个 .config 配置文件，记录哪些被编译进内核，哪些被编译进内核模块。

其过程是：

- 配置工具先分析与体系结构对应 ach/xxx/Kconfig 文件（xxx就是 ARCH 的参数，比如 arm），arch/xxx/Kconfig 文件中会引入一系列的 Kconfig 配置文件，这些 Kconfig 可能是下一层的 Kconfig。

在 drivers/char 目录中包含了 TTY_PRINTK 设备驱动的源代码 drivers/char/ttyprintk.c。而在该目录的 Kconfig 文件中包含关于 TTY_PRINTK 的配置项：

```mk
config TTY_PRINTK
    tristate "TTY driver to output user messages via printk"
    depends on EXPERT && TTY 
    default n
    ---help---
      If you say Y here, the support for writing user messages (i.e.
      console messages) via printk is available.

      The feature is useful to inline user messages with kernel
      messages.
      In order to use this feature, you should output user messages
      to /dev/ttyprintk or redirect console to this TTY.

      If unsure, say N.
```

上述 Kconfig 文件的这段脚本意味着只有在 EXPERT 和 TTY 被配置的情况下，才会出现 TTY_PRINTK 配置项.

选“Y”时会直接将生成的目标代码连接到内核，选“M”时则会生成模块 ttyprintk.ko；如果TTY_PRINTK配置选项被选择为“N”，这不编译。


驱动开发者会在内核源代码的 drivers 目录内的相应子目录中增加新设备驱动的源代码或者在 arch/arm/mach-xxx 下新增加板级支持的代码，同时增加或修改Kconfig配置脚本和Makefile脚本

### Kconfig

例子

```c
config EXT3_FS_SECURITY
	bool "Ext3 Security Labels"   //类型
	depends on EXT3_FS            //依赖属性
	select EXT4_FS_SECURITY       //选择属性
	help                          //帮助属性
	  This config option is here only for backward compatibility. ext3
```

#### 配置选项

- 大多数内核配置选项都对应 Kconfig 中一个 config，config 之后接的是配置选项的属性，每个配置选项都必须指定类型，，包括：类型（类型包括 bool、tristate、string、hex和 int。），数据范围，输入提示，依赖关系，选择关系，帮助信息，默认值。

```c
bool “Networking support”

等价于
bool
prompt "Networking support"
```

- 输入提示的一般格式为,其中，可选的 if 用来表示该提示的依赖关系

```c
prompt <prompt> [if <expr>]
```

- 依赖关系的格式为

```c
depends on（或者requires） <expr>
```

- 默认值的格式为,如果用户不设置对应的选项，配置选项的值就是默认值

```c
default <expr> [if <expr>]
```

- 如果定义了多重依赖关系，它们之间用 “&&” 间隔。

依赖关系也可以应用到该菜单中所有的其他选项（同样接受if表达式）内，下面两段脚本是等价的：

```c
bool "foo" if BAR
default y if BAR

// 等价

depends on BAR
bool "foo"
default y
```

- 选择关系（也称为反向依赖关系）的格式如下，A 如果选择了B，则在A被选中的情况下，B自动被选中

```c
select <symbol> [if <expr>]    
```

- 数据范围的格式如下，

```c
range <symbol> <symbol> [if <expr>]
```

- Kconfig中的expr（表达式）定义

```c
<expr> ::= <symbol>
    <symbol> '=' <symbol>
    <symbol> '!=' <symbol>
    '(' <expr> ')'
    '!' <expr>
    <expr> '&&' <expr>
    <expr> '||' <expr>
```

# 5.Linux文件系统与设备文件

## linux 文件系统

![](../img/文件系

> VFS -- 虚拟文件系统

![](../img/应用程序-VFS-设备驱动.jpg)

### file结构体

kernel/linux-5.6.14/include/linux/fs.h

- file

```c
struct file {
	union {
		struct llist_node	fu_llist;
		struct rcu_head 	fu_rcuhead;
	} f_u;
	struct path		f_path;
	struct inode		*f_inode;	/* cached value */
	const struct file_operations	*f_op;

	/*
	 * Protects f_ep_links, f_flags.
	 * Must not be taken from IRQ context.
	 */
	spinlock_t		f_lock;
	enum rw_hint		f_write_hint;
	atomic_long_t		f_count;
	unsigned int 		f_flags;          // 设备驱动关心的内容
                                  // f_flags & O_NONBLOCK 为 真 表示非阻塞打开设备文件
	fmode_t			f_mode;               // 文件读写模式
	struct mutex		f_pos_lock;
	loff_t			f_pos;
	struct fown_struct	f_owner;
	const struct cred	*f_cred;
	struct file_ra_state	f_ra;

	u64			f_version;

	errseq_t		f_wb_err;
} __randomize_layout
  __attribute__((aligned(4)));
```

- inode 

```c
struct inode {
	umode_t			i_mode;
	unsigned short		i_opflags;
	kuid_t			i_uid;
	kgid_t			i_gid;
	unsigned int		i_flags;

#ifdef CONFIG_FS_POSIX_ACL
	struct posix_acl	*i_acl;
	struct posix_acl	*i_default_acl;
#endif

	const struct inode_operations	*i_op;
	struct super_block	*i_sb;
	struct address_space	*i_mapping;

#ifdef CONFIG_SECURITY
	void			*i_security;
#endif

	/* Stat data, not accessed from path walking */
	unsigned long		i_ino;
	/*
	 * Filesystems may only read i_nlink directly.  They shall use the
	 * following functions for modification:
	 *
	 *    (set|clear|inc|drop)_nlink
	 *    inode_(inc|dec)_link_count
	 */
	union {
		const unsigned int i_nlink;
		unsigned int __i_nlink;
	};
	dev_t			i_rdev;         //设备编号，linux内核的设备编号分为主设备编号和次设备编号。前者12位，后者20位
	loff_t			i_size;
	struct timespec64	i_atime;
	struct timespec64	i_mtime;
	struct timespec64	i_ctime;
	spinlock_t		i_lock;	/* i_blocks, i_bytes, maybe i_size */
	unsigned short          i_bytes;
	u8			i_blkbits;
	u8			i_write_hint;
	blkcnt_t		i_blocks;

#ifdef __NEED_I_SIZE_ORDERED
	seqcount_t		i_size_seqcount;
#endif

	/* Misc */
	unsigned long		i_state;
	struct rw_semaphore	i_rwsem;

	unsigned long		dirtied_when;	/* jiffies of first dirtying */
	unsigned long		dirtied_time_when;

	struct hlist_node	i_hash;
	struct list_head	i_io_list;	/* backing dev IO list */
#ifdef CONFIG_CGROUP_WRITEBACK
	struct bdi_writeback	*i_wb;		/* the associated cgroup wb */

	/* foreign inode detection, see wbc_detach_inode() */
	int			i_wb_frn_winner;
	u16			i_wb_frn_avg_time;
	u16			i_wb_frn_history;
#endif
	struct list_head	i_lru;		/* inode LRU list */
	struct list_head	i_sb_list;
	struct list_head	i_wb_list;	/* backing dev writeback list */
	union {
		struct hlist_head	i_dentry;
		struct rcu_head		i_rcu;
	};
	atomic64_t		i_version;
	atomic64_t		i_sequence; /* see futex */
	atomic_t		i_count;
	atomic_t		i_dio_count;
	atomic_t		i_writecount;
#if defined(CONFIG_IMA) || defined(CONFIG_FILE_LOCKING)
	atomic_t		i_readcount; /* struct files open RO */
#endif
	union {
		const struct file_operations	*i_fop;	/* former ->i_op->default_file_ops */
		void (*free_inode)(struct inode *);
	};
	struct file_lock_context	*i_flctx;
	struct address_space	i_data;
	struct list_head	i_devices;
	union {
		struct pipe_inode_info	*i_pipe;
		struct block_device	*i_bdev;
		struct cdev		*i_cdev;
		char			*i_link;
		unsigned		i_dir_seq;
	};

	__u32			i_generation;



	void			*i_private; /* fs or device private pointer */
} __randomize_layout;
```

查看 `/proc/devices` 文件可以获知系统中注册的设备，第1列为主设备号，第2列为设备名。

### devfs 设备文件系统

> **已经被 udev 取代**

- 可以通过程序在设备初始化时在 `/dev` 目录下创建设备文件，卸载设备时将它删除

- 设备驱动程序可以指定设备名、所有者和权限位，用户空间程序仍可以修改所有者和权限位。

- 不再需要为设备驱动程序分配主设备号以及处理次设备号，在程序中可以直接给 `register_chrdev()` 传递0主设备号以获得可用的主设备号，并在`devfs_register()`中指定次设备号

```c
static devfs_handle_t devfs_handle;
static int _ _init xxx_init(void)
{
    int ret;
    int i;
    /* 在内核中注册设备 */
    ret = register_chrdev(XXX_MAJOR, DEVICE_NAME, &xxx_fops);
    if (ret < 0) {
        printk(DEVICE_NAME " can't register major number\n");
        return ret;
    }
    /* 创建设备文件 -- 已经被删除了 */
    devfs_handle =devfs_register(NULL, DEVICE_NAME, VFS_FL_DEFAULT,
    XXX_MAJOR, 0, S_IFCHR | S_IRUSR | S_IWUSR, &xxx_fops, NULL);
    ...
    printk(DEVICE_NAME " initialized\n");
    return 0;
 }

 static void _ _exit xxx_exit(void)
 {
    devfs_unregister(devfs_handle); /* 撤销设备文件  -- 已经被删除了 */
    unregister_chrdev(XXX_MAJOR, DEVICE_NAME); /* 注销设备 */
 }

 module_init(xxx_init);
 module_exit(xxx_exit);
```

---

在Linux内核中，设备和驱动是分开注册的，注册 1 个设备的时候，并不需要驱动已经存在，而 1 个驱动被注册的时候，也不需要对应的设备已经被注册。设备和驱动各自涌向内核，而每个设备和驱动涌入内核的时候，都会去寻找自己的另一半，而正是 `bus_type` 的 `match()` 成员函数将两者捆绑在一起。

就是说  `bus_type` 的 `match()`  能识别什么设备与什么驱动配对，一旦配对成功，xxx_drive 和 probe() 就被执行（xxx 是总线，比如i2c,pci,usb等）。

> 注意：总线、驱动和设备最终都会落实为 sysfs 中的1个目录，进一步追踪代码会发现，它们实际上都可以认为是 kobject 的派生类，kobject 可看作是所有总线、设备和驱动的抽象基类，1个 kobject 对应 sysfs 中的1个目录。

### udev

udev的工作过程如下:

- 当内核检测到系统中出现了新设备后，内核会通过netlink套接字发送uevent。
- udev获取内核发送的信息，进行规则的匹配。匹配的事物包括 SUBSYSTEM、ACTION、atttribute、内核提供的名称（通过 KERNEL= ）以及其他的环境变量。

> devfs 和 udev 分别是Linux 2.4和Linux 2.6以后的内核生成设备文件节点的方法，前者运行于内核空间，后者运行于用户空间。

> udev 可以利用内核通过 netlink 发出的 uevent 信息动态创建设备文件节点。


# 6.字符设备

在Linux内核中，使用 cdev 结构体描述一个字符设备。

```c
struct cdev {
	struct kobject kobj;    //内嵌的kobject对象
	struct module *owner;   // 所述模块
	const struct file_operations *ops;    // 文件操作结构体
	struct list_head list; 
	dev_t dev;                            // 设备号
	unsigned int count;
} __randomize_layout;
```

cdev 结构体的 dev_t 成员定义了设备号，为 32 位，其中 12 位为主设备号，20 位为次设备号。使用下列宏可以从 dev_t 获得主设备号和次设备号：

```c
MAJOR(dev_t dev)
MINOR(dev_t dev)
```

而使用下列宏则可以通过 主设备号 和 次设备号 生成 dev_t

```c
// #define MKDEV(ma,mi)	((ma)<<8 | (mi))

MKDEV(int major, int minor)
```

操作 cdev 结构体的函数

```c
void cdev_init(struct cdev *, const struct file_operations *); 
struct cdev *cdev_alloc(void);  
void cdev_put(struct cdev *p);
int cdev_add(struct cdev *, dev_t, unsigned);   //从系统添加有一个 cdev
void cdev_del(struct cdev *)   		//从系统删除有一个 cdev
```



