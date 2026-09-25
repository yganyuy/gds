#!/usr/bin/env python
import os
import sys

# 1. 定义一个“隐藏”目录，用来放所有 .obj 文件
#    这个 .obj_fw 文件夹不会被 Godot 扫描（因为以 . 开头），而且我们已经排除了 src。
obj_dir = "src/.obj_fw"

# 2. 告诉 SCons：所有源文件在 src/，但编译产生的 .obj 文件要放到 obj_dir 里
#    注意：这里我们显式指定了源文件路径和对象文件路径的对应关系
VariantDir(obj_dir, 'src', duplicate=0)

# 3. 加载 godot-cpp 的编译环境
env = SConscript("godot-cpp/SConstruct")

# 4. 告诉编译器去哪里找头文件（.h）
#    头文件还是放在 src/ 里，不需要变
env.Append(CPPPATH=["src/"])

# 5. 收集所有需要编译的 .cpp 文件
#    注意：这里用 obj_dir 路径，SCons 会智能地映射到 src/
sources = env.Glob(f"{obj_dir}/*.cpp")

# 6. 给生成的 .dll 起名字（不用改）
lib_filename = "{}gdexample{}{}".format(env.subst('$SHLIBPREFIX'), env["suffix"], env.subst('$SHLIBSUFFIX'))

# 7. 编译成 .dll，输出到 addons/bin/
library = env.SharedLibrary(
    "addons/bin/{}".format(lib_filename),
    source=sources,
)

# 8. 默认目标就是生成这个 .dll
Default(library)