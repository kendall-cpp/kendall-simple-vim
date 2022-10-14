# 第一章

## 基本概念

ARM 体系结构是一种硬件规范，主要用来约定指令集，为了降低客户基于 ARM 体系结构开发处理器的难度，ARM 根据不同的应用开发需求开发出箭筒体系结构的处理器 IP，然后授权给客户，比如 ARMv8 体系结构开发出的处理器 IP 有：Cortex-A53, Cortex-A55, Cortex-A72, Cortex-A73,.

**ARMv8 体系结构特性**

- 提供超过 4G 物理内存空间
- 具有 64 位宽的虚拟地址空间，32 位宽的虚拟地址空间只能供 4GB 大小的虚拟空间访问，限制了桌面操作系统和服务器的应用。

> ARMv8 体系结构包含多少个通用寄存器？

- **提供 31 个 64 位宽的通用寄存器**。分别是 X0~X30 。可以减少对栈的访问，从而提高性能。
- 提供 16KB 和 64KB 的页面，有助于降低 TLB 的未命中率。
- 具有全新的异常处理模型，降低操作系统和虚拟化的实现复杂度。

A64 指令集和 A32 指令集是不兼容的，它们是完全不一样的指令集，它们的指令编码时不一样的，另外 A64 指令集的指令宽度是 32 位，而不是 64 位。

ARMv8 处理器支持两种执行状态， AArch64 和 AArch32 ,当处理器在 AArch64 状态时，运行 A64 指令集，而处理器在 AArch32 状态时，运行 A32 和 T32 指令集，

> AArch64 执行状态包含多少个异常等级？分页有什么作用？

AArch64 执行状态的异常等级确定了处理器当前运行的特权级别，类似特权等级。
- EL0: 用户特权，用于运行普通用户程序
- EL1: 系统特权，通常用于操作系统内核，如果系统使能了虚拟化扩展，运行虚拟机操作系统内核。
- EL2: 运行虚拟化扩展的虚拟机监控器
- EL3: 运行安全世界中的安全监控器

**ARMv8 支持的数据宽度**

- 字节（byte）: 8位
- 半字（halfword）: 16位
- 字（word）：32位
- 双字（doubleword）: 64位
- 四字（quadword）： 128位

## ARMv8 寄存器

### 31个通用寄存器

在 AArch64 状态下，使用 X(X0、X30) 表示 64 位通用寄存器，另外**可以使用 W 来表示低 32 位的数据**，如 W0 表示 X0 寄存器的低 32 位数据， W1 表示 X1 寄存器的低 32 位数据。

