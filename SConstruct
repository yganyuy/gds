#!/usr/bin/env python
import os
import sys

# 1. 定义隐藏目录
obj_dir = "src/.obj_fw"

# 2. VariantDir
VariantDir(obj_dir, 'src', duplicate=0)

# 3. 加载 godot-cpp 环境
env = SConscript("godot-cpp/SConstruct")

# 4. 头文件路径
env.Append(CPPPATH=["src/"])

# 5. 收集 .cpp
sources = env.Glob(f"{obj_dir}/*.cpp")

# 5.5 ★ 文档：把 doc_classes/*.xml 打包进 dll
if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData(f"{obj_dir}/doc_gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")
# 6. dll 名字
lib_filename = "{}gdexample{}{}".format(env.subst('$SHLIBPREFIX'), env["suffix"], env.subst('$SHLIBSUFFIX'))

# 7. 编译成 dll
library = env.SharedLibrary(
    "addons/bin/{}".format(lib_filename),
    source=sources,
)

# 8. 默认目标
Default(library)