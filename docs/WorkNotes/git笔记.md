

- [git 三个分区](#git-三个分区)
	- [提交到暂存区](#提交到暂存区)
	- [提交到对象区](#提交到对象区)
		- [将当前更改追加到某个commit上](#将当前更改追加到某个commit上)
		- [删除 commit](#删除-commit)
	- [总结提交步骤](#总结提交步骤)
	- [后悔还原](#后悔还原)
		- [误删/改了某个文件还原](#误删改了某个文件还原)
	- [撤销已经push到远端的文件](#撤销已经push到远端的文件)
	- [checkout](#checkout)
	- [查看日志](#查看日志)
	- [重命名](#重命名)
	- [查重提交说明/修改注释](#查重提交说明修改注释)
		- [修改以前 commit 的注释](#修改以前-commit-的注释)
	- [branch 分支](#branch-分支)
	- [保存现场 stash](#保存现场-stash)
	- [在分支下修改文件](#在分支下修改文件)
	- [分支修改冲突](#分支修改冲突)
	- [版本回退--commit回退](#版本回退--commit回退)
- [tag标签](#tag标签)
- [diff 命令](#diff-命令)
- [邮箱设置](#邮箱设置)
- [push pull](#push-pull)
	- [和远程发生冲突](#和远程发生冲突)
	- [push 别人已经推送过的 commit](#push-别人已经推送过的-commit)
	- [解释 push HEAD](#解释-push-head)
- [git patch](#git-patch)
	- [git format-patch：生成commit的内容](#git-format-patch生成commit的内容)
	- [检查 patch](#检查-patch)
	- [git am 对应 git format-patch](#git-am-对应-git-format-patch)
	- [git apply 与 git am 的区别](#git-apply-与-git-am-的区别)
	- [打patch发生冲突](#打patch发生冲突)
		- [强制打上 patch](#强制打上-patch)
	- [patch 例子](#patch-例子)
- [cherry-pick](#cherry-pick)
- [查看某个文件的修改记录](#查看某个文件的修改记录)
- [repo 命令](#repo-命令)
- [设置 git commit 模式使用 vim](#设置-git-commit-模式使用-vim)

-----

## git 三个分区

- 工作区 modefied / unstaged
- 暂存区 staged
- 对象区 commited

### 提交到暂存区

git add hello.txt  			添加文件到暂存区


git ls-files    查看暂存区所有的文件

git rm --cached hello.txt   从暂存区退回到工作区  # 从暂存区删除该文件

	git reset HEAD hello.txt    从暂存区退回到工作区 和上面一样

	git restore --staged fileName


git status        			查看目前工作区状态


### 提交到对象区

git commit  或者 git commit -a   #省略add步骤

填写信息，

如果暂存区已经全部 commit 了，执行的时候就会出现

```
nothing to commit, working tree clean
```

git rm hello.txt  从对象区中删除一个数据（会删除本地文件），会回到暂存区，可以用 git reset HEAD file-name 退回到 工作区，但是也可以再执行 git commit hello.txt 彻底删除

> 所以彻底删除：git rm file_name ; git commit file_name

git commit -a -s --no-verify   忽略掉代码不规范错误 -s 加签名 -a 是上了 add 步骤

#### 将当前更改追加到某个commit上

https://www.cnblogs.com/everest33Tong/p/6418494.html


#### 删除 commit 
 
git reset --soft HEAD^		 撤销commit 保留 add

git reset HEAD~数字		按照输入的数字撤销输入数字条commit记录

git commit -m update        将上面删除操作提交到git仓库


### 总结提交步骤

```sh
git add

git commit 
# 填写注释

git commit --amend -s --no-verify     
	--amend  修改上一次的注释 
	--no-verify 忽略代码检查，
	-s 是添加签名

# 如果没有 changeID 需要拷贝 .git/hooks$ cp [other_path]]/.git/hooks/commit-msg  .
# 然后再执行 git commit --amend 就有 Change-Id 了


git push 链接别名 分支名
```


### 后悔还原

> 所有文件都在已经提交到对象区，可以通过 git status 查看：nothing to commit, working tree clean

git add aaa.txt bbb.txt    提交到暂存区

git commit -m "提交aaa.txt bbb.txt到对象区"

git status          --> nothing to commit, working tree clean

===> 删除对象区中已经提交的文件

git rm bbb.txt    从对象区删除，同时会删除本地工作区 bbb.txt 源文件（这时候的操作命令【也可以理解bbb.txt文件】在 暂存区 中）

git commit        提交删除操作，会彻底删除

===> 后悔还原

git reset HEAD bbb.txt  退回到工作区（但是还是删除指令）

git checkout -- hello.txt  还原回工作区

#### 误删/改了某个文件还原

git restore <file>

### 撤销已经push到远端的文件

```c
// 切换到指定分支
git checkout 分支名
// 撤回到需要的版本
git reset --soft 需要回退到的版本号
//提交撤销动作到服务器，强制提交当前版本号
git push origin 分支名 --force
//撤销后强制提交到当前分支的版本号状态，这里使用要谨慎，
```


- soft 和 hard的区别

  - soft：保留本地当前工作区，用于重新提交（回退到指定版本号，回退的版本号代码会保留到本地工作区，本地工作区代码还是保留最后提交的状态）
  - hard：不保留本地当前工作区，回退到指定版本号之后，同时本地工作区代码也回退，一定要谨慎使用


### checkout

commit 之后再修改文件

git status  查看可以看到 `(use "git checkout -- <file>..." to discard changes in working directory)`

意思就是放弃修改，将代码从 对象区 又拷贝回来 工作区

git checkout -- hello.txt  	注意：放弃的是工作区中的修改

> 注意 checkout 不加 '--' git checkout new_branch  是创建新分支


### 查看日志

git log 可以查看每次提交

git log -2 查看最近 2 次提交

git log --pretty=oneline --3   显示在一行查看

### 重命名

> 重命名的本质就是移动，也就是删除原来位置的拷贝到新位置

git mv aaa.txt

撤销重命名--类似删除撤销

git reset HEAD aaa.txt

git checkout -- aaa.txt

> 这时候生成两个文件

### 查重提交说明/修改注释

git commit --amend -m "修正最近一次 commit 的提交信息"

git commit --amend -s    `-->` 修正最后一次 commit 提交的注释

#### 修改以前 commit 的注释

例，修改倒数第三个

git rebase -i HEAD~3  倒数第3个（以1开始）

把 pick 改为 edit

接着执行以下命令修改注释： 

git commit --amend   # 修改上一次注释

git push 

最后执行，复原现在的点

git rebase --continue

### branch 分支

git branch     查看分支

git branch new_branche   创建新的分支

git checkout new_branch   切换分支

> 当一个工作未 commit 完成不能切换分支

git checkout quartz-master --force  强制切换

git checkout -b new_branch   创建并切换分支

git branch -d new_branch   删除分支，但是不能删除自己，得切换到其他分支，而且**当前分支如果有文件也不能删除**，建议想先合并

git branch -D new_branch    没有 merge 删除

```sh
git checkout -b <branch> origin/<branch>   # 先在本地建立一个分支，并切换到该分支，然后从远程分支上同步代码到该分支上，并建立关联
git checkout -t origin/<branch>		# 这个的作用和上面的一样
```


### 保存现场 stash

如果某个功能还没开发完毕，就要切换分支，建议保存现场（临时保存，stash），再切换

> 备份当前的工作区的内容,将当前的工作区内容保存到Git栈中

git stash    保存现场，还原到上一个时刻

git stash save "mystash"  保存现场，并命名为 mystash，同时还原到上一个时刻

git stash list   查看所有保存的现场

git stash pop    后面不跟stash id, 还原到上一个现场，同时删除上一个现场

git stash apply  stash@{0}  还原现场，但不删除现场内容

git stash pop stash@{0}    指定恢复到某一次现场，同时删除 stash@{0} 

git stash drop stash@{0}   手动删除某个现场

> 如果不小心删除了 stash,删除的时候会有一个 ID
> Dropped stash@{0} (e2b6a6a3d905861b5ae6e08f2dafdf2b7a259571)
> 也可以使用 git stash apply e2b6a6a3d905861b5ae6e08f2dafdf2b7a259571(删除的时候会有) 来恢复删除的 stash


### 在分支下修改文件

git rm abc.txt

git commit -m "delete"

git checkout main  切换分支

> 这时候发现 abx.txt 又在了，切换会 new_branch 又没了

这时候删除 new_branch 分支会 error

想要多个分支都删出，需要合并“写”操作

git checkout main   切换分支

git merge new_branch   合并分支

> 这时候 main 下 abc.txt 也没了

git branch -d new_branch  可以删除分支

> 注意：**建议删除分支之前建议先合并**

git branch -D new_branch   强制删除，不提示合并

> 如果在分区 a 中进行了写操作，比如 vi file,但是没有执行 add commit（两个命令都要执行完） ，在同一个文件夹下的其他分支也是可以看到的，但是如果执行了 add commit ，其他分支就看不到了本地的文件了

git branch -v  查看每个分支最近一次提交的 sta1 值

git branch -m main main2   分支重命名

git branch -a       查看本地所有分支，红色表示远程分支（只读）

### 分支修改冲突

就是两个分支都对文件进行修改并且 add commit 了

> 现在能不能合并？？ 不能

- 需要 vi 文件解决冲突

- git add --> git commit 

	- 这里两次 commit，一次是修改的时候会触发，一次是 commit 的时候会触发

这时候就可以合并了

git merge bash

### 版本回退--commit回退 

git commit -am  "合并 add 和 commit" （工程的第一次提交不能用）

git commit --amend "aaaa22222"   修改上次注释加 --amend

git reset --hard HEAD^^  回退2个版本，一个 ^ 表示回退一个

git reset --hard HEAD~n  回退前n个版本


git reset --hard  536ab2	回到某一次， 通过 sha1 值前几个字符就可以

git reflog       查看所有记录

git reset --hard 709a929   通过 git reflog 得到被删除的 commit 的 sha1 值并回退


## tag标签

标签是针对这个项目的，而不是针对某个分支

git tag v1.0  打标签

git tag      查看标签（版本）

git tag -a tag_name -m "注释“  

git tag -d v1.0  	删除标签

git tag -l "v*“       模糊查询

git blame aaa.txt		追求某个文件是谁写的谁创建的


## diff 命令

比较 对象区 和 工作区 的差异，相对于对象区比较

git diff   查看文件差异

## 邮箱设置

 git config -l 插看使用

 git config --global  (整个计算机设置)

 git config --system (给当前用户设置)

 git config --loacl (给当前项目一次性设置)

```sh
git config --local user.name ""
git config --local user.email ""

git config --global user.name "shengken.lin"
git config --global user.email "shengken.lin@amlogic.com"

git config --global user.name "Shengken Lin"
git config --global user.email "shengken.lin@amlogic.corp-partner.google.com"

# 修改当前repo的用户名和邮箱
git config user.name "shengken.lin"
git config user.email "shengken.lin@amlogic.com"
```

> 如果是当前用户 --system 设置，存在 ~/.gitconfig 文件下

git config --local --unset user.name   删除

git config --local --unset user.email  删除 

## push pull

- git remote add origin github_url  将本地和远程关联

- git push -u origin master     第一次要指定分支
  - git push 				后续不需要加 -u
  - git push origin master  查看远程状态

- git pull -u pull       

- git remote show     查看远程项目链接的名字，origin

- git remote show origin   查看origin的详细信息

### 和远程发生冲突

- 需要 git add 和 commit 再进行 pull

- git pull 

- vim 修改文件

- git add  文件名

- git commit -m "解决冲突"

- git push

- 再重新拉下来 git pull

> **解决完冲突提交且 push 之后，另一个用户需要 pull **


- git merge		 合并分支


> pull = fecth + merge   (marge:  origin/master 和 master 合并)

- git fetch   拉去到本地，origin/master 分支，还未合并

### push 别人已经推送过的 commit 

- 会报错

```sh
fatal: Unpack error, check server log
error: remote unpack failed: error Missing tree f5a548203954ecfbe7ebeaa435b7bf48b71cf225
To ssh://scgit.amlogic.com:29418/kernel/common.git
 ! [remote rejected]             HEAD -> refs/for/amlogic-5.4-dev (n/a (unpacker error))
error: failed to push some refs to 'ssh://shengken.lin@scgit.amlogic.com:29418/kernel/common.git'
```

- 解决

```sh
git push --no-thin  review HEAD:refs/for/amlogic-5.4-dev
```

- 出现原因： 推送到远程的文件被本地git优化后，发送数据不一致。

### 解释 push HEAD

git push origin HEAD:refs/for/master

- HEAD: 是一个特别的指针，它是一个指向你正在工作的本地分支的指针，
  - 可以把它当做本地分支的别名，git 这样就可以知道你工作在哪个分支
- refs/for :意义在于我们提交代码到服务器之后是需要经过 code review 之后才能进行merge的
- refs/heads： 不需要 review 直接 merge (**谨慎操作**)

---

## git patch

### git format-patch：生成commit的内容

```
生成最近1次的commit的patch
git format-patch HEAD^

生成最近2次的commit的patch
git format-patch HEAD^^

生成最近3次的commit的patch
git format-patch HEAD^^^

生成最近4次commit的patch
git format-patch HEAD^^^^

将两个commit以及中间的所有commit生成patch
git format-patch <commit1_hash>..<commit2_hash>

生成单个commit的patch
git format-patch -1 <commit_hash>

某次提交以后的所有patch，不包括 commit_hash 这个
git format-patch <commit_hash>

将所有patch输出到一个指定位置的指定文件，git am 的时候会看到所有的 commit
git format-patch -1 <commit_hash> --stdout > xxx.patch
```

### 检查 patch

```
查看patch的情况
git apply --stat xx.patch

检查patch与当前分支合并时，是否有冲突
git apply --check xx.patch
```


### git am 对应 git format-patch

```
合并新来的commit patch
git am *.patch
git apply  *.patch
  ## 或者：patch -p1 < 0001-a5-av400-enable-nand.patch   打 patch

合并时，签上打patch人的名字
git am --signoff *.patch

放弃本次打的patch
git am --abort

当 git am 失败，解决完冲突后，接着执行未完成的 patch
git am --resolved
```

### git apply 与 git am 的区别

- git apply 只更新改动内容，打完之后需要自己 git add 和  git commit

**少用 git am**

- git am 是更新的 commit，会将 commit 的所有信息打上去，author 也是 patch 的 author 而不是打 patch的人。

### 打patch发生冲突

- 根据 git am 失败的信息，找到发生冲突的具体 patch 文件

- 然后 git apply --reject xxxx.patch ，发生冲突的部分会保存为 patch_name.rej 文件；

- 根据 patch_name.rej 文件，修改该 patch 文件来解决冲突；

- 然后删除这些 *.rej 文件。完成这一步骤的操作后，我们就可以继续执行 git am 的过程了。
  - git clean -f xxx.rej

- 执行命令 git status 查看当前改动过的以及新增的文件，确保没有多添加或少添加文件。

- 执行命令 git add . 将所有改动都添加到暂存区（注意，关键字add后有一个小数点 . 作为参数，表示当前路径）。

- 执行命令 git am --resolved 继续 步骤1 中被中断的 patch 合入操作。合入完成后，会有提示信息输出。

- 执行命令 git log 确认合入状态。


在遇到打了一次补丁之后继续运行patch命令时，patch会提示 `Reversed (or previously applied) patch detected! Assume -R? [n]`。对此：

-t：该参数遇到这种情况直接将打过补丁的文件恢复原样，即未打补丁之前的状态
-f：该参数遇到这种情况则继续打补丁，当然一般情况下会报错，毕竟对比不一致了
-N：忽略该文件

#### 强制打上 patch

- (1) 根据git am失败的信息，找到发生冲突的具体patch文件，然后用命令`git apply --reject <patch_name>`，强行打这个patch，发生冲突的部分会保存为.rej文件（例如发生冲突的文件是a.txt，那么运行完这个命令后，发生conflict的部分会保存为a.txt.rej），未发生冲突的部分会成功打上patch
- (2) 根据.rej文件，通过编辑该patch文件的方式解决冲突
- (3) 废弃上一条am命令已经打了的patch：git am --abort
- (4) 重新打patch：git am ~/patch-set/*.patchpatch

### patch 例子

```sh
修改最新文件并 commit

然后打 patch

git format-patch -1 <commit_hash>

## 注意 patch 不能保存在当前目录下，否则 reset 会被删掉

然后 reset 到某个版本


git reset --hard 761ac81568

如果需要退回某个 patch 的地方

git am --abort

git am *.patch
```

> 学习参考：https://www.cnblogs.com/lueguo/p/3544114.html

将所有patch输出到一个指定位置的指定文件 git format-patch commit_hash --stdout > xxx.patch

使用 git am xxx.patch  可以把所有的 commit 保存成一个 patch， 打 patch 的时候会显示所有的 commit

## cherry-pick

> 参考：https://blog.csdn.net/GBS20200720/article/details/123840359


作用 ： 指定的 commit，拉到一个新的分支上。

```
git cherry-pick <commitHash>

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/27/245927/1 && git cherry-pick FETCH_HEAD -x
```

- 如果遇到冲突，解决冲突，然后 git commit -s 

```c
git cherry-pick --continue  // 1. 解决完冲突以后，继续下一个 cherry-pick
git cherry-pick --abort   // 2. 如果不想解决冲突，要放弃合并，用此命令回到操作以前
git cherry-pick --quit   // 3. 不想解决冲突，放弃合并，且保持现有情况，不回到操作以前
```

## 查看某个文件的修改记录

git log --pretty --oneline xarch/arm64/boot/dts/amlogic/a4_a113l2_ba400.dtsxxx

---

## repo 命令

```sh
# 将HEAD强制指向manifest的库，而忽略本地的改动。
repo sync -d

# Remove all working directory (and staged) changes. 删除所有工作目录（和暂存）更改
repo forall -c 'git reset --hard'   

# Clean untracked files 清楚所有缓冲中间文件
repo forall -c 'git clean -f -d' 

# 上面三条会后，本地代码和远程服务器的代码就完全一致了

# 拉代码
repo sync -c

# repo撤销本地代码修改：
repo forall -c “git clean -df” && repo forall -c “git checkout .”
```

## 设置 git commit 模式使用 vim

git config --global core.editor "vim"