![](https://gitee.com/linKge-web/PerPic/raw/master/bookImg/ARM64biancheng/AArch64状态的31个通用寄存器.png)

### 处理器的状态

AArch64 体系结构使用 PSTATE 寄存器来保存当前处理器状态

条件标志位： N（负位） Z（零位） C（进位） V（溢出标志位）

### 特殊寄存器

- 零寄存器

ARMv8 有两个零寄存器，这些寄存器的内容全是 0 ，可以用作源寄存器，也可以用作目标寄存器。WZR 是32位的零寄存器，XZR 是64位的零寄存器。

- PC 指针寄存器

通常用来指向当前运行指令的下一条指令的地址，用于控制程序的运行顺序。

- SP 寄存器

ARMv8 支持 4 个异常等级，每个异常等级都有一个 SP 寄存器

	- SP_EL0: EL0 下的 SP 寄存器（最低等级）
	- SP_EL1: EL1 下的 SP 寄存器
	- SP_EL2: EL2 下的 SP 寄存器
	- SP_EL3: EL3 下的 SP 寄存器

当处理器运行在 EL0 时，它只能访问 SP_EL0 ,不能访问其他高级的 SP 寄存器。

- 备份程序状态寄存器

当我们运行一个异常处理程序时，处理器的备份程序会保存到**备份程序状态寄存器**（SPSR）里面，当异常要发生时，处理器会把 PSTATE 寄存器的值暂时保存到 SPSR 里，当异常处理完成返回时，再把 SPSR 寄存器的值恢复到 PSTATE 寄存器。

![](https://gitee.com/linKge-web/PerPic/raw/master/bookImg/ARM64biancheng/SPSR.png)

- ELR

存放异常返回地址

- CurrentEL 寄存器

表示 PSTATE 寄存器中的 EL 字段（当前异常等级），该寄存器保存了当前的异常等级，可以使用 MRS 指令读取当前异常等级。

- DAIF 寄存器

表示 PSTATE 寄存器中的{D, A, I, F}字段（异常掩码标志位）。

- SPSel 寄存器

表示 PSTATE 寄存器中的 SP 字段，用于选择某个 SP_ELn 寄存器。

- PAN 寄存器

表示 PSTATE 寄存器中 PAN(特权禁止访问)字段。可以通过 MSR 和 MRS 指令来设置 PAN 寄存器，主要是为了防止内核态恶意访问用户态内存而新增的，所以需要调用内核提供的结构，比如 `copy_from_user()` 或者 `copy_to_user()` 函数。

> - 0: 表示在内核态可以访问用户态内存
> - 1： 表示在内核态访问用户态内存会触发一个访问权限异常

- UAO 寄存器

表示 PSTAYE 寄存器中的 UAO (用户访问覆盖) 字段。同样可以使用 MSR 和 MRS 指令来设置，

> UAO=1 时，表示在 EL1 和 EL2 执行非特权指令（例如 LDTR 和 STTR）的效果和特权指令（例如 LDR、STR）是一样的。

- NACV 寄存器

表示 PSTATE 寄存器中的{N, Z, C, V}字段 (条件标志位)。

### 系统寄存器

系统寄存器支持不同的异常等级的访问，通常系统寄存器会使用“Reg_ELn"的方式来表示

- Reg_EL1: 处理器处于 EL1、EL2 和 EL3 时可以访问该寄存器
- Reg_EL2: 处理器处于 EL2 和 EL3 时可以访问该寄存器

除了 CTR_EL0 ，大部分系统寄存器不支持处理器处于 EL0 时范访问。

----

# 第二章

## 加载与存储指令

在 ARMv8 体系结构下，所以的数据都需要在通用寄存器中完成，而不能直接在内存中完成，因此，首先把待处理的数据从内存加载到通用寄存器，再进行数据处理，最后再把结果写入到内存中。

- LDR **内存加载指令**
- STR **存储指令**

```c
LDR 目标基础漆，<存储器地址>   //把存储器地址中的数据加载到目标寄存器中
STR 源寄存器， <存储器地址>    //把源寄存器的数据存储到存储器中
```

## 基于基地址的寻址模式



### 基地址模式

- 使用寄存器的值来表示一个地址
- 把这个内存地址的内容加载到通用寄存器中

```c
LDR Xt, [Xn]  //把 Xn 寄存器中的内容作为内存地址，并把这个内存地址的内容加载到 Xt 寄存器中

STR xt, [Xn]  //把 Xt 寄存器中的内容存储到 Xn 寄存器的内存地址中
```

### 基地址+偏移地址模式

- 基地址 + 偏移地址 = 内存地址
- 把这个内存地址的值加载到通用寄存器中

```c
LDR Xt, [Xn. #offset] //Xn寄存器中的内容加一个偏移量（offset 必须是 8 的倍数），以相加的结果作为内存地址，加载这个内存地址的内容到 Xt 寄存器中。

STR Xt，[Xn. #offset]  //把 Xt 寄存器的值存储到以 Xn 寄存器的值加一个偏移量表示的内存地址中
```

### 基地址扩展模式

```c
LDR <Xt>, [<Xn>, (<Xm>) {, <extend> {<amount>}}]

STR <Xt>, [<Xn>, (<Xm>) {, <extend> {<amount>}}]
```

- Xt: 目标寄存器
- Xn：基地址寄存器
- Xm，偏移的寄存器
- extend：扩展/移位 指示符，默认是 LSL（逻辑左移），UXTW（从寄存器中提取32位，其余高位填充0），SXTW（从寄存器中提取32位，其余高位须有符号扩展），SXTX（从寄存器中提取64位数据）,UXTB（对寄存器的低8位进行无符号扩展），SXTB（对寄存器的低8位进行有符号扩展）
- amount：索引偏移量，当 extend 不是 LSL 时有效

```c
LDR X0, [X1, X2 LSL #3]   //内存地址为 X1 寄存器的值（X2 寄存器的值<<3），加载这个内存地址的值到 X0 寄存器

LDR X0, [X1, W2, SXTW, #3]  //先对 W2 的值做有效符号扩展，然后左移 3 位，和 X1 寄存器的值相加后得到内存地址，加载这个内存地址的值到 X0 寄存器
```

#### 变基模式

- 前变基模式：先更新偏移量地址，后访问内存地址
- 后变基模式：先访问内存地址，后更新偏移量地址

##### 前变基模式

**内存加载指令**

```c
LDR Xt, [<Xn|SP>, #<simm>]
```

- 首先，Xn/SP 寄存器的值 = Xn/SP 寄存器的值 + simm
- 以新的 Xn/SP 寄存器的值作为内存地址，并加载这个内存地址的值到 Xt 寄存器

**存储指令**

```c
STR Xt, [<Xn|SP>, #<simm>]
```

- 首先，Xn/SP 寄存器的值 = Xn/SP 寄存器的值 + simm
- 以新的 Xn/SP 寄存器的值作为内存地址，然后把 Xt 寄存器的值存储到这个内存单元中

##### 后变基模式

**内存加载指令**

```c
LDR Xt, [<Xn|SP>, #<simm>]
```

- 首先，加载 Xn/SP 寄存器的值到 Xt 寄存器
- 然后更新，Xn/SP 寄存器的值 = Xn/SP 寄存器的值 + simm

**存储指令**

```c
STR Xt, [<Xn|SP>, $<simm>]
```

- 首先，将 Xt 寄存器的值加载到 Xn/SP 寄存器的值为内存地址的内存单元中
- 然后更新，Xn/SP 寄存器的值 = Xn/SP 寄存器的值 + simm

#### 易混例子

```c
//（X1的值不变）
LDR X0, [X1, #8]    //内存地址为 X1的值+8，加载此内存地址的值到 X0 寄存器

//（X1的值改变）
LDR X0, [X1, #8]!    //前变基模式，先更新 X1 寄存器的值 = X1 寄存器的值 + 8，然后将 X0 的值加载到新的 X1 寄存器值对应的内存单元中

//（X1的值改变）
LDR X0, [X1], #8     //后变基模式，以 X1 的值作为内存地址，加载该内存地址的值到 X0 中，然后更新 X1 寄存器的值 = X1 寄存器的值 + 8

STP X0， X1, [SP, #-16]!   //把 X0 和 X1 寄存器的值压回栈中

LDP X0, X1, [SP], #16	  //把 X0 和 X1 寄存器的值出栈给 X0 和 X1
```

#### PC相对地址模式

可以使用 lable 标签来标记代码片段，LDR 指令可以访问标签的地址

```c
LDR Xt <label>
```

读取 label 所在内存地址的内存到 Xt 寄存器中，但是这个 label 必须在当前 PC地址后 1MB 的范围内，否则会报错。

```c
my_data:
	.word 0x40
ldr x0, my_data  // 最终 X0 寄存器的值为 0x40
```

假设当前 PC 的地址是 0x806E4, 那么这条 LDR 指令读取 0x806E4 + 0x20 地址的内容到 X6 寄存器中。（ PC + 0x40 内存单元的值）

```c
#define MY_LABEL 0x20
ldr x6, MY_LABEL


// error 0x100000 的偏移量超超出 1MB 范围
#define MY_LABEL_1 0x100000
ldr x6, MY_LABEL_1
```

#### LDR 伪指令

伪指令是对汇编器发出的指令，伪指令可以分解为几条指令的集合。

LDR 指令既可以在大范围内加载地址的伪指令，也可以是普通的内存访问指令。当第二个参数前面有 “=” 时，表示伪指令，否则表示普通的内存访问指令。

```c
LDR Xt, =<label>  //把label标记的地址加载到 Xt 寄存器

#define MY_LABEL 0x20
ldr x6, =MY_LABEL
//这里的 ldr 是一条伪指令，它会把 MY_LABEL 宏的值加载到 X6 寄存器中

my_data1:
	.quad 0x8
ldr x5, =my_data1
ldr x6, [x5]
//my_data1 定义了一个数据为 0x8，第一条 LDR 是伪指令，它把 my_data1 对应的地址加载到 X5 寄存器中
//第二条 LDR 是普通的内存访问指令，以 X5 寄存器的值为内存地址，加载这个地址的内容到 X6 中
```

> 简而言之，伪指令是把地址给目标寄存器，而普通指令是把地址的值给目标指令

linux 内核的 head.S 中，启动 MMU 之后就使用这个特性实现从运行地址定位到链接地址。

```c
secondary_startup:   
    bl  __cpu_secondary_check52bitva
    bl  __cpu_setup  // initialise processor
    bl  __enable_mmu  
    ldr x8, =__secondary_switched  //跳转到__secondary_switched函数，该函数的地址是链接地址（内核空间的虚拟地址），
	// 在这之前CPU运行在实际物理地址上，实现了地址重定位功能
    br  x8  
ENDPROC(secondary_startup)
```

## 加载与存储指令的变种

### 不同位宽的LDR和STR指令

| 指令  | Describe                         |
| :---: | :------------------------------- |
|  LDR  | 数据加载指令                     |
| LDRSW | 有符号的数据加载指令，单位：字   |
| LDRB  | 数据加载指令，单位：字节         |
| LDRSB | 有符号的加载指令，单位：字节     |
| LDRH  | 数据加载指令，单位：半字         |
| LDRSH | 有符号的数据加载指令，单位：半字 |
| STRB  | 数据存储指令，单位：字节         |
| STRH  | 数据存储指令，单位：半字         |

```c
1 my_data:
2 	.quad 0x8a
3 ldr x5, =my_data	//使用LDR伪指令加载标签my_data的内存地址
4 ldrb x1, [x5]
5 ldrsb x2, [x5]
```

- 第 4 行使用 LDRB 指令（无符号）读取标签 my_data 内存地址中第 1 字节的数据（0x8a)，此时读取的数据为 0x000000000000008A。
- 第 5 行使用 LDRB 指令（有符号）读取标签 my_data 内存地址中第 1 字节的数据（0x8a)，此时读取的数据为 0xFFFFFFFFFFFFFF8A

