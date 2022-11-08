# repo sync

```sh
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m br-ipc-c3.xml --repo-url=git://git.myamlogic.com/tools/repo.git

# 修改 git user email
# vim buildRoot_C3/.repo/repo/.git/config
[user]   
        name = shengken.lin
        email = shengken.lin@amlogic.com 
repo sync -c
```

# 编译

```sh
source setenv.sh 
# 选择AW401
make
```


## 编译uboot

```sh
# 可以用409的bootloader
ls bl33/v2019/board/amlogic/defconfigs/c3_aw409_defconfig 
# 编译
uboot-repo$ ./mk c3_aw409_av400

# 编译kernel
buildRoot_C3$ make linux-dirclean
buildRoot_C3$ make linux-rebuild  
# 编译uboot
buildRoot_C3$ make uboot-dirclean
buildRoot_C3$ make uboot-rebuild  
```


### 打包成 boot.img

```sh
# 在这个脚本
vim output/c3_aw401_a32_release/images/mk_bootimg.sh 

./mk_bootimg.sh    # 打包生成 boot.img
```


```sh
# 设置log 级别
echo 9 > /proc/sys/kernel/printk
echo 0 > /proc/sys/kernel/printk
```


# MBP 熟悉

## 模块注册

模块管理组件为每个驱动模块提供相应的对外接口，不同业务驱动之间通过双方的 ID 相互访问，这样就可以实现两个模块之间的关联

- CPPI：common platform program interface 通用平台程序接口
- MBD：基于 OSAL，主要由各种媒体驱动程序组成

各个模块通过 模块描述符 链表进行管理，各个模块以注册的方式加入到 模块描述符 链表中。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221107194434.png)


## 驱动接口

> buildRoot_C3/vendor/amlogic/ipc/mbp/prebuilt/mbd/base/cppi/src/mbd_cppi_init.c

|  内核态对外接口   | 描述  |
|  ----  | ----  |
| cppi_module_init  | 初始化模块 |
| cppi_module_exit  | 去初始化模块 |
| cppi_module_get_name_byid  | 根据模块 ID 获取模块名 |
| cppi_module_get_module_byid  | 根据模块 ID 获取模块描述符 |
| cppi_module_get_func_byid  | 根据模块 ID 获取模块对外接口 |
| cppi_module_stop  | 模块停止 |
| cppi_module_query  | 模块查询 |
| cppi_module_register  | 模块注册 |
| cppi_module_unregister  | 模块注销 |
| cppi_create_proc_entry  |  |
| cppi_remove_proc_entry  |  |
| cppi_device_create  | 创建设备 |
| cppi_device_destroy  | 移除设备 |
| cppi_device_register  | 注册设备 |
| cppi_device_unregister  | 注销设备 |
| cppi_drv_exit  | 退出drv |


## 模块绑定

通过数据接收者绑定数据源来建立两模块之间的数据流。数据源生成的数据将根据绑定的情况，自动发送给数据接收者，用于描述模块与模块之间的关系。

### 模块绑定的功能设计

- 模块绑定功能的初始化/退出。

初始化部分应该实现在对应的模块驱动的初始化函数中。同理，退出功能应该实现在对应的模块驱动的退出函数中

- 绑定功能的核心结构：binder

Binder 的核心结构是两个链表

- 绑定功能提供给其他驱动调用的接口

通过 module register 注册为私有的驱动模块，并提供对外的驱动层接口，方便其他驱动模块使用

- 绑定功能提供给用户层使用的接口

Linux 上通过一般的 ioctl ，提供用户层接口，并将其封装成 MBI 接口。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221107200736.png)

Module bind 提供给其他驱动调用，接口是以回调形式放在 pstExportFuncs 结构体内。主要分为三类: `register/unregister，send/reset data，get bind info` 。

