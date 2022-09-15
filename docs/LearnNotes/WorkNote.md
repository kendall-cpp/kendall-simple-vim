
软件：
VScode
Typora
snipaste


## 网址：
- 邮箱：https://mail-sz.amlogic.com/owa/#path=/mail
- Wiki:https://wiki-china.amlogic.com/
- 新员工：https://confluence.amlogic.com/pages/viewpage.action?pageId=130033242
- 晶晨家园：https://jira.amlogic.com/secure/Dashboard.jspa
- AAA-For New coming members：https://confluence.amlogic.com/display/SW/AAA-For+New+coming+members
- https://jira.amlogic.com/secure/Dashboard.jspa
- 代理地址：http://proxy-cn.amlogic.com:8000/download/tools/amlogic.list.sz

## 信息

- 工号：SZ1056
- 职位：SW Engineer
- 部门：ENG SW(410)
- 邮箱地址	shengken.lin@amlogic.com	
- 谷歌邮箱：shengken.lin@amlogic.corp-partner.google.com
- 密码：pHFP-eotQ-TtmZ Kendall@000



## 服务器信息

- Your linux account:	shengken.lin
- Your linux password:	pF%B8f4r
- Server hostname :	walle01-sz  
- Work directory: /mnt/fileroot/shengken.lin
- Your directory size:	2T

== YOUR SAMBA PATH AND ACCOUNT INFORMATION ==
---------------------------------------------------
- windows mount path : \\walle01-sz\fileroot\shengken.lin
- login name:	walle01-sz\shengken.lin
- Login password:	pF%B8f4r  (command smbpasswd change samba - password)
- (note: if your samba password doesn't work, please find cary.wu@amlogic.com or local IT guys)




--------------
https://wiki-china.amlogic.com/ 
- 汇总：https://confluence.amlogic.com/pages/viewpage.action?spaceKey=SW&title=AAA-For+New+coming+members
- 文档：
	- https://employees.myamlogic.com/Engineering/VLSI%20Documents/Forms/AllItems.aspx?RootFolder=%2FEngineering%2FVLSI%20Documents%2FVLSI%2FMeson%2FA1%2Fapp%2Fregister&FolderCTID=0x012000EB99DE675E1E9148A1C3238131CCDCDD&View=%7B773C7B32%2D679B%2D4F51%2DB993%2D9556C56C21C7%7D
	- https://doc.amlogic.com/index/index
	- https://jira.amlogic.com/secure/Dashboard.jspa?selectPageId=15131
	
### 烧录文档学习

- https://confluence.amlogic.com/display/SW/BuildRoot+A1+Environment+Setup
	
	
  git config --global user.email "shengken.lin@amlogic.com"
  
  git config --global user.name "shengken.lin"


  ### Git 命令

```
git config --global user.name "Yuegui He"
git config --global user.email yuegui.he@amlogic.corp-partner.google.com



git config user.name "Yuegui He"
git config user.email yuegui.he@amlogic.com
```

### 谷歌项目账号

Email		shengken.lin@amlogic.corp-partner.google.com

Password		pHFP-eotQ-TtmZ
  
  

### 烧录过程命令

```
  E:\amlogic_tools\aml_dnl-win32\adnl.exe  Download u-boot.bin 0x10000
E:\amlogic_tools\aml_dnl-win32\adnl.exe run
E:\amlogic_tools\aml_dnl-win32\adnl.exe bl2_boot -F  u-boot.bin

E:\amlogic_tools\aml_dnl-win32\adnl.exe oem "store init 1"
```


## 任务记录

- 第二周，熟悉aml的软件开发流程， 用 buildroot 做为开始的基础
	- sync code & 编译&烧录&启动， 提供几个问题。
		- --> 熟悉 bootloaer下cmd添加，启动
		- --> 熟悉 kernel 下启动，dts 修改
		- --> 熟悉文件系统，nand， ubi mount， nand 块计算等
		- --> 记录启动时间。
		- --> 并做提交到 gerrit。

- 第三周，转入到google项目		
  - 转到google korlan项目熟悉


- 1 sync google code,
代理设置： https://confluence.amlogic.com/pages/viewpage.action?spaceKey=SW&title=0.+Get+the+google+source+code+access+-+Updated+2022
sync code: refer to Gproject Development Guideline_update_bill.docx Korlan part.

- 2 T404 熟悉
   - 熟悉 kernel 下启动，dts 修改
     - task1: 修改 boot 分区表，烧录并能正常启动
	 - task2: 打印系统启动的时间
	 - task3: 更改 system 的 pagesize 和 block count, 看看系统是否能正常挂载
	 - task4: 将这些修改加上 [Don't merge] 提交到 gerrit  ---> 到时候提交 ping 我