#include "my_locator.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <cassert>    // 必须包含，否则 assert 会报错

using namespace godot;

void CXT::_bind_methods() {
    // 绑定 FIND 方法，暴露给 GDScript 调用，方法名也叫 FIND
    ClassDB::bind_method(D_METHOD("FIND", "node", "target_name", "max_depth", "only_script_name"),
        &CXT::FIND, DEFVAL(-1), DEFVAL(false));
}

CXT::CXT() {}
CXT::~CXT() {}

// 核心查找逻辑实现
Node* CXT::FIND(Node* p_node, const String& p_target_name, int p_max_depth, bool p_only_script_name) {
    // 开发阶段使用 assert 快速失败，一旦传入空指针立刻报错崩溃
    assert(p_node != nullptr && "【CXT错误】传入的起始节点指针为空！");

    // 1. 获取节点上挂载的脚本
    Ref<Script> script = p_node->get_script();                    // 获取脚本引用
    if (script.is_valid()) {                                      // 如果脚本存在且有效
        String script_path = script->get_path();                  // 脚本的完整路径字符串
        // 提取纯文件名（如 "res://scripts/Player.gd" -> "Player"）
        String script_file = script_path.get_file().get_basename(); // 提取文件名并去掉扩展名

        // 2. 优先匹配脚本文件名（性能最好，不需要解析脚本内部）
        if (script_file == p_target_name) {                       // 如果脚本名等于目标名
            return p_node;                                        // 找到匹配节点，直接返回
        }

        // 3. 如果性能不敏感，或者没匹配到脚本名，再尝试匹配 class_name
        if (!p_only_script_name) {                                // 如果不是“仅查找脚本名”模式
            // 注意：get_global_name() 需要 Godot 4.3+ 版本，低版本会编译报错
            String global_name = script->get_global_name();       // 获取脚本的全局类名
            if (!global_name.is_empty() && global_name == p_target_name) { // 类名非空且匹配
                return p_node;                                    // 返回找到的节点
            }
        }
    }

    // 4. 检查层数限制
    if (p_max_depth == 0) {                                       // 如果最大深度耗尽
        return nullptr;                                           // 返回空指针，停止向下查找
    }

    // 5. 递归查找子节点（深度优先遍历）
    int child_count = p_node->get_child_count();                  // 获取子节点数量
    for (int i = 0; i < child_count; i++) {                       // 遍历所有子节点
        Node* child = p_node->get_child(i);                       // 获取当前子节点指针
        Node* result = FIND(child, p_target_name, p_max_depth - 1, p_only_script_name); // 递归调用自己，深度减 1
        if (result) return result;                                // 如果子节点里找到了匹配的，直接返回
    }

    return nullptr;                                               // 遍历完当前分支没找到，返回空
}