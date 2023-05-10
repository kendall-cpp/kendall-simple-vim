# release build

```sh
source ./build-chrome.sh
lunch longan-eng
PARTNER_BUILD=true BOARD_NAME=longan-b1 make -j30 otapackage
```

- 编译出错

这是由于 ninja 找不到导致

```
FileNotFoundError: [Errno 2] No such file or directory: '/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/chromium/src/out_chromecast_longan/release/../../third_party/ninja/ninja
```

- 问题解决

```sh
vim chromium/src/chromecast/internal/build/guarded_ninja.py +64

# 这里有设置 ninja 的路径
ninja_path = os.path.join(ninja_dir, '../../third_party/ninja/ninja')
# 之前的 chromium 版本 ninja 确实在 ./chromium/src/third_party/ninja/ninja  ， 但是 gclient sync 之后这里面的被删除的。
# 修改
ninja_path = os.path.join(ninja_dir, '../../third_party/ninja/ninja')
```