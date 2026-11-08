#ifndef PHYSICS_SPACE_2D_H
#define PHYSICS_SPACE_2D_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/physics_server2d.hpp>
#include <godot_cpp/classes/collision_object2d.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/rid.hpp>

namespace godot {

class PhysicsSpace2D : public Node2D {
    GDCLASS(PhysicsSpace2D, Node2D);

private:
    RID space_rid;
    
    void _propagate_enter_space(Node *p_node);
    void _on_child_entered_tree(Node *p_node);

protected:
    static void _bind_methods();

public:
    PhysicsSpace2D();
    ~PhysicsSpace2D();

    // 暴露给 GDScript 的接口
    RID get_space_rid() const;
    void register_node(Node *p_node);

    virtual void _notification(int p_what);
};

} // namespace godot

#endif // PHYSICS_SPACE_2D_H