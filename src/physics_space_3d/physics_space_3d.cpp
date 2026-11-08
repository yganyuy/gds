#include "physics_space_3d.h"
#include <godot_cpp/classes/area3d.hpp>
#include <godot_cpp/classes/physics_body3d.hpp>
// 补充软体的头文件引入，确保编译器能识别
#include <godot_cpp/classes/soft_body3d.hpp> 

namespace godot {

    PhysicsSpace3D::PhysicsSpace3D() {
        space_rid = PhysicsServer3D::get_singleton()->space_create();
        PhysicsServer3D::get_singleton()->space_set_active(space_rid, true);
    }

    PhysicsSpace3D::~PhysicsSpace3D() {
        if (space_rid.is_valid()) {
            PhysicsServer3D::get_singleton()->free_rid(space_rid);
        }
    }

    void PhysicsSpace3D::_bind_methods() {
        ClassDB::bind_method(D_METHOD("get_space_rid"), &PhysicsSpace3D::get_space_rid);
        ClassDB::bind_method(D_METHOD("register_node", "node"), &PhysicsSpace3D::register_node);
    }

    void PhysicsSpace3D::_notification(int p_what) {
        if (p_what == NOTIFICATION_READY) {
            connect("child_entered_tree", callable_mp(this, &PhysicsSpace3D::_on_child_entered_tree));
            _propagate_enter_space(this);
        }
    }

    void PhysicsSpace3D::_on_child_entered_tree(Node* p_node) {
        _propagate_enter_space(p_node);
    }

    void PhysicsSpace3D::register_node(Node* p_node) {
        _propagate_enter_space(p_node);
    }

    RID PhysicsSpace3D::get_space_rid() const {
        return space_rid;
    }

    void PhysicsSpace3D::_propagate_enter_space(Node* p_node) {
        if (!p_node) return;

        // 处理刚体、静态体、角色体
        PhysicsBody3D* physics_body = Object::cast_to<PhysicsBody3D>(p_node);
        if (physics_body) {
            PhysicsServer3D::get_singleton()->body_set_space(physics_body->get_rid(), space_rid);
        }
        // 处理区域
        else if (Area3D* area = Object::cast_to<Area3D>(p_node)) {
            PhysicsServer3D::get_singleton()->area_set_space(area->get_rid(), space_rid);
        }
        // 处理软体（SoftBody3D 不继承自 PhysicsBody3D）
        else if (SoftBody3D* soft_body = Object::cast_to<SoftBody3D>(p_node)) {
    
            PhysicsServer3D::get_singleton()->soft_body_set_space(soft_body->get_physics_rid(), space_rid);
        }

        TypedArray<Node> children = p_node->get_children();
        for (int i = 0; i < children.size(); i++) {
            Node* child = Object::cast_to<Node>(children[i]);

            // 遇到嵌套的 PhysicsSpace3D 则不干涉
            if (Object::cast_to<PhysicsSpace3D>(child) && child != this) {
                continue;
            }

            _propagate_enter_space(child);
        }
    }

} // namespace godot