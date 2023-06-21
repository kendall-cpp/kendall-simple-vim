# 环境准备

在Ubuntu Linux 20.04可以通过如下命令来安装本书需要的软件包。

仓库： https://benshushu.coding.net/public/runninglinuxkernel_5.0/runninglinuxkernel_5.0/git/files

```sh
sudo apt install net-tools libncurses5-dev libssl-dev build-essential openssl qemu-system-arm libncurses5-dev gcc-aarch64-linux-gnu  bison flex bc  universal-ctags cscope   gdb-multiarch openjdk-13-jre trace-cmd kernelshark bpfcc-tools  docker docker.io -y
```

## 更新 apt 源

```sh
sudo apt-get update 
sudo apt-get upgrade -y 升级已经安装的软件
```


## 配置 linux

```sh
sudo apt install openssh-server -y  #下载安装ssh服务的服务器
sudo apt install openssh-client -y  #下载安装ssh服务的客户端

sudo apt install git

# 配置代理
ip_set=192.168.0.27
ip_set_port=7890
export my_proxy="${ip_set}:${ip_set_port}"
export http_proxy="${my_proxy}"
export https_proxy="${my_proxy}"
git config --global http.proxy http://${my_proxy}
git config --global https.proxy https://${my_proxy}
```

## vim 插件安装

> 推荐网址： https://zhuanlan.zhihu.com/p/547772348

### 安装 vim

sudo apt install vim -y

```sh
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

:PluginInstall 安装插件命令
:PluginList  列出已经安装的插件
:PluginUpdate  更新插件
卸载插件，列出所有已安装的插件 :PluginList 。然后将焦点移动到要卸载的插件上，按下 SHITF+d 组合键。然后编辑 ~/.vimrc 文件，删除插件入口。
或者，可以在 ~/.vimrc 文件中删除插件入口，执行 :PluginClean 命令，卸载插件。这个命令将会移除所有不在 ~/.vimrc 中但是存在于 ~/.vim/bundle 目录中的插件。
```

### ag

sudo apt-get install silversearcher-ag

```sh
cd ~/.vim/bundle && git clone https://github.com/rking/ag.vim ag && echo "set runtimepath^=~/.vim/bundle/ag" >> ~/.vimrc
```

### YouCompleteMe自动补齐插件

参考： https://blog.csdn.net/OIDCAT/article/details/106816941

```sh
cd ~/.vim/bundle
git clone https://github.com/Valloric/YouCompleteMe.git ~/.vim/bundle/YouCompleteMe

vim .vimrc
Plugin 'ycm-core/YouCompleteMe'

cd YouCompleteMe/
~/.vim/bundle/YouCompleteMe/third_party$ git clone https://github.com/ycm-core/ycmd.git
git submodule update --init --recursive  # 更新依赖模块  等很久

sudo apt-get install cmake
sudo apt install python3-dev
sudo apt-get install build-essential -y
sudo apt-get install llvm clang libclang-10-dev libboost-all-dev -y

# 非必要
# mkdir ycm_temp
# cd ycm_temp/
# # 下载地址： https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz

./install.sh --clangd-completer
```

### 安装 ctags

```sh
sudo apt-get install ctags
# 添加到 ~/.bashrc
alias ctags='ctags --fields=+iaS --extra=+q * --languages=c,c++'
```

### Tagbar

列出函数和变量

https://github.com/majutsushi/tagbar

```sh
Plugin 'majutsushi/tagbar'
```

### 目录树插件nerdtree

```sh
Plugin 'scrooloose/nerdtree'
```

### vim 主题插件molokai

Plugin 'tomasr/molokai'


### global gtags

wget http://tamacom.com/global/global-6.6.2.tar.gz

tar xzvf global-6.6.2.tar.gz

cd global-6.6.2

 ./configure  --prefix=/home/kendall/.vim/global/

 make && make install


```sh
find ./ -name "*.h" -o -name "*.c" -o -name "*.cpp" >gtags.files
gtags
```

### cscope

> 不使用

sudo apt-get install cscope -y

```sh
find ./ -name "*.h" -o -name "*.c" -o -name "*.cpp" > cscope.file
cscope -Rbkq -i cscope.file
# -R: 在生成索引文件时，搜索子目录树中的代码

# -b: 只生成索引文件，不进入cscope的界面

# -k: 在生成索引文件时，不搜索/usr/include目录

# -q: 生成cscope.in.out和cscope.po.out文件，加快cscope的索引速度
# 接下来，就可以在vim里读代码了。
```

帮我写个shell，进入执行脚本的目录，然后执行下面命令

```sh
find ./ -name "*.h" -o -name "*.c" -o -name "*.cpp" >gtags.files
gtags

ctags -R
```

# 处理器架构介绍

## 精简指令集和复杂指令集

> **精简指令集计算机（RISC） 和复杂指令集计算机（CISC） 的	U区别**

- 精简指令集计算机：只保留常用的简单指令，避免浪费太多的晶体管去完成那些很复杂又很少用的复杂指令
- 复杂指令集计算机，指令集全面，但是将近 80% 的指令很少被使用，会占用大量的晶体管。RISC 是基于 CISC 的优化。

## 大小端存储模式

> **简述大小端字节序，0x12345678在大小端处理器的存储器中如何存储？**	
> 首先回答下为什么需要大小端存储方式

计算机系统是以字节（byte）为单位进行存储计算信息的。每个地址单元对应 1 字节，`1 字节 = 8 位` 。但是对于 16 位，32 位等位数更高的处理器，由于寄存器的宽度大于 1 字节。

> 寄存器的宽度指的是寄存器可以存储的二进制位数。它表示寄存器可以同时处理的数据大小。例如，一个16位的寄存器可以存储16个二进制位，也就是可以处理16位的数据。

> 当说到16位的处理器宽度时，通常是指该处理器的寄存器的宽度为16位。这意味着该处理器可以一次性处理16位的二进制数据。处理器的宽度与其寄存器的宽度相关联，因为寄存器是处理器内部存储和处理数据的重要组成部分。

正是由于寄存器内部存储了多个二进制位数，所以就存储如何安排多字的问题，因此就有了大端存储模式和小端存储模式。

- 大端存储模式（Big Endian）中，高位字节（Most Significant Byte，MSB）会被存储在低地址，而低位字节（Least Significant Byte，LSB）会被存储在高地址。
- 小端存储模式（Little Endian）中，低位字节（LSB）会被存储在低地址，而高位字节（MSB）会被存储在高地址。
