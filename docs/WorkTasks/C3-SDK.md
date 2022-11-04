# repo sync

```sh
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m br-ipc-c3.xml --repo-url=git://git.myamlogic.com/tools/repo.git

# 修改 git user email
# vim buildRoot_C3/.repo/repo/.git/config
[user]   
        name = shengken.lin
        email = shengken.lin@amlogic.com 
repo sync -c
```

# 编译

```sh
source setenv.sh 
# 选择AW401
make
```

