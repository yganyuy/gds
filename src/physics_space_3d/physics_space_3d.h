#ifndef PHYSICS_SPACE_3D_H
#define PHYSICS_SPACE_3D_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/soft_body3d.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/rid.hpp>

namespace godot {

class PhysicsSpace3D : public Node3D {
    GDCLASS(PhysicsSpace3D, Node3D);

private:
    RID space_rid;
    
    void _propagate_enter_space(Node *p_node);
    void _on_child_entered_tree(Node *p_node);

protected:
    static void _bind_methods();

public:
    PhysicsSpace3D();
    ~PhysicsSpace3D();

    RID get_space_rid() const;
    void register_node(Node *p_node);

    virtual void _notification(int p_what);
};

} // namespace godot

#endif // PHYSICS_SPACE_3D_H