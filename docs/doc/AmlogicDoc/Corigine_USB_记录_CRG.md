# 概述

Corigine 的 USB 3.1 控制器 ip 是基于 USB-IF 的最新 USB 3.1 规范，并兼容 xHCI 1.1 规范。

支持超高速（10Gbps）链接速度，向后兼容超速（5Gbps，也称为USB3.0），高速（480Mbps），全速度（12Mbps）和低速（1.5Mbps）。

CRG 控制器可以作为三种角色

- Host-mode

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.6osvw9b2spc0.webp)

- Device-mode

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.1ppgo21tu5og.webp)

图中的设备 DMA 引擎和 CSR 是和 xhci-ring 管理、TRB 定义类似，是基于 环机制 实现的。

- Dual-Role Device mode (OTG)

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.2ia46xi3x2q0.webp)


# 接口

## Master interface(AXI)

CRG 控制器通过 AXI 接口获取 TRB 数据，并使用该接口将事件写入事件环。

## Slave interface(AXI / AHB / APB)

从接口主要用于访问 USB 设备控制器中的寄存器，包括中断处理和设备控制器的配置，

## Interrupt interface(Legacy/MSI)

中断接口，控制器通过这个接口通知 CPU 有事件要处理，系统软件会处理事件环中的所有事件。同时通知完 CPU 后，就需要通过中断寄存器清楚该中断。

## PHY Interface

接收和传输数据到 phy，选择 PHY 操作模式等。





