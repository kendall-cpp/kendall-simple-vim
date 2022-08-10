
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
- [vim 命令记录](#vim-命令记录)
- [nerdtree_red 使用](#nerdtree_red-使用)


------

设置 github host


参考这个：

https://vim80.readthedocs.io/zh/latest/plugin/vundle.html

YouCompleteMe 插件支持 C/C++ 代码补全

Plugin 'Valloric/YouCompleteMe'

参考：https://www.csdn.net/tags/NtjaggysOTI4Mi1ibG9n.html

需要安装 cmake

sudo apt install cmake

问题总结：https://www.freesion.com/article/6925855340/

解决 py 问题：https://blog.csdn.net/u014070086/article/details/88692896

插件推荐和使用：https://blog.csdn.net/sctu_vroy/article/details/71310522

进入网站 https://vimawesome.com/ 寻找合适的插件

github参考：https://github.com/chxuan/vimplus

括号补全插件

auto-pairs


Participate in the company's SW training courses

The company holds mid-career training for the graduates

-----




----

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

```
cd ~/.vim/bundles
git clone https://gitee.com/zhuixixi/YouCompleteMe.git --depth=1 
cd ~/.vim/bundles/YouCompleteMe
python3 install.py --clang-completer
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




-----

## vim 命令记录

- 搜索高亮
  - 高亮匹配结果中往下跳：n
  - 高亮匹配结果中往上跳：N
  - 关闭高亮：noh。

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

- 自动对齐：自动对齐：（gg=G）

- 块模式 ctrl+v
  - d 删除
  - I 进入编辑，编辑完按 ESC 退出

  ## nerdtree_red 使用

```sh
ctrl + w + h    光标 focus 左侧树形目录
ctrl + w + l    光标 focus 右侧文件显示窗口
ctrl + w + w    光标自动在左右侧窗口切换
ctrl + w + r    移动当前窗口的布局位置

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