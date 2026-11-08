#include "physics_space_2d.h"

namespace godot {

PhysicsSpace2D::PhysicsSpace2D() {
    // 在底层创建一个独立的物理空间
    space_rid = PhysicsServer2D::get_singleton()->space_create();
    PhysicsServer2D::get_singleton()->space_set_active(space_rid, true);
}

PhysicsSpace2D::~PhysicsSpace2D() {
    if (space_rid.is_valid()) {
        PhysicsServer2D::get_singleton()->free_rid(space_rid);
    }
}

void PhysicsSpace2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_space_rid"), &PhysicsSpace2D::get_space_rid);
    ClassDB::bind_method(D_METHOD("register_node", "node"), &PhysicsSpace2D::register_node);
}

void PhysicsSpace2D::_notification(int p_what) {
    if (p_what == NOTIFICATION_READY) {
        // 绑定子节点进入信号
        connect("child_entered_tree", callable_mp(this, &PhysicsSpace2D::_on_child_entered_tree));
        // 初始化时，将已经在树下的子节点全部拉入独立空间
        _propagate_enter_space(this);
    }
}

void PhysicsSpace2D::_on_child_entered_tree(Node *p_node) {
    _propagate_enter_space(p_node);
}

void PhysicsSpace2D::register_node(Node *p_node) {
    _propagate_enter_space(p_node);
}

RID PhysicsSpace2D::get_space_rid() const {
    return space_rid;
}

void PhysicsSpace2D::_propagate_enter_space(Node *p_node) {
    if (!p_node) return;

    // 如果当前节点是物理对象（Body 或 Area），就把它塞进新空间
    CollisionObject2D *collision_obj = Object::cast_to<CollisionObject2D>(p_node);
    if (collision_obj) {
        PhysicsServer2D::get_singleton()->body_set_space(collision_obj->get_rid(), space_rid);
    }

    // 递归遍历所有子节点
    TypedArray<Node> children = p_node->get_children();
    for (int i = 0; i < children.size(); i++) {
        Node *child = Object::cast_to<Node>(children[i]);
        
        // 防止嵌套（如果子节点本身也是一个 PhysicsSpace2D，就不干涉它）
        if (Object::cast_to<PhysicsSpace2D>(child) && child != this) {
            continue;
        }
        
        _propagate_enter_space(child);
    }
}

} // namespace godot