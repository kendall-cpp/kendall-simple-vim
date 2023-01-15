


## init.rc

init进程是Android系统中用户空间的第一个进程，进程ID为1，源代码位于 `​​system/core/init` ​​目录。作为 Android 系统的第一个进程，Init 进程承担这很多重要的初始化任务，一般 Init 进程的初始化可以分为两部分，前半部分挂载文件系统，初始化属性系统和 Klog， selinux 的初始化等，后半部分重要通过解析 `init.rc` 来初始化系统​​daemon​​ 服务进程，然后以 epoll 的监控属性文件，系统信号等。

`init.rc` 则是 init 进程启动的配置脚本

init.rc 包括四种类型的语句

- Action：动作
- Command：命令
- Service：服务
- Option：选项

Actions和Services声明一个新的分组Section。所有的命令或选项都属于最近声明的分组。位于第一个分组之前的命令或选项将会被忽略。Actions和Services有唯一的名字。如果有重名的情况，第二个申明的将会被作为错误忽略。

### 动作 Action

```sh
on <trgger> [&& <trigger>]*
   <command1>
   <command2>
   <command3>
   ...
```

on 后面跟着一个触发器，当 trigger 被触发时，每个 action 中的 command 将会顺序执行。init 在执行 command 的过程中同时会执行其他活动（设备节点的创建/销毁，属性设置，进程重启）。

|  trigger   | 描述  |
|  ----  | ----  |
| boot  | init 程序启动后触发的第一个事件 |
| device-added-<path>  | 指定设备被添加时触发 |
| device-removed-<path>   | 指定设备被移除时触发 |
| service-exited-<name>   | 在特定服务(service)退出时触发 |
| early-init   | 初始化之前触发 |
| late-init  | 初始化之后触发 |
| init  | 初始化时触发（在 `/init.conf` （启动配置文件）被装载之后 |

```sh
# 当init被触发器执行
on init
	<command>
	...

# 当属性 property:dnsmasq.enable 被设为 1 时执行
on property:dnsmasq.enable=1 
	<command1>
	...
```

### 命令 Command

init.rc中常见的Commands有以下一些：

- `exec ​​<path> [ <argument> ]​​*`
  - 创建和执行程序. 这将会阻塞 init，直到程序执行完成。由于它不是内置命令，应尽量避免使用 exec，它可能会引起 init 卡死。
- `export ​​<name> <value>​​` 在全局环境变量中设在环境变量 `<name>` 为 `<value>`。（这将会被所有在这命令之后运行的进程所继承）
- `ifup ​​<interface>​​` 启动网络接口 `<interface>`
- `import ​​<filename>​​` 解析一个 init 配置文件，扩展当前配置。
- `hostname ​​<name>​​` 设置主机名。
- `chdir​​<directory>​​` 改变工作目录。
- `chmod ​​<octal-mode> <path>​​` 更改文件访问权限。
- `chown ​​<owner> <group> <path>` ​​更改文件的所有者和组。
- `chroot ​​<directory>​​` 改变进程的根目录。
- `class_start ​​<serviceclass>​​` 启动该类 service 所有尚未运行的服务。
- `class_stop ​​<serviceclass>​​` 停止所有该类正在运行的service。
- `domainname ​​<name>​​` 设置域名。
- `enable ​​<servicename>​​` 改变一个 disable 的 service 为 enabled 。一般用于 service 在 init.rc 中被标记为 disabled ，这样的 service 是不会被启动的，当满足一定的触发条件时，可以同 enable 命令来将他变为 enabled

```
on property:boot_completed=1
enable my_service_name
```

- `insmod ​​<path>`​​安装位于`<path>`的模块（PS：驱动）。
- `mkdir ​​<path>​​ [mode] [owner] [group]`
在`​​<path>​​`创建一个目录，（可选）使用给定的模式，所有者个组。如-果没有提供，该目录将用 755 权限，所有者为 root 用户，组为root。
- `mount ​​<type> <device> <dir>[ <mountoption> ]\*​​` 尝试挂载`<device>`到`<dir>`，`<device>`可能有`mtd@name`形式，以指定名为 name 的 mtd 块设备。 `<mountoption>`包括 "ro", "rw", "remount", "noatime", ...
- `restorecon ​​<path> [ <path> ]\*​​`恢复名为`<path>`的文件在file_contexts中配置的的安全级别。自动被init标记正确，不需要用init.rc创建的目录。
- `restorecon_recursive ​​<path> [ <path> ]\*​​`递归的恢复`<path>`指出的目录树中`file_contexts`配置指定的安全级别。 path不要用shell可写或app可写的目录，如`/data/locla/temp`，`/data/data`，或者有类似前缀的（目录）。
- `setcon​​ <securitycontext>`​​设置当前进程的 security context 为特定的字符串。这是典型的仅用于所有进程启动之前的 early-init 设置 init context
- `setenforce 0|1`
  - 设置SELinux系统范围的enfoucing状态。0 is permissive (i.e. log but do not deny), 1 is enforcing.