### 不可扩展的指令：LDUR 和 STUR

- 可扩展，使用偏移量按照数据大小来扩展，取值范围是（0~32760），
- 不可扩展，偏移量只能按照字节来扩展，取值范围（-256~256）。

```c
LDUR Xt, [Xn|SP, #simm]
STUR Xt, [Xn|SP, #simm]
```

### 多字节内存指令

```c
LDP Xt1, Xt2, [Xn|SP, #simm]   //出栈
```

以 Xn/SP 寄存器的值+simm 地址的值作为内存地址，然后将该内存地址的值给 Xt1， 接着读取 Xn/SP 寄存器的值+simm+8（内存对齐）的值给 Xt2.

```c
STP Xt1, Xt2, [Xn|SP, #simm]   //入栈
```

以 Xn/SP 寄存器的值+simm 地址的值作为内存地址，把 Xt1 寄存器的值存储到这个内存地址中 ， 接着将 Xt2 的值存储到 Xn/SP 寄存器的值+simm+8（内存对齐）处。

```c
STP Xt1, Xt2, [Xn|SP, #simm]!   //前变基模式
```

先计算 Xn寄存器的值=Xn寄存器的值+simm，然后以新的 Xn 寄存器的值为内存地址，把 X1 寄存器的值存储到这个地址处，再把 X2 寄存器的值存储到这个内存地址+8 处。

