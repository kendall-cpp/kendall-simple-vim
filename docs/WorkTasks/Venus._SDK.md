
- [DDR功耗测试](#ddr功耗测试)
  - [理论带宽](#理论带宽)
  - [linux下内存压力测试——stressapptest](#linux下内存压力测试stressapptest)
- [325FG 功耗测试](#325fg-功耗测试)
  - [测试 FPN](#测试-fpn)
  - [dsp 功耗测试](#dsp-功耗测试)
  - [SRAM测试](#sram测试)

-----

> 波特率：921600

## DDR功耗测试

- 查看功耗

```sh
cat ./sys/class/aml_ddr/bandwidth
```

- 测试工具

```sh
stressapptest -M 512 -s 1000000  -F &
memtester 64M 10000 &
/data/stream_aarch64 &
```

- 测试工具源码

https://github.com/heyg/STREAM

https://github.com/heyg/stressapptest

- 计算理论带宽和测试带宽

./stressapptest -s 20 -M 256 -m 8 -W 



```sh
stressapptest -M 256 -s 10  -F
stressapptest -s 30 -M 256 -m 2  -v 10 -l /data/testfile -F
```

```sh
# 看这个
1970/01/01-00:05:21(UTC) Stats: Memory Copy: 52894.00M at 5289.16MB/s
```

- 测试 korlan

```sh
stressapptest -s 30 -M 256 -m 2  -v 10 -l /data/testfile -F

./stream_aarch64  &
```


### 理论带宽

- **venus**

```
1320 * 32 * 2 Mb/s
DDR freq: 1320 Mhz
ddr 数据线个数： 32
===> 1320 * 32 * 2 MB/s == 10560 MB/s
```

AML 使用 dmc, 可以使用 `cat /sys/class/aml_ddr/bandwidth`  查看实际带宽，并推算出理论带宽， 2760002（cat 查看的值） / 0.2676/1024 == 10072.1765811846 MB/s  (与 10560 MB/s 相近)

- **Korlan**

768MHZ DDR4 为例

- 理论带宽： 768Mhz * 16 * 2 = 24576Mb/s == 3072MB/s
- AML 使用 dmc，可以使用 `cat /sys/class/aml_ddr/bandwidth` 检测实际带宽，并推算出理论带宽

eg

```
Total bandwidth: 1139599 KB/s, usage: 37.98%
==> 1139599 / 0.379 / 1024 = 2936.39429966

2936 和 3027 接近

实际带宽测试一般上限是 80%。基本很难达到
```

### linux下内存压力测试——stressapptest

该软件更多的时候测试的是内存控制器和总线接口，而不是存储单元的功能。测试是会最大化总线和内存的交换量，从而使交换失败的概率会增加。

该软件采用多线程对内存进行拷贝和磁盘接口读写，占用85%的内存块，而且每个线程都是随机进行读写操作，一般每个处理开启2个线程，磁盘也是。

 参数说明：        

-s: number of second to run the application  测试时间

-m: number of memory copy threads to run  复制线程数  (Memory Copy)

-W : Use more CPU-stressful memory copy (false)

-i: number of memory invert threads to run  反转线程数 (Invert Copy)

-c: CRC check  CRC校验                                (Data Check)

-C: number of memory CPU stress threads to run    CPU压力线程数

-M: Megabytes of ram to run  尽可能测试最大的可用存储空间，（设置超过了memfree，就会被kill）

-f filename : add a disk thread with tempfile 'filename' (none) 使用tempfile 'filename'添加一个磁盘线程

-F : don't result check each transaction, use libc memcpy instead. (false) 不对每个事务进行结果检查，而是使用libc memcpy

-l logfile : log output to file 'logfile' (none)  输出到log文件

-v level : verbosity (0-20) (default: 8) 冗长

**使用**

```
stressapptest -s 600 -M 64 -m 8 -C 8 -W &


stressapptest -s 30 -M 256 -m 2  -v 10 -l /data/testfile -F

```


- 修改代码

STREAM-master/stream.c 

```c
#define TEST_LOOP_COUNT 10000000
long long loop_count = 0;


// 317
  #pragma omp parallel for
          for (j=0; j<STREAM_ARRAY_SIZE; j++)
              c[j] = a[j];
  #endif
  #if 0 /*disable not use test*/
          times[0][k] = mysecond() - times[0][k];
          
          times[1][k] = mysecond();
  #ifdef TUNED
          tuned_STREAM_Scale(scalar);
  #else
  #pragma omp parallel for
          for (j=0; j<STREAM_ARRAY_SIZE; j++)
              b[j] = scalar*c[j];
  #endif
          times[1][k] = mysecond() - times[1][k];
          
          times[2][k] = mysecond();
  #ifdef TUNED
          tuned_STREAM_Add();
  #else
  #pragma omp parallel for
          for (j=0; j<STREAM_ARRAY_SIZE; j++)
              c[j] = a[j]+b[j];
  #endif
          times[2][k] = mysecond() - times[2][k];
          
          times[3][k] = mysecond();
  #ifdef TUNED
          tuned_STREAM_Triad(scalar);
  #else
  #pragma omp parallel for
          for (j=0; j<STREAM_ARRAY_SIZE; j++)
              a[j] = b[j]+scalar*c[j];
  #endif
          times[3][k] = mysecond() - times[3][k];
  #endif
          }   
  }
```

- 测试

```
adb push .\stream_aarch64 /data/

./stream_aarch64  &
cat /sys/class/aml_ddr/bandwidth 
```

> confluence 总结： https://confluence.amlogic.com/pages/viewpage.action?pageId=209283542


---

## 325FG 功耗测试

```sh
# Linux version 4.19.180-gf0c7983dcc17 (zhiqi.lai@walle01-sz) (Chromium OS 12.0_pre422132_p20210405-r4 clang version 13.0.0

# 修改编译成静态库
--- a/acuity-ovxlib-dev/build_vx.sh
+++ b/acuity-ovxlib-dev/build_vx.sh
@@ -78,8 +78,8 @@ if [ -z $BUILD_OPTION_EGL_API_NULLWS ]; then
 fi
 if [ ${PRODUCT} == "gq" ] || [ ${PRODUCT} == "nq" ] ||
    [ ${PRODUCT} == "spencer" ] || [ ${PRODUCT} == "venus" ]; then
-  BUILD_OPTION_gcdSTATIC_LINK=1
-  BUILD_OPTION_STATIC_LINK=1
+  BUILD_OPTION_gcdSTATIC_LINK=0
+  BUILD_OPTION_STATIC_LINK=0
 else
   BUILD_OPTION_gcdSTATIC_LINK=0
   BUILD_OPTION_STATIC_LINK=0
diff --git a/build_ml.sh b/build_ml.sh
index e0dcec2d..4c31644c 100755
--- a/build_ml.sh
+++ b/build_ml.sh
@@ -301,7 +301,7 @@ elif [ ${PRODUCT} == "spencer" -o ${PRODUCT} == "venus" ]; then
   BUILD_OPTION_USE_VSC_LITE=1
   BUILD_OPTION_USE_VXC_BINARY=1
   BUILD_OPTION_GPU_CONFIG="vip9000nanodi_pid0xBE"
-  BUILD_OPTION_gcdSTATIC_LINK=1
+  BUILD_OPTION_gcdSTATIC_LINK=0
   BUILD_OPTION_gcdPOWEROFF_TIMEOUT=5
 else
   BUILD_OPTION_USE_VSC_LITE=0



# 回退kernel
cd kernel
spencer-master 分支
git reset --hard 227d320dcdc40efd6ece0b58e0a8ddecb85b32b3
```

### 测试 FPN

```sh
编译
./build_kernel.sh venus-p2 ./../../chrome

# git clean -d -fx ./
cd verisilicon
./build_ml.sh arm64 venus-p2 ./../../chrome


测试
insmod /lib/galcore.ko showArgs=1
/data/FPN # ./tflite FPN_be.nb ./640.jpg 
/data/FPN # ./tflite FPN_be.nb ./input_0_out0_1_640_640_3.tensor 
```

- 测试结果

```
/data/FPN # ./tflite FPN_be.nb ./640.jpg 


/data/FPN # ./tflite FPN_be.nb ./input_0_out0_1_640_640_3.tensor 

# 如果想一直跑需要声明环境变量
export VNN_LOOP_TIME=10000
```


### dsp 功耗测试

```sh
cd spencer-sdk$/freertos
# 分支：spencer-master

git checkout -t eureka-partner/spencer-master

# 打上patch dsp_patch.patch
patch -p1 < ../../Venus-file/325FG功耗测试/dsp_patch.patch 
# 或者直接拷贝：cp /mnt/nfsroot/yuegui.he/c2/amlogic_sdk/freertos/build_rtos.sh .

cd freertos
./build_rtos.sh venus-p2 ./../../chrome release --skip-dsp-build
# 输出目录：out_dsp/dspboot.bin

# 运行dsp
adb.exe push ./dspboot.bin  /system/lib/firmware/
adb.exe push ./dspboot.bin  /lib/firmware/

# Run the test
# 1. -s                 : stop dsp
# 2. -r                 : reset dsp
# 3. -l --firmware=XXXX : reload dsp
# 4. -S                 : start dsp
dsp_util --dsp=hifi4a -s
dsp_util --dsp=hifi4a -r
dsp_util --dsp=hifi4a --firmware=dspboot.bin -l
dsp_util --dsp=hifi4a -S

# 进入休眠
echo mem > /sys/power/state
```

- 修改代码

```sh
# 在编译中搜索 startdsp.c 确定是哪个
../../demos/amlogic/xtensa_hifi4/c2_venus_hifi4a/boot/startdsp.cc

vim ./demos/amlogic/xtensa_hifi4/c2_venus_hifi4a/boot/startdsp.cc

./build_rtos.sh venus-p2 ./../../chrome 

```

- 修改成 24M

···
 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/kernel/arch/arm64/boot/dts/amlogic/meson-c2.dtsi   

 <!-- 1376         dspa_clkfreq = <400000000>;    24 -->
 dspa_clkfreq = <24000000>;

 加 sleep
···


----------

- 400M

```sh
Z:\workspace\google_source\eureka\spencer-sdk\freertos\hifi_tests> adb push .\c2_venus_flatbuftest_hifi4a.bin /data/

# 修改
# 这个目录下查看只编译一个： workspace\google_source\eureka\spencer-sdk\freertos\demos\amlogic\xtensa_hifi4
# +tests=$(find demos/amlogic/xtensa_hifi4/ -mindepth 1 -maxdepth 1 -type d -name "c2_venus_flatbuftest_hifi4a")

编译z指令： bash build_hifi_tests.sh debug 

cp /data/c2_venus_flatbuftest_hifi4a.bin /system/lib/firmware/dspboot.bin 

cp /data/c2_venus_flatbuftest_hifi4a.bin /lib/firmware/dspboot.bin 

sync

dsp_util --dsp=hifi4a -s
dsp_util --dsp=hifi4a -r
dsp_util --dsp=hifi4a --firmware=dspboot.bin -l
dsp_util --dsp=hifi4a -S

cat /sys/kernel/debug/hifi4frtos/hifi4

# 修改： demos/amlogic/xtensa_hifi4/c2_venus_flatbuftest_hifi4a/boot/startdsp.c

```

- 24M

./build_kernel.sh venus-p2 ./../../chrome

adnl.exe Partition -P system_b -F .\boot.venus-p2.img

adnl.exe oem "enable_factory_boot"

 adnl reboot


----

### SRAM测试

> 下载芯片文档地址： https://employees.myamlogic.com/Engineering/default.aspx


- 到 venus 上测试


修改 help.c

```c
// vim u-boot/cmd/help.c 
#define START_ADDR	0xFFFC0000
#define END_ADDR	0xFFFFE000

static int do_sram_mem(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
        volatile unsigned char *write = "AA";
	volatile unsigned char *p = START_ADDR;

        int i = 0;
        while(p != END_ADDR) {
                printf (" ------ %p -----\n", p);
                *p = *write;
                // printf (" == %u ==\n", *p);
                p++;
                if(p > END_ADDR) {
                        // printf ("\n\n\n ------ %p ------\n\n\n", p);
                        if(*write == "AA") 
                                *write = "BB";
                        else 
                                *write = "CC";
                        p = START_ADDR;
                }
        }

	
	return 0;
} 

U_BOOT_CMD(
          sram_mem, CONFIG_SYS_MAXARGS, 0,      do_sram_mem,
          "sram_mem cmd'",
          "map sram, and memcopy data to test \n"
          "      passing 'arg' as arguments"
);
```

- 修改 u-boot BOOTDELAY 时间

```
vim spencer-sdk/u-boot/board/amlogic/defconfigs/c2_venus_p2_defconfig

CONFIG_BOOTDELAY=5 
```



用 venus-p2 编译所有的 bootloader

烧录

```sh
adnl.exe oem "store init 1"
adnl.exe oem "mmc dev 1"

adnl.exe Partition -M mem -P 0x2000000 -F u-boot.signed.bin
adnl.exe oem "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a  -F tpl.signed.bin
adnl.exe Partition -P tpl_b  -F tpl.signed.bin

# 关闭工厂模式
adnl.exe oem "store erase fts  0 0"

adnl reboot 
```

重启的时候一直按住 Enter 进入 u-boot

```sh
# 执行 sram_mem 测试
c2_venus_p2# sram_mem
```

https://confluence.amlogic.com/pages/viewpage.action?pageId=209283480


