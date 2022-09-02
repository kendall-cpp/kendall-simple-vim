

参考：https://confluence.amlogic.com/pages/viewpage.action?spaceKey=SW&title=0.+Get+the+google+source+code+access+-+Updated+2022#id-0.GetthegooglesourcecodeaccessUpdated2022-1.Setproxy

## 服务设置代理

```
$ cd ~
$ vim .boto
# 公司的
proxy = 10.78.20.250
proxy_type = http
proxy_port = 3128
# proxy_user = shengken.lin
# proxy_pass = New@345
proxy_rdns = True
```

修改代理：

```
/mnt/fileroot/shengken.lin/workspace/google_source/depot-tools-env.sh
```

## 同步代码

```
git config --global http.proxy http://10.78.20.250:3128
git config --global https.proxy https://10.78.20.250:3128
export http_proxy="10.78.20.250:3128"
export https_proxy="10.78.20.250:3128"
echo "proxy=10.78.20.250:3128" > ~/.curlrc
```

Open `https://eureka-partner.googlesource.com/`, click “Generate Password”

之后得到

```sh
git config --global http.cookiefile "%USERPROFILE%\.gitcookies"
powershell -noprofile -nologo -command Write-Output "eureka-partner.googlesource.com`tFALSE`t/`tTRUE`t2147483647`to`tgit-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA`neureka-partner-review.googlesource.com`tFALSE`t/`tTRUE`t2147483647`to`tgit-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA" >>"%USERPROFILE%\.gitcookies"
```

和（只需要执行这些命令）

```sh
eval 'set +o history' 2>/dev/null || setopt HIST_IGNORE_SPACE 2>/dev/null
 touch ~/.gitcookies
 chmod 0600 ~/.gitcookies

 git config --global http.cookiefile ~/.gitcookies

 tr , \\t <<\__END__ >>~/.gitcookies
eureka-partner.googlesource.com,FALSE,/,TRUE,2147483647,o,git-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA
eureka-partner-review.googlesource.com,FALSE,/,TRUE,2147483647,o,git-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA
__END__
eval 'set -o history' 2>/dev/null || unsetopt HIST_IGNORE_SPACE 2>/dev/null
```

### gclient

```sh
shengken.lin@walle01-sz:~$ git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git 

shengken.lin@walle01-sz:/mnt/fileroot/shengken.lin/workspace/google_source$ source depot-tools-env.sh

shengken.lin@walle01-sz:/mnt/fileroot/shengken.lin/workspace/google_source$ gsutil.py config
```


访问链接获取谷歌授权码：`4/1AX4XfWgYu8DEu9kkZ6cc7dAxWHblWkfabtChfB3M5vD_jmGreNoNKoWJWMc`

```
Enter the authorization code: <access the link to get it>
 
proxy host -> 10.78.20.250
proxy type -> http
proxy port -> 3128
proxy user -> (skip it)
proxy pass -> (skip it)
DNS lookup -> y
 
Enter the authorization code: <access the link to get it>
 
What is your project-id?  google.com:eureka-builds
```

### Download source code

```
shengken.lin@walle01-sz:/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools$ cat http_proxy.boto 
proxy = 10.78.20.250
proxy_type = http
proxy_port = 3128

proxy_rdns = True
```

### 代理

```
10.28.39.73  10809
```

将代理添加到环境变量

```sh
~/.bash_profile

export PATH=$PATH:/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools/
export NO_AUTH_BOTO_CONFIG=/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools/http_proxy.boto
export BOTO_CONFIG=/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools/http_proxy.boto
```

### repo 代码

```sh
## 也可以不设置成全局
$ git config --global user.name "Shengken Lin"
$ git config --global user.email shengken.lin@amlogic.corp-partner.google.com


$ repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -m default.xml 

# 显示这样，说明成功
Your identity is: Shengken Lin <shengken.lin@amlogic.corp-partner.google.com>
If you want to change this, please re-run 'repo init' with --config-name

repo has been initialized in /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/
If this is not the directory in which you want to initialize repo, please run:
   rm -r /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome//.repo
and try again.

$ repo sync

$ cd chromium

export PATH=/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools/:$PATH

$ gclient setdep --deps-file=src/DEPS --var=fuchsia_sdk_bucket=fuchsia && gclient sync

$ cd ../../

$ mkdir amlogic_sdk

$ /mnt/fileroot/shengken.lin/workspace/google_source/eureka$ vim ../depot-tools-env.sh 

$ /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk$ repo sync -j12
# -j12 开启12个线程
```

### 工作目录

> shengken.lin@walle01-sz:/mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk


## 拉取chrome（第二次）

mkdir chrome_code


进入 `https://eureka-partner.googlesource.com/`, click “Generate Password”

之后得到