> 注意偏移量 simm 必须要满足
> - simm 取值范围为 -512~504
> - simm 必须为 8 的倍数

## 入栈和出栈

栈通常用来保存以下内容

- 临时存储的数据，例如局部变量，传递参数等
- 参数，在函数调用过程，如果传递的参数少于或等于 8 个，那么使用 X0~X7 通过寄存器来传递，当参数多于 8 个，就需要使用栈来传递。

栈从高低地址往低地址生长，数据出栈，SP 增大，数据入栈，SP 减小，栈空间扩大；数据出栈，SP 增大。栈空间减小。

```c
.globalmain
main:
	//栈往下扩展16字节
	stp x29, x30, [sp, #-16]！

	//把栈继续往下扩展8字节（相当于栈帧向下移一位）
	stp sp, sp, #-8

	mov x8, #1

	//x8保存到SP指向的位置上
	str x8, [sp]

	//释放刚才扩展的8字节的栈空间（栈帧向上移动一位，将X8的值出栈）
	add sp, sp, #8

	//main函数返回 0
	mov w0, 0

	//恢复x29和x30寄存器的值，使SP指向原位置（将X29和x30出栈）
	ldp x29, x30, [sp], #16
	ret
```

## mov指令

```c
mov <Xd|SP>, <Xn|SP>  //寄存器之间的搬移
mov <Xd>, $imm		  //立即数之间的搬移
```

