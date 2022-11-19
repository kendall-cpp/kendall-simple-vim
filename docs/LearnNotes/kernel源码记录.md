
# 设备树

在Linux 2.6中， ARM架构的板极硬件细节过多地被硬编码在 `arch/arm/plat-xxx和arch/arm/mach-xxx` 中，采用**设备树**后，许多硬件的细节可以直接通过设备树传递给 Linux，而不再需要在内核中进行大量的冗余编码。

## 设备树中 DTS、DTC 和 DTB 的关系

- DTS：.dts 文件是设备树的源文件。由于一个SoC可能对应多个设备，这些 .dst 文件可能包含很多共同的部分，共同的部分一般被提炼为一个 .dtsi 文件，这个文件相当于C语言的头文件。
- DTC：DTC是将.dts 编译为 .dtb 的工具，相当于 gcc。
- DTB：.dtb文件是 .dts 被 DTC 编译后的二进制格式的设备树文件，它可以被 linux 内核解析。

设备节点的标准属性

### compatible 属性

compatible 属性也叫做“兼容性”属性，compatible 属性用于将设备和驱动绑定起来。字符串列表用于选择设备所要使用的驱动程序。

```c
"manufacturer,model"
```

- manufacturer : 表示厂商；
- model : 一般是模块对应的驱动名字。

比如 `imx6ull-alientek-emmc.dts` 中 sound 节点是 I.MX6U-ALPHA 开发板的音频设备节点，I.MX6U-ALPHA 开发板上的音频芯片采用的欧胜(WOLFSON)出品的 WM8960，sound 节点的 compatible 属性值如下：

```c
compatible = "fsl,imx6ul-evk-wm8960","fsl,imx-audio-wm8960";
```

sound 设备首先会使用第一个属性值在 Linux 内核里面查找，看看能不能找到与之匹配的驱动文件；

如果没找到，就使用第二个属性值查找，以此类推，直到查到到对应的驱动程序 或者 查找完整个 Linux 内核也没有对应的驱动程序为止。

```c
// ./sound/soc/fsl/imx-wm8960.c

static const struct of_device_id imx_wm8960_dt_ids[] = { 
  { .compatible = "fsl,imx-audio-wm8960", },
  { /* sentinel */ }                
};                                  
MODULE_DEVICE_TABLE(of, imx_wm8960_dt_ids);
                                    
static struct platform_driver imx_wm8960_driver = { 
  .driver = {                       
    .name = "imx-wm8960",           
    .pm = &snd_soc_pm_ops,          
    .of_match_table = imx_wm8960_dt_ids,
  },                                
  .probe = imx_wm8960_probe,        
  .remove = imx_wm8960_remove,   
};                                  
module_platform_driver(imx_wm8960_driver);
```

一般驱动程序文件都会有一个 OF 匹配表，此 OF 匹配表保存着一些 compatible 值，如果设备节点的 compatible 属性值和 OF 匹配表中的任何一个值相等，那么就表示设备可以使用这个驱动。数组 imx_wm8960_dt_ids 就是 `imx-wm8960.c` 这个驱动文件的匹配表，此匹配表只有一个匹配值“fsl,imx-audio-wm8960”。如果在设备树中有哪个节点的 compatible 属性值与此相等，那么这个节点就会使用此驱动文件。此行设置 `.of_match_table` 为 `imx_wm8960_dt_ids` ，也就是设置这个 platform_driver 所使用的 OF 匹配表。

### model 属性

一般 model 属性描述设备模块信息，比如名字什么的 ,

```c
model = "Samsung S3C2416 SoC";
```


### `#address-cells` 和 `#size-cells` 属性

这两个属性的值都是无符号 32 位整形，`#address-cells` 和 `#size-cells` 这两个属性可以用在任何拥有子节点的设备中，用于**描述子节点的地址信息**。

- `#address-cells` 属性值决定了子节点 reg 属性中地址信息所占用的字长(32 位)，
- `#size-cells` 属性值决定了子节点 reg 属性中长度信息所占的字长(32 位)。
  
`#address-cells` 和`#size-cells` 表明了子节点应该如何编写 reg 属性值，一般 reg 属性都是和地址有关的内容，和地址相关的信息有两种：起始地址和地址长度，reg 属性的格式一为：

```
reg = <address1 length1 address2 length2 address3 length3……>
```

每个“address length”组合表示一个地址范围，其中 address 是起始地址，length 是地址长度，`#address-cells` 表明 address 这个数据的起始地址，`#size-cells` 表明 length 这个数据所占用的字长.

例如一个64位的处理器：

```c
soc {
    #address-cells = <2>;  // 两个地址
    #size-cells = <1>;    // 1 代表一个32位
    serial {
        compatible = "xxx";
        reg = <0x4600 0x5000 0x100>;  /*地址信息是：0x00004600 00005000,长度信息是：0x100*/
        };
};
```

#### reg 属性

reg 属性的值一般是(address，length)对。reg 属性一般用于描述设备地址空间资源信息，一般都是某个外设的寄存器地址范围信息。比如 

```c
uart1: serial@02020000 { 
  ...
  reg = <0x02020000 0x4000>;
}
```

其中 uart1 的父节点 `aips1: aips-bus@02000000` 设置了`#address-cells = <1>、#size-cells = <1>`，因此 reg 属性中 `address=0x02020000，length=0x4000` 。


> 其他属性学习参考： https://zhuanlan.zhihu.com/p/425420889



----

# kernel 源码结构体里的元素前面有一点“.”

> 参考：http://blog.chinaunix.net/uid-29033331-id-3811134.html

例如：

```c
//gceSTATUS _AdjustParam(IN gcsPLATFORM *Platform,OUT gcsMODULE_PARAMETERS *Args)
//这些函数定义在上面

static gcsPLATFORM_OPERATIONS default_ops =
{
    .adjustParam   = _AdjustParam,
    .getPower  = _GetPower,
    .reset = _Reset,
    .putPower = _DownPower,
    .setPower = _SetPower,
    .getPowerStatus = _GetPowerStatus,
    .setPolicy = _SetPolicy,
};
```

这与我们之前学过的结构体初始化差距甚远。其实这就是前面所说的指定初始化在Linux设备驱动程序中的一个应用，它源自ISO C99标准。以下我摘录了C Primer Plus第五版中相关章节的内容，从而就可以很好的理解2.6版内核采用这种方式的优势就在于由此初始化不必严格按照定义时的顺序。这带来了极大的灵活性，其更大的益处还有待大家在开发中结合自身的应用慢慢体会。 已知一个结构，定义如下

```c
struct book { 
    char title[MAXTITL]; 
    char author[MAXAUTL]; 
    float value; 
};
```

C99支持结构的指定初始化项目，其语法与数组的指定初始化项目近似。只是，结构的指定初始化项目使用点运算符和成员名（而不是方括号和索引值）来标识具体的元素。例如，只初始化book结构的一个成员value，可以这样做： 

```c
struct book surprise = { .value = 10.99 }; 
```

可以按照任意的顺序使用指定初始化项目： 

```c
struct book gift = { 
    .value = 25.99, 
    .author = "James Broadfool", 
    .title = "Rue for the Toad"
};
```

正像数组一样，跟在一个指定初始化项目之后的常规初始化项目为跟在指定成员后的成员提供了初始值。