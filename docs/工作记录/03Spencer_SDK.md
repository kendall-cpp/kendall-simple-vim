

---

> 波特率：921600

## 编译 uboot & kernel & NN

> 参考：https://confluence.amlogic.com/pages/viewpage.action?pageId=180725726

### Bootloader (bl2 + bl31 + bl32 + u-boot)

```sh
cd bl2
./build_bl2.sh spencer-p2 release
cd -


cd bl31
./build_bl31.sh spencer-p2 release
cd -
 
cd bl32
./build_bl32.sh spencer-p2 release
cd -
 
cd u-boot
./build_uboot.sh spencer-p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome release
cd -
```

### kernel

- 切换分支

git branch -a | grep spencer

git checkout -t remotes/eureka-partner/spencer-master

```sh
cd eureka/spencer-sdk/
 
cd kernel
./build_kernel.sh spencer-p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
cd -
```

### module - NN

```
cd ~/eureka/spencer-sdk/
 
cd verisilicon
./build_ml.sh arm64 spencer-p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
cd -
```

### 签名（会重新编译一遍）

拷贝签名脚本到 sign-sdk

#### 签名 u-boot

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/sign-sdk
./main.sh /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk u-boot spencer p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
```

#### 签名 kernel

下载 ramdisk

> https://console.cloud.google.com/storage/browser/_details/cast-partner-amlogic-internal/internal/master/spencer-eng/314706/factory/spencer-fct-spencer-p2-314706.zip;tab=live_object

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/compile-sign-sdk/unpack_boot
unpack_boot.sh ./fct_boot.img ./boot_out unpack_boot 

cp ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka/compile-sign-sdk/spencer/ramdisk.img
```

- 签名

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/sign-sdk
./main.sh /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk kernel spencer p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
```

### 烧录

