# Android.mk文件的作用

Android.mk是Android工程管理文件，类似于编译文件的说明书，用来向编译系统描述源代码，并将源文件分组为模块（包括静态库、共享库、独立可执行文件）。Android.mk会被编译系统解析一次或多次，可以在每一个Android.mk文件中定义一个或多个模块，也可以多个模块使用同一个 .mk 文件。

## Android.mk语法详解

LOCAL_PATH := $(call my-dir) 

每个Android.mk文件必须以定义LOCAL_PATH为开始。它用于在开发tree中查找源文件。宏 my-dir 则由 Build System 提供。返回包含 Android.mk 的目录路径。

include $(CLEAR_VARS) 

CLEAR_VARS 变量由 Build System 提供。并指向一个指定的 GNU Makefile，由它负责清理很多LOCAL_xxx.

例如：LOCAL_MODULE, LOCAL_SRC_FILES, LOCAL_STATIC_LIBRARIES等等。但不清理LOCAL_PATH.

这个清理动作是必须的，因为所有的编译控制文件由同一个GNU Make解析和执行，其变量是全局的。所以清理后才能避免相互影响。