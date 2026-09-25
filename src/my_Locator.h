#ifndef MY_LOCATOR_H
#define MY_LOCATOR_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

    class CXT : public Node {                                  // CXT 查找器类，继承自 Node 节点类
        GDCLASS(CXT, Node)                                     // Godot 类绑定宏，注册为 CXT

    protected:
        static void _bind_methods();                           // 注册要暴露给 GDScript 的方法

    public:
        CXT();                                                 // 构造函数
        ~CXT();                                                // 析构函数

        // 核心查找函数（对应你笔记里的 CXT 功能）
        // 参数说明：
        // p_node              起始节点指针
        // p_target_name       目标脚本名或类名
        // p_max_depth         最大查找深度（-1 代表无限）
        // p_only_script_name  是否仅查找脚本名（true 则跳过检查 class_name，性能更好）
        Node* FIND(Node* p_node, const String& p_target_name, int p_max_depth = -1, bool p_only_script_name = false);
    };

} // namespace godot

#endif // MY_LOCATOR_H