## 算数和移位指令
### 加法指令

```c
add x0, x1, #1	//把x1寄存器的值加过加上立即数 1，结果写进x0寄存器中
add x0, x1, #1, LSL 12	//把立即数 1 算数左移 12 位，然后再加 x1 寄存器的值，结果写入 x0 寄存器中
```

注意：立即数是一个无符号的，取值范围为 0~4095

```c
add x0, x1, x2    //x0=x1+x2
add x0, x1,x2, LSL 2	//x0=x1+(x2 << 2)

mov x1, #1
mov x2, #0x8a
add x0, x1, x2, UXTB
//运行结果是 0x8B，UXTB 对寄存器 x2 进行无符号扩展，结果为0x8a，再加上 X1 寄存器的值，x0最终结果为0x8b
add x0, x1, x2, SXTB	
// SXTB 对 x2 寄存器的值低8位进行有符号扩展，结果为0xFFFFFFFFFFFFFF8A，然后再加上 X1 寄存器的值，x0最终结果为0xFFFFFFFFFFFFFF8B
```

### 移位操作的加法指令

```c
add x0, x1, x2, LSl, 3	//x0=x1+(x2<<3))
```

注意，移位的取值范围 0~63

- ADDS 指令

adds 指令是 add 指令的变种，它们的区别是指令执行结果会影响 PSTATE 寄存器的 N、Z、C、V 标志位，例如当计算结果发生无符号数溢出时，C=1 。

```c
mov x1, 0xffffffffffffffff
adds x0, x1, #2
mrs x2, nxcv
```

x1 的值（0xffffffffffffffff）加上立即数 2 一定会触发无符号溢出，最终 X0 寄存器的值为 1，同时还设置 PSTATE 寄存器的 C 标志位为 1，我们可以通过读取 NZCV 寄存器来判断，最终 X2 寄存器的值为 0x20000000 ，说明第 29 位的 C （进位标志）字段置 1，

ADC xd，xn, xm	//Xd寄存器的值等于 Xn 寄存器的值加上 Xm 寄存器的值加上 C ，C表示 PSTATE 寄存器的 C 标志位。

```c
mov x1, oxffffffffffffffff
mov x2, #2

adc x0, x1, x2
mrs x3, nzcv
```

ADC 指令计算过程： 0xFFFFFFFFFFFFFFFF + 2 + C ，因为 0xFFFFFFFFFFFFFFFF + 2 的过程中已经出发了无符号溢出，C=1 ，所以最终计算 X0 寄存器的值为 2，如果读取 NZCV 寄存器，发现 C 标志位也被置为 1 了。

### SUB 指令

减法指令

```c
sub x0, x1, #1	//把 x1 寄存器的值减去立即数 1，结果写入 x0 寄存器
//把立即数1算数左移12位，然后把x1寄存器中的值减去（1<<12），把结果写入 x0 寄存器中
sub x0, x1, #1, LSL 12	
```

