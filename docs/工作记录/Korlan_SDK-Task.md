- [TASK：测试 i2s clock](#task测试-i2s-clock)
  - [在 Ubuntu 下测试](#在-ubuntu-下测试)
- [提交](#提交)
  - [最终提交1](#最终提交1)
  - [最终提交2](#最终提交2)
- [Task: AC status `connected_status` not truly reflect the state when T6 docked](#task-ac-status-connected_status-not-truly-reflect-the-state-when-t6-docked)
- [复现](#复现)


-------------




## TASK：测试 i2s clock

> https://partnerissuetracker.corp.google.com/issues/243087651

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247301

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247425

```sh
dmesg  -n 8

cat /sys/kernel/debug/tas5805_debug/seq_timestamp

echo 0 > /sys/kernel/debug/tas5805_debug/seq_timestamp   关闭

echo 1 > /sys/kernel/debug/tas5805_debug/seq_timestamp   打开

cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*

amixer cget numid=2 

amixer cset numid=2 150   # 修改音量

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav 

```


- dump 寄存器

```
i2cdump -f -y 0x01 0x2d
```

### 在 Ubuntu 下测试

进入 codecs

adb shell

## 提交


### 最终提交1

git add sound/soc/codecs/tas5825m.c

git commit -s --no-verify    // git commit --amend  --no-verify     第二次 加changeID

```sh
[tas5805] Enable/disable i2s clock when power on/off codec

Bug:b/236912216
Test: build ok

Signed-off-by: Shengken Lin <shengken.lin@amlogic.corp-partner.google.com>
Change-Id: Iad9dba635ddd890457398c6bed8cba324feb80f0
```

git push eureka-partner HEAD:refs/for/korlan-master


https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247301



### 最终提交2

git add 

git commit -s --no-verify    // git commit --amend  --no-verify     第二次 加changeID



```sh
    [Dont't merge] Test enable/disable i2s clock when power on/off codec
    
    Bug:b/236912216
    Test:
    case 1:power off codec(disable i2s clock)
    / # echo 0 > /sys/kernel/debug/tas5805_debug/seq_timestamp
    / # cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*
     tdmout_b_sclk                 0    +/-3125Hz
     tdmout_a_sclk                 0    +/-3125Hz
     tdmin_lb_sclk                 0    +/-3125Hz
     tdmin_b_sclk                  0    +/-3125Hz
     tdmin_a_sclk                  0    +/-3125Hz
     tdmin_vad_clk                 0    +/-3125Hz
    
    case 2:power on codec(enable i2s clock)
    / # echo 1 > /sys/kernel/debug/tas5805_debug/seq_timestamp
    / # cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*
     tdmout_b_sclk           3067188    +/-3125Hz
     tdmout_a_sclk                 0    +/-3125Hz
     tdmin_lb_sclk                 0    +/-3125Hz
     tdmin_b_sclk            3068750    +/-3125Hz
     tdmin_a_sclk                  0    +/-3125Hz
     tdmin_vad_clk                 0    +/-3125Hz
    
    Signed-off-by: Shengken Lin <shengken.lin@amlogic.corp-partner.google.com>
    Change-Id: I8c5fc26d97b1643f0074e8823cae98fc42ba9e70
```

```c
static struct tas5825m_priv *write_priv; 
write_priv = priv; 


  static ssize_t ta5805_i2s_write(struct file *filp, const char __user *buf, size_t count, loff_t *off)                                                                            
  {
          char val[10];
          int tmp_val = 0; 
   
          if (count > 10)
                  return -1;
   
          if(copy_from_user(val, buf, count))
                  return -EFAULT;
          else {
                  sscanf(val, "%d", &tmp_val);
                  if (tmp_val == 1)
                          tas5805m_power_on(write_priv);
                  else if (tmp_val == 0)
                          tas5805m_power_off(write_priv);
                  else 
                          pr_err("echo 1 or 0 to enable i2c clock or disable i2c clock");
          }    
          return count;
  }


  struct file_operations ta5805_timestamp_file_ops = {
    .open   = simple_open,
    .read = ta5805_timestamp_read,
    .write = ta5805_i2s_write,
  };  
```

git push eureka-partner HEAD:refs/for/korlan-master


https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247425


-------------------

## Task: AC status `connected_status` not truly reflect the state when T6 docked 

> https://partnerissuetracker.corp.google.com/issues/244842099

## 复现

https://partnerissuetracker.corp.google.com/issues/245839768

编译 ota 命令

```sh
cd chrome/

source build/envsetup.sh 

# PARTNER_BUILD=true lunch korlan-eng
PARTNER_BUILD=true lunch

PARTNER_BUILD=true BOARD_NAME=korlan-b1 make -j30 otapackage
PARTNER_BUILD=true BOARD_NAME=korlan-p1 make -j30 otapackage
# 输出obj路径： /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/korlan
```


编译

```sh
./build_bl2.sh korlan-b1 ../u-boot release

./build_bl31.sh korlan-b1 ../u-boot release

# 修改pthon脚本 scripts/pack_kpub.py
./build_bl32.sh korlan-b1 ../u-boot release  #+#!/usr/bin/env python

./build_uboot.sh korlan-b1 ../../chrome release

./build_kernel.sh korlan-b1  ../../chrome
```

签名

```sh
cd pdk
./create-uboot.sh -b korlan-b1

./build-bootimg.sh -b  korlan-b1
```