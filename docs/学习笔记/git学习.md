



-----

## git 三个分区

- 工作区 modefied / unstaged
- 暂存区 staged
- 对象区 commited

### 提交到暂存区

git add hello.txt  			添加文件到暂存区

git rm --cached hello.txt   从暂存区退回到工作区

git reset HEAD hello.txt    从暂存区退回到工作区 和上面一样

git status        			查看目前工作区状态


### 提交到对象区

git commit 

填写信息，shift+zz 可以保存退出

如果暂存区已经全部 commit 了，执行的时候就会出现

```
nothing to commit, working tree clean
```

git rm hello.txt  从对象区中删除一个数据（会删除本地文件），会回到暂存区，可以用 git reset head 退回到 工作区，但是也可以再执行 git commit hello.txt 彻底删除

> 所以彻底阐述：git rm file_name ; git commit file_name


### 后悔还原

> 所有文件都在已经提交到对象区，可以通过git status 查看：nothing to commit, working tree clean

git add aaa.txt bbb.txt    提交到暂存区

git commit -m "提交aaa.txt bbb.txt到对象区"

git status          --> nothing to commit, working tree clean

===> 删除对象区中已经提交的文件

git rm bbb.txt    从对象区删除，同时会删除本地工作区 bbb.txt 源文件（这时候的操作命令[也可以理解bbb.txt文件]在 暂存区 中）

git commit        提交删除操作，会彻底删除

===> 后悔还原

git reset HEAD bbb.txt  退回到工作区（但是还是删除指令）

git checkout -- hello.txt  还原回工作区

### checkout

commit 之后再修改文件

git atatus  查看可以看到 `(use "git checkout -- <file>..." to discard changes in working directory)`

意思就是放弃修改，将代码从 对象区 又拷贝回来 工作区

git checkout -- hello.txt

> 注意 checkout 不佳斜杠 git checkout new_branch   切换分支


### 查看日志

git log 可以查看每次提交

git log -2 查看最近 2 次提交

git log --pretty=oneline --3   显示在一行查看

### 重命名

> 重命名的本质就是移动，也就是删除原来文字的拷贝到新位置

git mv aaa.txt

撤销重命名--类似删除撤销

git reset HEAD aaa.txt

git checkout -- aaa.txt

> 这时候生成两个文件

### 查重提交说明

git commit --amend -m "修正最近一次的提交信息"

### branch 分支

git branch     查看分支

git branch new_branche   创建新的分支

git checkout new_branch   切换分支

git checkout -b new_branch   创建并切换分支

git checkout -d new_branch   删除分支，但是不能删除自己，得切换到其他分支，		
	而且**当前分支如果有文件也不能删除**，建议想先合并

#### 在分支下修改文件

git rm abc.txt

git commit -m "delete"

git checkout main  切换分支

> 这时候发现 abx.txt 又在了，切换会 new_branch 又没了

这时候删除 new_branch 分支会 error

想要多个分支都删出，需要合并“写”操作

git checkout main

git merge new_branch   合并分支

> 这时候 main 下 abc.txt 也没了

git branch -d new_branch  可以删除分支

> 注意：**建议删除分支之前建议先合并**

git branch -D new_branch   强制删除，不提示合并

> 如果在分区 a 中进行了写操作，比如 vi file,但是没有执行 add commit（两个命令都要执行完） ，在同一个文件夹下的其他分支也是可以看到的，但是如果执行了 add commit ，其他分支就看不到了本地的文件了

git branch -v  查看每个分支最近一次提交的 sta1 值

### 分支修改冲突

就是两个分支都对文件进行修改并且 add commit 了

> 现在能不能合并？？ 不能

- 需要 vi 文件解决冲突

- git add --> git commit 

	- 这里两次 commit，一次是修改的时候会触发，一次是 commit 的时候会触发

这时候就可以合并了

git merge bash

## 邮箱设置

 git config  常看使用

 git config --global  (整个计算机设置)

 git config --system (给当前用户设置)

 git config --loacl (给当前项目一次性设置)

```
git config --local user.name "kendall-cpp"
git config --local user.email "lsken00@foxmail.com"
```

> 如果是当前用户 --system 设置，存在 ~/.gitconfig 文件下

git config --local --unset user.name   删除

git config --local --unset user.email  删除 



