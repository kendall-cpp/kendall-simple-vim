
- [重新安装 vim](#重新安装-vim)
  - [安装插件](#安装插件)
  - [升级 cmake](#升级-cmake)
- [vim插件安装和配置](#vim插件安装和配置)
- [主题colorsheme](#主题colorsheme)
- [YouCompleteMe 的安装和使用](#youcompleteme-的安装和使用)
  - [安装](#安装)
  - [使用](#使用)
- [ctags 使用](#ctags-使用)
  - [安装 ctags](#安装-ctags)
  - [使用 ctags](#使用-ctags)
  - [函数变量查找](#函数变量查找)
- [Ack 插件安装](#ack-插件安装)
  - [ACK使用](#ack使用)
  - [ubuntu 安装 ag](#ubuntu-安装-ag)
  - [结合使用](#结合使用)
- [nerdtree_red 使用](#nerdtree_red-使用)
- [vim 命令记录](#vim-命令记录)
  - [vim 查找替换](#vim-查找替换)
- [vscode 设置 markdown 字体](#vscode-设置-markdown-字体)


------

## 重新安装 vim

- 安装libncurses5-dev，否则编译时会报no terminal library found错误：

sudo apt install libncurses5-dev

- 由于这里要添加python支持，所以要装python3-dev(或者python-dev，对于python2用户)，否则编译时报Python.h: No such file or directory错误：

如果没有 python3

sudo apt-get install python3-dev

- 克隆Vim源代码，并进入目录

git clone https://github.com/vim/vim

cd vim

- 配置并执行

```sh
./configure --with-features=huge \
                  --enable-multibyte \
                  --enable-rubyinterp=yes \
                  --enable-python3interp=yes \
                  --with-python3-config-dir=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu \
                  --enable-pythoninterp=yes \
                  --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
                  --enable-perlinterp=yes \
                  --enable-luainterp=yes \
                  --enable-gui=auto \
                  --enable-cscope \
                  --prefix=/usr

# –with-features=huge：支持最大特性
# –enable-rubyinterp：打开对ruby编写的插件的支持
# –enable-pythoninterp：打开对python编写的插件的支持
# –enable-python3interp：打开对python3编写的插件的支持
# –enable-luainterp：打开对lua编写的插件的支持
# –enable-perlinterp：打开对perl编写的插件的支持
# –enable-multibyte：打开多字节支持，可以在Vim中输入中文
# –enable-cscope：打开对cscope的支持
# –with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu/ 指定python config路径
# –with-python-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu/ 指定python3 config路径(根据自己系统实际情况配置)
# –prefix=/usr：指定将要安装到的路径(可自行创建)
# –enable-gui：GUI支持，可用auto、gtk2或者gnome                  
```

### 安装插件

拷贝 vim.zip

直接到 .vim 下执行 `./run-pathogen.sh`

最后去 .vimrc 最上面添加

`source /home/book/.vim/run-pathogen.vim `

- 编译安装
  
make

sudo make install

### 升级 cmake

如果提示错误

```
CMake 3.14 or higher is required.  You are running version 3.10.2
```

分别执行下面命令升级 cmake

```sh
sudo apt remove --purge cmake
hash -r
sudo snap install cmake --classic
```

可能需要升级 C++ 支持 C++17

```sh
sudo apt-get install g++-8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 700 --slave /usr/bin/g++ g++ /usr/bin/g++-7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8
```

然后

```sh
/usr/bin/python3 /home/book/.vim/bundle/youcompleteme/third_party/ycmd/build.py --clang-completer --racer-completer --verbose
```

## vim插件安装和配置

在 Linux 系统上安装 Vundle 需要 Git 支持

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

> 参考：https://vim80.readthedocs.io/zh/latest/plugin/vundle.html


## 主题colorsheme

去这里的 colors 下下载自己想要的主题 https://github.com/flazz/vim-colorschemes

## YouCompleteMe 的安装和使用

### 安装

安装 cmake，否则会报：CMAKE IS REQUIRED TO BUILD YCMD 这个错。

```
sudo apt-get install cmake
```

报错：E: Unmet dependencies. Try 'apt --fix-broken install' with no packages (or specify a solution).

解决：

```
sudo apt --fix-broken install
sudo apt-get update
sudo apt-get upgrade
```

继续

```sh
cd ~/.vim/bundles
git clone https://gitee.com/zhuixixi/YouCompleteMe.git --depth=1 
cd ~/.vim/bundles/YouCompleteMe
python3 inst/usr/bin/python3 /home/book/.vim/bundle/youcompleteme/third_party/ycmd/build.py --verboseall.py --clang-completer

# 打开 vim 如果报错，The ycmd server SHUT DOWN (restart with ':YcmRestartServer'). YCM cor...le YCM before using it. Follow the instructions in the documentation，
# 解决方法
/usr/bin/python3 /home/book/.vim/bundle/youcompleteme/third_party/ycmd/build.py --verbose
```


### 使用

默认当键入两个字母之后, 则启动补全. 可以通过该变量调整: g:ycm_min_num_of_chars_for_completion
- 也可以使用原有的<c-x><c-o>来补全, ycm 将其功能增强了.
- 按照本文配置, 可用<c-j>跳转到定义处.
- 默认配置<TAB>会选择补全内容, 本文的配置将其屏蔽了, 为了不会与snipmate等需要tab的冲突, 选择补全改为了.


## ctags 使用

### 安装 ctags

sudo apt-get install ctags

### 使用 ctags

在源码目录下执行： `ctags -R` ，然后会生成一个 tags 文件，其实这个 tags 文件就是你的编码的所有文件的索引（比如变量索引，函数索引）。

最后在 .vimrc 下写入： `set tags=[your_path]./tags`, 或者在 vim 下直接执行 `：set tags=./tags ` 临时设置

> 不过还有一个小瑕疵, 你修改程序后, 比如增加了函数定义, 删除了变量定义, tags文件不能自动rebuild, 你必须手动再运行一下命令: `ctags -R`

### 函数变量查找

- 命令模式下  CTRL+]

- 查找完毕返回到当前：CTRL+O

## Ack 插件安装

> Ack 插件，和 ag 命令结合使用

插件地址：https://github.com/mileszs/ack.vim

安装：在 .vimrc 中添加 `Plugin 'mileszs/ack.vim'` ,然后再 vim 下执行 `:PluginInstall` 安装。

### ACK使用

vim 中输入 :Ack "字符串"

```sh
?           帮助，显示所有快捷键
Enter/o     打开文件
O           打开文件并关闭Quickfix
go          预览文件，焦点仍然在Quickfix
t           新标签页打开文件
q           关闭Quickfix
```

### ubuntu 安装 ag

sudo apt-get install silversearcher-ag

```
ag -i xxxxx					搜索忽略大小写
ag -A xxxxx     			搜索显示行号
ag -B 2 "root" /etc/passwd  并显示匹配内容之前的n行文本
ag -C 2 PATTERN			搜索含PATTERN文本，并同时显示匹配内容以及它前后各n行文本的内容。
ag -w PATTERN			 全匹配搜索，只搜索与所搜内容完全匹配的文本。
ag --ignore-dir /etc/ "kendall"  	忽略某些文件目录进行搜索。
```

命令使用参考 ：https://blog.csdn.net/weixin_39789796/article/details/117462856

### 结合使用

```
:Ack [options] {pattern} [{directories}]

?           帮助，显示所有快捷键
Enter/o     打开文件
O           打开文件并关闭Quickfix
go          预览文件，焦点仍然在Quickfix
t           新标签页打开文件
q           关闭Quickfix
```

结合 go >> q 退出。

## nerdtree_red 使用

```sh
ctrl + w + h    光标 focus 左侧树形目录
ctrl + w + l    光标 focus 右侧文件显示窗口
ctrl + w + w    光标自动在左右侧窗口切换
ctrl + w + r    移动当前窗口的布局位置

clrl + w + 方向键，左右窗口切换

o       在已有窗口中打开文件、目录或书签，并跳到该窗口
go      在已有窗口 中打开文件、目录或书签，但不跳到该窗口
t       在新 Tab 中打开选中文件/书签，并跳到新 Tab
T       在新 Tab 中打开选中文件/书签，但不跳到新 Tab
i       split 一个新窗口打开选中文件，并跳到该窗口
gi      split 一个新窗口打开选中文件，但不跳到该窗口
s       vsplit 一个新窗口打开选中文件，并跳到该窗口
gs      vsplit 一个新 窗口打开选中文件，但不跳到该窗口
!       执行当前文件
O       递归打开选中 结点下的所有目录
m    文件操作：复制、删除、移动等
```


-----

## vim 命令记录

- 搜索高亮
  - 高亮匹配结果中往下跳：n
  - 高亮匹配结果中往上跳：N
  - 关闭高亮：noh 。

-  翻屏
  - ctrl+f: 下翻一屏。
  - ctrl+b: 上翻一屏。
  - ctrl+d: 下翻半屏。
  - ctrl+u: 上翻半屏。
  - ctrl+e: 向下滚动一行。
  - ctrl+y: 向上滚动一行。
  - n%: 到文件n%的位置。
  - zz: 将当前行移动到屏幕中央。
  - zt: 将当前行移动到屏幕顶端。
  - zb: 将当前行移动到屏幕底端。

- 多行缩进缩出
  - 正常模式下，按两下>;光标所在行会缩进。
  - 如果先按了n，再按两下>;，光标以下的n行会缩进。
  - 对应的，按两下<;，光标所在行会缩出

- 查找
  - `*` 查找光标所在处的单词，向下查找
  - `#` 查找光标所在处的单词，向上查找
  - gd 跳至当前光标所在的变量的声明处
  - `^` 跳至行首的第一个字符
  - 0 跳至行首，不管有无缩进，就是跳到第0个字符
  - w 跳到下一个字首，按标点或单词分割
  - W 跳到下一个字首，长跳，如 end-of-line 被认为是一个字
  - b 跳到上一个字
  - B 跳到上一个字，长跳
  - `$` 跳到行尾

- 编辑
  - u 撤销
  - ctrl+r 重做
  - `>>` 将当前行右移一个单位
  - `<<` 将当前行左移一个单位(一个tab符)
  - `==` 自动缩进当前行



- 块模式 ctrl+v
  - d 删除
  - I 进入编辑，编辑完按 ESC 退出

### vim 查找替换

```sh
# 以下命令将1~3行所有的se替换为si
:1,3s/se/si/g 

# 将整个文件中每行找到的第1个se替换为si
:%s/se/si/ 
# 将整个文件中每行找到所有se替换为si
:s/se/si/g

# 如果想搜索和替换整个文件中的匹配内容，使用百分比字符%作为范围。此字符指示从文件第一行到最后一行的范围, g 表示某一行的全部
:%s/foo/bar/g
```

## vscode 设置 markdown 字体

快捷键Ctrl+Shift+P输入：Customize CSS

```css
.markdown-preview.markdown-preview {
  // modify your style here
  // eg: background-color: blue;
  
  font-size: 16px;
  font-family: '微软雅黑';
}
```