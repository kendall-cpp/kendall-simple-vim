# bringup 

- schematic review
  - wait google share pinmux settings
  - compare amlogic reference deltas with google
  - Finish secure boot (bootloader) 

- kernel  编译

./build_kernel.sh lumia-proto

- uboot 编译

./mk a4_lumia_proto

## Base GPIO add BSP

### kernel

[GPIO 功能表连接](https://docs.google.com/spreadsheets/d/1vfIfrzfPsIUnfrY_ygjiDI7CCKeCf0k_7lZ33QB9IkI/edit?resourcekey=0-mmV6nD00ava-ImJD3n7sXw#gid=2062501657)

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.62f21cdbjw00.webp)

./drivers/pinctrl/meson/pinctrl-meson-a4.c

找到

```c
  /* GPIOAO func1 */
  static const unsigned int i2c_slaveo_a_sda_ao0_pins[]           = { GPIOAO_0 };
  static const unsigned int i2c_slaveo_a_scl_ao1_pins[]           = { GPIOAO_1 };
  static const unsigned int remote_ao_input_ao3_pins[]            = { GPIOAO_3 };
  static const unsigned int uart_ao_c_tx_ao4_pins[]               = { GPIOAO_4 };
  static const unsigned int uart_ao_c_rx_ao5_pins[]               = { GPIOAO_5 };
  static const unsigned int clk_32k_ao_out_pins[]                 = { GPIOAO_6 };
  
  /* GPIOAO func2 */
  static const unsigned int uart_ao_c_tx_ao0_pins[]               = { GPIOAO_0 };
  static const unsigned int uart_ao_c_rx_ao1_pins[]               = { GPIOAO_1 };
  static const unsigned int i2c_slaveo_a_sda_ao2_pins[]           = { GPIOAO_2 };
  static const unsigned int i2c_slaveo_a_scl_ao3_pins[]           = { GPIOAO_3 };
  static const unsigned int remote_ao_input_ao4_pins[]            = { GPIOAO_4 };
  static const unsigned int pwm_g_pins[]                          = { GPIOAO_6 };

  /* GPIOAO func3 */
  static const unsigned int remote_ao_input_ao1_pins[]            = { GPIOAO_1 };
  static const unsigned int remote_ao_input_ao6_pins[]            = { GPIOAO_6 };
  
  /* GPIOAO func4 */
  static const unsigned int pmic_sleep_ao2_pins[]                 = { GPIOAO_2 };
  static const unsigned int pmic_sleep_ao4_pins[]                 = { GPIOAO_4 };
```

#### 学习配 GPIO

**GPIOAO_0 和 GPIOAO_1**

根据上表表格知道如果 GPIOAO_0 的功能是 I2CS_AO_A_SDA ， 所以去 meson-a4.dtsi 中搜索 sda 。 找到 i2c0_sda_e0 和 i2c0_scl_e1 。

```c
i2c0_pins1:i2c0_pins1 {
  mux { 
    groups = "i2c0_sda_e0",
      "i2c0_scl_e1"; 
    function = "i2c0";
    drive-strength-microamp = <3000>;
    bias-disable;
  };
}
```

然后去 longyan-proto.dts 中引用 i2c0_pins1 这个节点。

```c
&i2c0 {
	status = "okay";
	pinctrl-names="default";
	pinctrl-0=<&i2c0_pins1>;
	clock-frequency = <400000>; /* default 400k */
};
```

根据上表表格，知道处除了 GPIOAO_0 是 Pogo Fault INT 之外，其他的都是默认的 GPIO 功能， 所以不需要管。

如果是 uboot 也类似，functiong 定义在 `u-boot/drivers/pinctrl/meson/pinctrl-meson-a4.c` 中。

## Read hw_id

在 ba400 内核启动的时候会有这一行打印

```sh
[    0.000000@0]  Built 1 zonelists, mobility grouping on.  Total pages: 258048
[    0.000000@0]  Kernel command line: init=/init console=ttyS0,921600 no_console_suspend earlycon=aml-uart,0xfe07a000 ramoops.pstore_en=1 ramoops.record_size=0x8000 ramoops.console_size=0x4000 loop.max_part=4 rootfstype=ramfs otg_device=1 logo=osd0,loaded,0x00300000 vout=1080p60hz,enable panel_type=lcd_1 hdmitx=,444,8bit hdmimode=1080p60hz hdmichecksum=0x00000000 frac_rate_policy=1 cvbsmode=576cvbs video_reverse=0 irq_check_en=0 androidboot.selinux=enforcing androidboot.firstboot=1 jtag=disable androidboot.bootloader=01.01.230613.164423 androidboot.hardware=amlogic androidboot.serialno=ap22241345631b5746456 androidboot.wificountrycode=US meson-gx-mmc.caps2_quirks=mmc-hs400 androidboot.force_normal_boot=1 reboot_mode=cold_boot
```

发现上面没有 hw_id , 对应 Korlan 的

```sh
[    0.000000@0] Kernel command line: otg_device=1 hw_id=0x04 warm_boot=1 androidboot.reboot_mode=watchdog_reboot androidboot.hardware=korlan-p2 rootfstype=ramfs init=/init console=ttyUSB0,115200 console=ttyS0,115200 no_console_suspend earlycon=aml_uart,0xfe002000 quiet loglevel=7 ramoops.pstore_en=1 ramoops.record_size=0x8000 ramoops.console_size=0x4000 selinux=1 enforcing=0
```

在 `korlan-sdk/u-boot/board/amlogic/configs/a1_korlan_b1.h` 这个文件中， 可以发现 

```c
 "get_hw_id=" \
    "get_board_hw_id;" \
    "\0" \

"run get_hw_id;" \
```

可以知道，get_hw_id 其实基就是 get_board_hw_id 这个命令。获取 hw_id 。

因为在 这个命令的实现源码中，已经将 hw_id_str 写入到环境变量的 hw_id 中，可以看下面的代码。

```c
env_set("hw_id", hw_id_str);
```

所以在上面的 `"hw_id=${hw_id}` 就可以获取到 hw_id 。

**get_board_hw_id 命令的实现 patch**: 0001-Add-read-hw_id-from-uboot-to-kernel.patch

打上 patch 最终在启动 kernel log 中能够看到 hw_id





