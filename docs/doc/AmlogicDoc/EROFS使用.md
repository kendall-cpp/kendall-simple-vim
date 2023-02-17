# EROFS 简介

EROFS 是在 Linux 4.19 中引入的只读文件系统。它支持压缩和去重，并针对读取性能进行了优化。

EROFS 与其他压缩文件系统之间的主要区别在于，它支持就地解压缩。压缩的数据存储在块末尾，以便能够解压缩到同一页面中。在 EROFS 映像中，超过 99% 的块能够使用此方案，因此无需在读取操作期间分配额外的页面。

EROFS 图片不必压缩。但是，使用压缩功能时，图片的大小平均缩小约 25%。在最高压缩级别下，图片可缩小多达 45%。

事实证明，无论是否压缩，EROFS 在随机和依序访问时间内都优于其他文件系统。

文档参考： https://source.android.com/docs/core/architecture/kernel/erofs?hl=zh-cn&authuser=1

## 开启 erofs 支持

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/erable_erofs.5h0o9midx840.webp)


## 使用 mkfs.erofs 工具制作 erofs img

git clone git://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git

```sh
# 需要下载一下插件
sudo apt-get install autotools-dev 
sudo apt-get install automake

sudo apt-get install uuid-dev
sudo apt-get install liblz4-dev
apt-cache search liblz4-dev  # 服务器上没有

cd erofs-utils
./autogen.sh
./configure
make -j4

# 拷贝到 chrome对应目录下
cp mkfs.erofs /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/host/linux-x86/bin/ -rf
```

**注意：** 服务器上编译可能缺少 liblz4-dev , 建议在 ubuntu 上编译

erofs 默认支持 lz4 压缩算法，所以需要安装相应的库，不然 .configure 时会关闭 lz4

如下：

```sh
./configure 

.......
checking lz4.h usability... no
checking lz4.h presence... no
checking for lz4.h... no
```


### 手动 mount erofs

```sh
# 制作 img
# 拷贝一些文件到 srcd
./mkfs.erofs  erofs.img srcd/
adb push erofs.img /data/

# 使用 lz4 压缩，需要观察在 erofs-utils configure时 lz4 是否显示为 yes
./mkfs.erofs -zlz4 -C65536 ./erofs.img.3 ./srcd/ -E context_file_path  # (linux的参数)

mount -t erofs /data/erofs.img  /data/aaa/

# 如果把 img 烧到自己新增加的分区，就这样挂载
mount -t erofs /dev/block/mtdblock8  /data/aaa/
```

**erofs 默认支持 lz4 压缩算法，所以需要安装相应的库，不然 .configure 时会关闭 lz4**



### 修改 ota_from_target_files 支持 erofs

参考这个 patch: https://eureka-partner-review.googlesource.com/q/topic:%22Enable+erofs%22

```sh
# common_drivers
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276586

# 需要增大 sytem 分区
# kernel-5.15
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276587

# u-boot
https://eureka-partner-review.googlesource.com/c/amlogic/u-boot/+/276588

# vendor/amlogic
https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/276589
```

## erofs VS squashfs

 - nandread

busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0

- nandwrite

busybox time nandwrite /dev/mtd/mtd4 -s -0 -p /data/write_test_file 

- mount fs

```sh
--- a/korlan/init.rc.base
+++ b/korlan/init.rc.base
@@ -141,8 +141,12 @@ on fs
     # Load device mapper table
     exec /sbin/dmsetup create system -r /dmtable
 
-    #mount squashfs /dev/mapper/system /system.ro ro nodev noatime
-    mount erofs /dev/mapper/system /system.ro ro nodev noatime
+    write /dev/kmsg "TEST : mount fs start  lsken00"
+
+    mount squashfs /dev/mapper/system /system.ro ro nodev noatime
+    #mount erofs /dev/mapper/system /system.ro ro nodev noatime
+
+    write /dev/kmsg "TEST : mount fs end lsken00"
```

- system.img 大小

### 数据对比


|     |   |  squashfs   | erofs  |
|  ----  | ----  |  ----  | ----  |
| nandread  | real |2.65s  |2.47s |
|            | user | 0.02s | 0.03s |
|            | sys | 1.50s | 1.57s  |
| nandwrite  | real | 4.10s  | 4.57s |
|            | user |0.01s | 0.01s |
|            | sys |  1.28s | 1.27s |
| mount fs |  start  | 4.090602	| 4.109511
|	|end|	4.374924|	4.149173|
|	|other partition|	5.910525|	5.792701|
|	|end-start|	0.284322|	0.039662|
|system.img  |     |26.040 KB	| 34.884 KB|

```
./iozone -a -n 8m -g 256m -i 0 -i 1 -y 4096 -q 4096 -f /system/iozone.tmpfile -Rb ./iotest.xls						
squashfs					erofs	
The top row is records sizes, the left column is file sizes	
Writer Report					Writer Report	
	4096					4096
8192	64471				8192	65146
16384	65239				16384	65551
32768	23665				32768	23067
65536	15758				65536	15821
131072	14483				131072	14821
262144	14125				262144	14275
Re-writer Report					Re-writer Report	
	4096					4096
8192	97652				8192	96764
16384	97062				16384	104512
32768	16098				32768	16335
65536	17909				65536	15728
131072	16499				131072	16282
262144	15107				262144	15088
Reader Report					Reader Report	
	4096					4096
8192	192399				8192	215703
16384	235934				16384	222104
32768	204303				32768	234278
65536	232769				65536	260151
131072	232489				131072	233637
262144	214413				262144	245730
Re-reader Report					Re-reader Report	
	4096					4096
8192	194764				8192	212205
16384	214354				16384	199301
32768	176403				32768	204080
65536	193224				65536	200454
131072	192444				131072	201576
262144	187548				262144	201468
```

**总结**：读写 IO 性能并没有提升，文件系统 mount 时间稍微减少，但 img 大小增大 8M 左右。

在嵌入式设备上 erofs 并没有表现出明显优势，正如官方解释 erofs 更适合手持设备。

> https://source.android.google.cn/docs/core/ota/ab/ab_faqs#why-didnt-you-use-squashfs




