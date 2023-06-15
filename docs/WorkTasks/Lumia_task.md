# bringup 

- schematic review
  - wait google share pinmux settings
  - compare amlogic reference deltas with google
  - Finish secure boot (bootloader) 

- kernel  编译

./build_kernel.sh longyan-proto

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

#### 学习配GPIO

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