```sh
git config --global http.cookiefile "%USERPROFILE%\.gitcookies"
powershell -noprofile -nologo -command Write-Output "eureka-partner.googlesource.com`tFALSE`t/`tTRUE`t2147483647`to`tgit-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA`neureka-partner-review.googlesource.com`tFALSE`t/`tTRUE`t2147483647`to`tgit-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA" >>"%USERPROFILE%\.gitcookies"
```

和（只需要执行这些命令）

```sh
eval 'set +o history' 2>/dev/null || setopt HIST_IGNORE_SPACE 2>/dev/null
 touch ~/.gitcookies
 chmod 0600 ~/.gitcookies

 git config --global http.cookiefile ~/.gitcookies

 tr , \\t <<\__END__ >>~/.gitcookies
eureka-partner.googlesource.com,FALSE,/,TRUE,2147483647,o,git-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA
eureka-partner-review.googlesource.com,FALSE,/,TRUE,2147483647,o,git-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA
__END__
eval 'set -o history' 2>/dev/null || unsetopt HIST_IGNORE_SPACE 2>/dev/null
```


---

- 拉取脚本

> 参考： https://confluence.amlogic.com/pages/viewpage.action?spaceKey=SW&title=0.+Get+the+google+source+code+access+-+Updated+2022



- git 设置代理


**直接使用以下命令**

```sh
git config --global user.email shengken.lin@amlogic.corp-partner.google.com

git config --global user.name "shengken lin"

git config --global http.proxy http://10.78.20.250:3128
git config --global https.proxy https://10.78.20.250:3128

```


Open `https://eureka-partner.googlesource.com/`, click “Generate Password”

之后得到

```sh
git config --global http.cookiefile "%USERPROFILE%\.gitcookies"
powershell -noprofile -nologo -command Write-Output "eureka-partner.googlesource.com`tFALSE`t/`tTRUE`t2147483647`to`tgit-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA`neureka-partner-review.googlesource.com`tFALSE`t/`tTRUE`t2147483647`to`tgit-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA" >>"%USERPROFILE%\.gitcookies"
```

和（只需要执行这些命令）

```sh
eval 'set +o history' 2>/dev/null || setopt HIST_IGNORE_SPACE 2>/dev/null
 touch ~/.gitcookies
 chmod 0600 ~/.gitcookies

 git config --global http.cookiefile ~/.gitcookies

 tr , \\t <<\__END__ >>~/.gitcookies
eureka-partner.googlesource.com,FALSE,/,TRUE,2147483647,o,git-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA
eureka-partner-review.googlesource.com,FALSE,/,TRUE,2147483647,o,git-shengken.lin.amlogic.corp-partner.google.com=1//0gziUl_3uYGEZCgYIARAAGBASNwF-L9IrDlejBhyRbMr3uNC-0N1BIiJ3pv9MjP8A-H8fF-AO2C-cxgOSJsXbMEfWP5dSnuqGonA
__END__
eval 'set -o history' 2>/dev/null || unsetopt HIST_IGNORE_SPACE 2>/dev/null
```

- Download gclient

到你的目录

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git



- 1.设置环境变量

```sh
# vim ~/.bash_profile 
#google  
ip_set=10.78.20.250:3128
export http_proxy=$ip_set
export https_proxy=$ip_set                  
export depot_path="/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools"
export BOTO_CONFIG=${depot_path}/.boto    
export NO_AUTH_BOTO_CONFIG=${depot_path}/.boto
export PATH=${depot_tools}:$PATH
export DEPOT_TOOLS_UPDATE=1 
```

- 2. gsutil.py config

```sh 
gsutil.py config

# 输出中有个链接：https://accounts.google.com/o/oauth2/auth?client_id=909320924072.apps.googleusercontent.com&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faccounts.reauth&access_type=offline&response_type=code

# 点击进去允许获取授权码 4/1AdQt8qgy0KTm8R157h_JJcv6ut_Qm7h8AuYdbZ8HCe3EweA79YzAUVvsBw8  每次不一样
 
# 3. fill some info message.
Enter the authorization code: <access the link to get it>
 
proxy host -> 10.78.20.250
proxy type -> http
proxy port -> 3128
proxy user -> (skip it)
proxy pass -> (skip it)
DNS lookup -> y
 
Enter the authorization code: <access the link to get it>
 
What is your project-id?  google.com:eureka-builds
```

- 拉取代码

```sh
google_source/chrome_code$ repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -m default.xml

# 结果：Your identity is: shengken lin <shengken.lin@amlogic.corp-partner.google.com>

repo sync
cd ./chromium
# export PATH=/mnt/fileroot/shengken.lin/workspace/google_source/depot_tools/:$PATH
gclient setdep --deps-file=src/DEPS --var=fuchsia_sdk_bucket=fuchsia
gclient sync
```






