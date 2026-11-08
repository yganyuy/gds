#!/usr/bin/env python
import os
import sys

# 1. 定义隐藏目录
obj_dir = "src/.obj_fw"

# 2. VariantDir (将 src 映射到 obj_dir，不生成副本)
VariantDir(obj_dir, 'src', duplicate=0)

# 3. 加载 godot-cpp 环境
env = SConscript("godot-cpp/SConstruct")

# 4. 头文件路径 (让 C++ 的 #include 能找到 src 及其子目录)
env.Append(CPPPATH=["src/"])

# ==============================================================================
# 5. 递归收集源码和头文件（自动排除 .obj_fw 等隐藏目录）
# ==============================================================================
sources = []
headers = []

# 使用 Python 的 os.walk 遍历 src 目录
for root, dirs, files in os.walk("src"):
    # 过滤掉以 '.' 开头的隐藏文件夹（完美排除了 .obj_fw）
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    
    for file in files:
        if file.endswith(".cpp"):
            # 计算相对路径，并拼接到 obj_dir 下，满足 VariantDir 机制
            rel_path = os.path.relpath(os.path.join(root, file), "src")
            sources.append(os.path.join(obj_dir, rel_path))
        elif file.endswith(".h"):
            rel_path = os.path.relpath(os.path.join(root, file), "src")
            headers.append(os.path.join(obj_dir, rel_path))

# 5.1 让所有 .cpp 依赖所有 .h（这样改头文件时才会重新编译）
for src in sources:
    env.Depends(src, headers)

# ==============================================================================
# 5.5 文档：把 doc_classes/*.xml 打包进 dll
# ==============================================================================
if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData(f"{obj_dir}/doc_gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")

# 6. 库文件名：Android / Linux 强制加 "lib" 前缀
if env["platform"] in ("android", "linux"):
    _prefix = "lib"
else:
    _prefix = env.subst('$SHLIBPREFIX')

lib_filename = "{}gdexample{}{}".format(_prefix, env["suffix"], env.subst('$SHLIBSUFFIX'))

# 7. 编译成 dll / so
library = env.SharedLibrary(
    "addons/bin/{}".format(lib_filename),
    source=sources,
)

# 8. 默认目标
Default(library)