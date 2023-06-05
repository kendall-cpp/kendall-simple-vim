
https://confluence.amlogic.com/pages/viewpage.action?pageId=262486727

# 测试 UAC 是否丢包

## 1 channel

对于 1 个通道的数据而言，1ms 传输 192 byte 的数据。即 `int aml_tdm_br_write_data(void *data, unsigned int len)` 中 `len == 192` 。

**丢包情况**

- 一个 192 byte 内部丢失
- 丢失整个 192byte 的包

**设计原始数据**

一个数据包 192 byte ， 每 4 个字节写入一个 int 数据，所以一个包能写入 48 个 int 数字。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.5ndzvygtbf40.webp)

### 生成原始数据代码

```c
#include <stdio.h> 
#include <stdlib.h>

#define NUM_PACKETS 1000*60*60 // 数据包数量
#define PACKET_SIZE 192*3 // 数据包大小，单位字节 如果测试两个 ch，直接改成 384
#define FRAME_SIZE 4 // 帧大小，单位字节

int main() {
    char filename[] = "data-ch1.bin"; // 文件名
    FILE *fp;
    unsigned char packet[PACKET_SIZE];
    int frame_num, i;

    // 分配并初始化数据包
    for (i = 0; i < PACKET_SIZE; i += FRAME_SIZE) {
        frame_num = i / FRAME_SIZE;
        *(int *)(packet + i) = frame_num;
    }   

    // 生成数据并写入文件
    if ((fp = fopen(filename, "wb")) == NULL) {
        printf("Error: cannot open file %s!\n", filename);
        exit(EXIT_FAILURE);
    }   
    for (i = 0; i < NUM_PACKETS; ++i) {
        fwrite(packet, PACKET_SIZE, 1, fp);
    }   
    fclose(fp);

    printf("Data generation complete.\n");

    return 0;
}
```

附件： test-miss-tdm_data.c

### 生成 data-ch1.bin 数据

通过上面 C 程序生成 data-ch1.bin， 查看 data-ch1.bin 数据是否正确。
```sh
hexdump -C data-ch1.bin -n 576
```

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.4510w4xufps0.webp)

### 开始测试

打上patch : test_miss_uac.patch

开始测试

- 将开发板与 linux PC  连接，在 linux PC (host) 播放 

```
aplay  -Dhw:1,0 -c 2 -r 48000 -f S32_LE data-ch1.bin
```

- 在板子端开启测试

```sh
echo 1 > /sys/module/snd_soc/parameters/start_write
```

- 如果未出现任何错误打印，说明 UAC 未出现丢包


## 2 channel

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.f76io2ycjps.webp)

### 生成原始数据代码

只需要将每毫秒 192 byte 数据改成 384 byte 即可， 最终生成 data-ch2.bin

```c
#include <stdio.h> 
#include <stdlib.h>

#define NUM_PACKETS 1000*60*60 // 数据包数量
#define PACKET_SIZE 384*3 // 数据包大小，单位字节 如果测试两个 ch，直接改成 384
#define FRAME_SIZE 4 // 帧大小，单位字节

int main() {
    char filename[] = "data-ch2.bin"; // 文件名
    FILE *fp;
    unsigned char packet[PACKET_SIZE];
    int frame_num, i;

    // 分配并初始化数据包
    for (i = 0; i < PACKET_SIZE; i += FRAME_SIZE) {
        frame_num = i / FRAME_SIZE;
        *(int *)(packet + i) = frame_num;
    }   

    // 生成数据并写入文件
    if ((fp = fopen(filename, "wb")) == NULL) {
        printf("Error: cannot open file %s!\n", filename);
        exit(EXIT_FAILURE);
    }   
    for (i = 0; i < NUM_PACKETS; ++i) {
        fwrite(packet, PACKET_SIZE, 1, fp);
    }   
    fclose(fp);

    printf("Data generation complete.\n");

    return 0;
}
```

**测试方法同上**

> **【注意】：**  patch 无需任何改动
> - **host**: aplay  -Dhw:1,0 -c 2 -r 48000 -f S32_LE data-ch2.bin
> - **device**： echo 1 > /sys/module/snd_soc/parameters/start_write