- `setprop ​​<name> <value>​​`设置系统属性`<name>`为`<value>`.
- `setrlimit ​​<resource> <cur> <max>​​`为特定资源设置 rlimit
- `setsebool ​​<name> <value>​​`设置SELinux的bool类型`<name>`为 ` <value>`。 `<value> may be 1|true|on or 0|false|off`
- `start ​​<service>`​​启动一个服务（如果服务尚未启动）。
- `stop ​​<service>`​​停止服务（如果正在运行）。
- `symlink ​​<target> <path>`​​创建一个符号连接，`at <path> with - the value <target>`。
- `sysclktz ​​<mins_west_of_gmt>`​​Set the system clock base (0 if system clock ticks in GMT)
- `trigger ​​<event>​​`触发一个事件。一个动作将另一动作排队。
- `wait ​​<path> [ <timeout> ]​​poll`特定的`<path>`，出现后返回，或 timeout 到达。如果 timeout 没有指定，默认为5秒。
- `write ​​<path> <string>​​`打开一个位于 `<path>` 的文件，写入（不是追加）字符串 `<string>` 。

### 服务 Service

```
service <name> <pathname> [ <argument> ]*
     <option>
     <option>
     ...
```

- ​​`<name>​​` ——表示service 的名字；
- `​​<pathname>`​​ ——表示service所在路径，此处的 service 是可执行文件，所以一定有存储路径
- `<argument>`​​ ——启动 service 所带的参数
- `<option>​​` ——对此service的约束选项，后面将详细讲解

### 选项 Option

- Option 用来定义 Service 的行为，决定了 Service 将在何时启动，如何运行等。常用的 Option 有包括以下一些。

- critical
  - 这是十分关键的服务。如果在四分钟内退出超过四次，手机将会重启并进入recovery模式。

- disabled
  - 这种类型的服务不会自动启动。它必须明确的使用名字启动。
`setenv ​​<name> <value>​​`设置环境变量`<name>=<value>`在加载的进程中。

- `socket ​​<name> <type> <perm> [ <user> [ <group> [ <context> ] ] ]​​`创建一个名为`/dev/socket/<name>`的UNIX域socket并将fd传递到加载的进程中。

- `user ​​<username>` ​​在执行该service前改变用户名，默认为root。如果你的进程请求Linux的特殊能力，就不要用这个命令。需以进入进程仍是root->请求特权->切换到你期望的uid来替换此法。
- `group ​​<groupname> [ <groupname> ]\*​​` 在执行该 service 前改变组名。第一个以后的附加组名用于设定进程的附加组（通过`setgroups()`）。当前默认是 root。
- `seclabel ​​<securitycontext>​​`在执行服务之前改变安全级别。 主要用于从 rootfs 执行服务，比如 ueventd, adbd. 在 system 分区上可以用基于文件安全级别的策略定义的transition，如果没有指定且没有定义策略的transition，默认是init上下文。
- oneshot
  - 退出不重启服务（名副其实，一次性）。
- `class ​​<name>` ​​为一 service 指定一个类名，所有有相同类名的 service 可以一同启动或停止。如果没有用 class 选项指定类名，该 `service` 属于"`default`"。
- onrestart
  - 在service重启的时候执行。

### 示例

```sh
# 【触发条件early-init，在early-init阶段调用以下行】
on early-init
	# 打开 /proc/sys/vm/min_free_kbytes 写入 4096
	write /proc/sys/vm/min_free_kbytes "4096"

# 不会自动启动 adbd 服务，可以在 init.rc 中加上 start adbd 来启动
service adbd /sbin/adbd  
	disabled
```

## 解析 init.rc

> chrome/system/core/init/init.c

```c
int main(int argc, char **argv)
{   
	...

	//创建linux根文件系统中的目录
	mkdir("/dev", 0755);
	mkdir("/proc", 0755);
	mkdir("/sys", 0755);
	
	mount("tmpfs", "/dev", "tmpfs", MS_NOSUID, "mode=0755");
	mkdir("/dev/pts", 0755);
	mkdir("/dev/socket", 0755);
	mount("devpts", "/dev/pts", "devpts", 0, NULL);
	mount("proc", "/proc", "proc", 0, NULL);
	mount("sysfs", "/sys", "sysfs", 0, NULL);
	
	mknod("/dev/kmsg", S_IFCHR | 0600, makedev(1, 11));
	close(open("/dev/.booting", O_WRONLY | O_CREAT, 0000));
	
	//init的 标准输入，标准输出，标准错误文件描述符定向到__null__，意味着没有输入和输出，它的输入和输出全部写入到Log中
	open_devnull_stdio();
	property_init();
	
	unsigned revision_number = 0;
	get_hardware_name(hardware, &revision_number);
	snprintf(revision, sizeof(revision), "%d", revision_number);
	
	process_kernel_cmdline();
	
	
	is_charger = !strcmp(bootmode, "charger");
	
	INFO("property init\n");
	if (!is_charger)
		property_load_boot_defaults();
	
	//读取并 且解析init.rc文件（这个文件在根目录下）
	INFO("reading config file\n");
	init_parse_config_file("/init.rc");
	
	queue_builtin_action(record_boot_start, "boot_start");

	//触发在init脚本文件中名字为early-init的action，并且执行其commands，其实是: on early-init
	action_for_each_trigger("early-init", action_add_queue_tail);
	
	...
	
	for(;;) {
		...
		//启动所有init脚本中声明的service
		//多路监听设备管理，子进程运行状态，属性服务
		nr = poll(ufds, fd_count, timeout);
		if (nr <= 0)
			continue;
			...
	}
	
	return 0;
} 
```

> 参考：https://blog.51cto.com/u_15127593/4402726