```c
1 mov x1, #1
2 mov x2, #0x108a
3 sub x0, x1, x2, UXTB
4 sub x0, x1, x2, SXTB
```

UXTB 对 x2 寄存器的低 8 位数据进行无符号扩展，结果为 0x8a ， 然后再计算 1-0x8a 的值，最终结果为 0xffffffffffffff77

SXTB 对 x2 寄存器的低 8 位数据进行有符号扩展，结果为 0xffffffffffffff8a，然后再计算 1-0xffffffffffffff8a ，最终结果为 0x77 。

```c
sub x0, x1, x2, LSL, 3  //x0 = x1 0 (x2 << 3)
```

### SUBS 指令

减法指令，但是会影响 PSTATE 寄存器的 N、Z、C、V 标志

该指令的计算过程： operand1 + NOT(operand2) + 1  // NOT 表示按位取反

```c
mov x1, 0x3
mov x2, 0x1
subs x0, x1, x2
mrs x3, nzcv	//读取 nzcv 寄存器的值——0x200000000
```

x2 的值为 0x1，按位取反后的值为 0xfffffffffffffffe , 3 + 0xfffffffffffffffe + 1 , 这个过程会发生无符号溢出，因此 4 个标志位中的 C=1，最终计算结果为 2 。

### SBC 指令

进位减法指令，也就是最终计算结果需要考虑 PSTATE 寄存器的 C 标志位

该指令的计算过程；Xd = Xn + NOT(Xm) + C

```c
mov x1, #3
mov x2, #1
sbc x0, x1, x2
mrs x3, nzcv
```

3 + not(1) + C , 1 按位取反为 0xfffffffffffffffe ， 3 + 0xfffffffffffffffe 过程会发生溢出，所以 C=1，再嘉善标志位 C，结果为 2.


## 比较大小指令 CMP

CMP 指令用来比较两个数的大小，在 A64 中，CMP 指令内部调用 SUBS 指令来实现

```c
cmp x1, x2		// x1 + not(x2) + 1
// 跳转到 label 处
b.cs label		//CS 表示发生了无符号溢出，即 C 标志位置位，CC 表示 C 标志位没有置位
```

```c
my_test:
	mov x1, #3
	mov x2, #2
1:
	cmp x1, x2
	b.cs lb

	ret
```

b 指令的操作由后缀 cs 决定，cs 表示判断是否发生无符号溢出，3 + not(2) + 1 , not(2) = 0xfffffffffffffffd , 3 + 0xfffffffffffffffd + 1 = 1， ，这个过程发生了溢出，C 标志位置为 1， 所以 b.cs 的判断条件成立，跳转到标签 1 处，继续执行。

- 比较 x1 和 x2 的寄存器的值大小

```c
my_test:
	mov x1, #3
	mov x2, #2
1:
	cmp x1, x2
	b.ls, 1b

	ret
```

在比较 x1 和 x2 寄存器的值大小时，判断调教为 LS，表示无符号小于或者等于，那么，在这个比较过程中，我们就不需要判断 C 标志位了，直接判断 x1 寄存器的值是否 小于或等于 x2 寄存器的值即可。因此这里不会跳转到标签 1 处。

### 以条件标志位示例 array_index_mask_nospec

内核中 array_index_mask_nospec 函数用来实现一个掩码

- when $index \geq size$, return 0
- when $index < size$, return 掩码 0xFFFFFFFFFFFFFFFF

```c
  static inline unsigned long array_index_mask_nospec(unsigned long idx, unsigned long sz) 
  {
      unsigned long mask;
   
      asm volatile(
      "   cmp %1, %2\n"
      "   sbc %0, xzr, xzr\n"
      : "=r" (mask)
      : "r" (idx), "Ir" (sz)
      : "cc");
   
      csdb();
      return mask;
  }
```

上述内嵌汇编转成纯汇编代码

```c
cmp x0, x1
sbc x0, xzr, xzr
```

