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

参考： https://blog.csdn.net/q752933833/article/details/117718115?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522168710169616800192232565%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fall.%2522%257D&request_id=168710169616800192232565&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~first_rank_ecpm_v1~rank_v31_ecpm-1-117718115-null-null.142^v88^control_2,239^v2^insert_chatgpt&utm_term=vim%E4%B9%8B%E4%BB%A3%E7%A0%81%E8%B7%9F%E8%B8%AA&spm=1018.2226.3001.4187