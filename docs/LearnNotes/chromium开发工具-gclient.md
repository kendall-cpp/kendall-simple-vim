

----

## gclient简介

gclient是谷歌开发的一套跨平台git仓库管理工具，用来将多个git仓库组成一个 solution 进行管理。总体上，其核心功能是根据一个Solution 的 DEPS 文件所定义的规则将多个 git 仓库拉取到指定目录。例如，chromium 就是由 80 多个独立仓库组成。

- hooks: 当gclient拉完代码后执行的额外脚本；
- solution: 一个包含DEPS文件的仓库，可以认为是一个完整的项目；
- DEPS: 一个特殊的文件，规定了项目依赖关系；
- `.gclient`：一个特殊文件，规定了要拉取的solution，可由gclient config命令创建出来；
- include_rules：指定当前目录下哪些目录/文件可以被其他代码include包含，哪些不可以被include。

## 常用命令

### gclient config

该命令会生成 `.gclient` 文件，用于初始化要拉取的 solution ，其内容记录了 solution 仓库的地址以及要保存的位置。

```sh
# vim chromium/.gclient

solutions = [ 
  {
    'managed': False,		# # 使用 unmanaged 模式
    'name': 'src',  		# 拉取代码后存放的位置
    'url': 'https://chromium.googlesource.com/chromium/src.git',  # Solution仓库地址
    'deps_file': '.DEPS.git',   # 这是一个文件名（不包括路径），指在工程目录中包含依赖列表的文件，该项为可选，默认值为"DEPS"
  }, 
]
```

### gclient sync

该命令用于同步solution的各个仓库，它有一些参数：

- -f、--force: 强制更新未更改的模块；
- --with_branch_heads： 除了clone默认refspecs外，还会clone "branch_heads" refspecs;
- --with_tags: 除了默认的refspec之外，还可以clone git tags;
- --no-history： 不拉取git提交历史信息；
- `--revision <version>`: 将代码切换到 version 版本 ;
- --nohooks：拉取代码之后不执行hooks。

拉取代码主要是根据 DEPS 文件来进行，它里面的内容包括

- deps: 要获取的子依赖项:

```
   deps = {
       "src/outside" : "http://outside-server/trunk@1234",
   }
```

- vars：定义字符串变量，一般用于替代公共的字符串，然后通过Var来获取实际的值:

```
    vars = {
        'chromium_git': 'https://chromium.googlesource.com'
    }
    
    deps = {
        'src/chrome/browser/resources/media_router/extension/src':
    Var('chromium_git') + '/media_router.git' + '@' + '475baa8b2eb0a7a9dd1c96c9c7a6a8d9035cc8d7',
        'src/buildtools':
    Var('chromium_git') + '/chromium/buildtools.git' + '@' +  Var('buildtools_revision')
    }
```

- Hooks：DEPS包含可选的内容 hooks，也有重要的作用，它表示在sync, update或者recert后，执行一个hook操作,也即执行对应的脚本；

```
    hooks = [
      {
        #config git log format  
        'name': 'git-log',  
        'pattern': '.',  
        'action': [  
            'python',  
            'src/git-log/config_commit.py',  
        ],  
      },  
    ...  
    ]  
```

- deps_os：根据不同的平台定义不同的依赖工程

### 使用 gclient 的开发流程

```sh
# 首次拉代码：
mkdir chromium
cd chromium
gclient config git@gitlab.gz.cvte.cn:CrOS/src.git --unmanaged 
gclinet sync --reversion src@c/master --nohooks 
gclient runhooks
...... # 编译
......  # 修改代码
...... # 使用 git  进行代码提交

# 更新代码：
cd src
git pull 
gclient sync 
```


> 参考: https://www.cnblogs.com/xl2432/p/11596695.html