x0 寄存器的值 idx，x1 寄存器的值 sz，当 $ldx < sz$ 时，cmp 指令没有产生无符号数溢出，C 标志位为 0，当 $idx \geq sz$ cmp 指令产生了无符号溢出（其实内置是使用了 subs 指令来实现），C 标志位会置 1。

根据 SBC 指令的计算： 0 + NOT(0) + C = 0-1+C

- 当 index 小于 size 时，C = 0， 最终计算结果为 -1，也就是 0xFFFFFFFFFFFFFFFF 。

- 当 index 大于或等于 size 时，C = 1， 最终计算结果为 0.

## 移位指令

- LSL：逻辑左移指令，最高位会被丢弃，最低位补 0。
- LSR：逻辑右移指令，最高位补 0，最低位会被丢弃
- ASR：算术右移指令，最低位会被丢弃，最高位会按照符号进行扩展。
- AOR：循环右移指令，最低位会移动到最高位

> A64 指令集里没有单独设置算术左移的指令，因为 LSL 指令会把最高位舍弃了

```c
ldr w1, =0x8000008a
asr w2, w1, 1
lsr w3, w1, 1
```

- ASR 是算术右移指令，把 0x8000008A 右移一位并且对最高位进行有符号扩展，最后结果为 0xC0000045 
- LSR 是逻辑右移指令，把 0x8000008A 右移一位并且在最高位补 0，最后结果为 0x40000045 。

## 位操作指令
### 与操作指令

AND：按位 与 操作

ANDS：带条件标志位的 与 操作，影响 Z 标志位。

```c
mov x1, #0x3
mov x2, #0

ands x3, x1, x2   // 0x3 和 0 做 “与” 操作
mrs x0, nzcv		//与 的结果为 0，读取 NZCV 寄存器，可以看到 Z 标志位了
```

### 或操作指令

```c
ORR Xd|SP, Xn, #imm
ORR Xd, Xn, shift #amount
```

- 立即数方式：对 Xn 寄存器的值与立即数 imm 进行 或 操作
- 寄存器方式：先对 Xm 寄存器的值做 移位 操作，然后再与 Xn 寄存器的值进行 或 操作

```
EOR Xd|SP, Xn, #imm
EOR Xd, Xn, Xm, shift #amount 
```

- 立即数方式：对 Xn 寄存器的值与立即数 imm 进行 异或 操作
- 寄存器方式：先对 Xm 寄存器的值做 移位 操作，然后再与 Xn 寄存器的值进行 异或 操作

## 位段指令

### 位段插入 BFI

```c
BFI Xd, Xn, #lsb, #width
```

BFI 指令的作用是用寄存器 Xn 寄存器中的 Bit[0, width-1] 替换 Xd 寄存器中的 Bit[lsb, lsb+width-1] 替换 Xd 寄存器中的 Bit[lsb, lsb + width-1] , Xd 寄存器中的其他位不变。

```c
val &=~ (oxf << 4)	//val 表示寄存器 A 的值
val |= ( (u64)0x5 << 4)

mov x0, #0		//寄存器 A 的值初始化为 0
mov x1， #0x5	

bfi x0, x1, #4, #4	//往寄存器A的Bit[7,4}字段设置 0x5
```

BFI 指令把 X1 寄存器中的 Bit[3,0] 设置为 X0 寄存器中的 Bit[7,4], X0 寄存器中的 Bit[7,4] ,X0 寄存器的值是 0x50。

![](https://gitee.com/linKge-web/PerPic/raw/master/bookImg/ARM64biancheng/BFI指令.png)

### 位段提取操作指令 UBFIX

```c
UFBX  Xd, Xn, #lsb, #width
```

UBFX 作用是提取 Xn 寄存器的 Bit[lsb, lsb+width-1], 然后存储到 Xd 寄存器中。另外 SBFX 和 UBFX 的区别只是SBFX 会进行符号扩展，例如 Bit[lsb, lsb+width-1] 为 1，那么写到 Xd 寄存器之后，所有的高位都必须为 1，。

```c
mov x2, #0x8a
ubfx x0, x2, #4, #4
sbfx x1, x2, #4, #4
```


