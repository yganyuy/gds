#include "simple_tracker_2d.h"

#include <godot_cpp/classes/collision_object2d.hpp>
#include <godot_cpp/classes/physics_direct_space_state2d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/world2d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/typed_array.hpp>

using namespace godot;

void SimpleTracker2D::_bind_methods() {
    // 绑定方法
    ClassDB::bind_method(D_METHOD("tick", "dt"), &SimpleTracker2D::tick);
    ClassDB::bind_method(D_METHOD("resume"), &SimpleTracker2D::resume);
    ClassDB::bind_method(D_METHOD("set_target_position", "pos"), &SimpleTracker2D::set_target_position);
    ClassDB::bind_method(D_METHOD("get_target_position"), &SimpleTracker2D::get_target_position);
    ClassDB::bind_method(D_METHOD("has_target_position"), &SimpleTracker2D::has_target_position);
    ClassDB::bind_method(D_METHOD("get_desired_direction"), &SimpleTracker2D::get_desired_direction);
    ClassDB::bind_method(D_METHOD("get_state"), &SimpleTracker2D::get_state);
    ClassDB::bind_method(D_METHOD("is_halted"), &SimpleTracker2D::is_halted);

    // 绑定新属性
    ClassDB::bind_method(D_METHOD("set_probe_shape_type", "type"), &SimpleTracker2D::set_probe_shape_type);
    ClassDB::bind_method(D_METHOD("get_probe_shape_type"), &SimpleTracker2D::get_probe_shape_type);
    ClassDB::bind_method(D_METHOD("set_probe_radius", "radius"), &SimpleTracker2D::set_probe_radius);
    ClassDB::bind_method(D_METHOD("get_probe_radius"), &SimpleTracker2D::get_probe_radius);
    ClassDB::bind_method(D_METHOD("set_probe_size", "size"), &SimpleTracker2D::set_probe_size);
    ClassDB::bind_method(D_METHOD("get_probe_size"), &SimpleTracker2D::get_probe_size);

    ClassDB::bind_method(D_METHOD("set_update_interval", "s"), &SimpleTracker2D::set_update_interval);
    ClassDB::bind_method(D_METHOD("get_update_interval"), &SimpleTracker2D::get_update_interval);
    ClassDB::bind_method(D_METHOD("set_ray_count", "v"), &SimpleTracker2D::set_ray_count);
    ClassDB::bind_method(D_METHOD("get_ray_count"), &SimpleTracker2D::get_ray_count);
    ClassDB::bind_method(D_METHOD("set_half_fov_deg", "v"), &SimpleTracker2D::set_half_fov_deg);
    ClassDB::bind_method(D_METHOD("get_half_fov_deg"), &SimpleTracker2D::get_half_fov_deg);
    ClassDB::bind_method(D_METHOD("set_lookahead_min", "v"), &SimpleTracker2D::set_lookahead_min);
    ClassDB::bind_method(D_METHOD("get_lookahead_min"), &SimpleTracker2D::get_lookahead_min);
    ClassDB::bind_method(D_METHOD("set_lookahead_max", "v"), &SimpleTracker2D::set_lookahead_max);
    ClassDB::bind_method(D_METHOD("get_lookahead_max"), &SimpleTracker2D::get_lookahead_max);
    
    ClassDB::bind_method(D_METHOD("set_expected_move_speed", "v"), &SimpleTracker2D::set_expected_move_speed);
    ClassDB::bind_method(D_METHOD("get_expected_move_speed"), &SimpleTracker2D::get_expected_move_speed);

    ClassDB::bind_method(D_METHOD("set_stop_distance", "v"), &SimpleTracker2D::set_stop_distance);
    ClassDB::bind_method(D_METHOD("get_stop_distance"), &SimpleTracker2D::get_stop_distance);
    ClassDB::bind_method(D_METHOD("set_obstacle_mask", "v"), &SimpleTracker2D::set_obstacle_mask);
    ClassDB::bind_method(D_METHOD("get_obstacle_mask"), &SimpleTracker2D::get_obstacle_mask);
    ClassDB::bind_method(D_METHOD("set_stuck_timeout", "v"), &SimpleTracker2D::set_stuck_timeout);
    ClassDB::bind_method(D_METHOD("get_stuck_timeout"), &SimpleTracker2D::get_stuck_timeout);
    ClassDB::bind_method(D_METHOD("set_stuck_move_ratio", "v"), &SimpleTracker2D::set_stuck_move_ratio);
    ClassDB::bind_method(D_METHOD("get_stuck_move_ratio"), &SimpleTracker2D::get_stuck_move_ratio);

    // 注册属性面板
    ADD_PROPERTY(PropertyInfo(Variant::INT, "probe_shape_type", PROPERTY_HINT_ENUM, "Circle,Rect"), "set_probe_shape_type", "get_probe_shape_type");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "probe_radius"), "set_probe_radius", "get_probe_radius");
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "probe_size"), "set_probe_size", "get_probe_size");

    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "target_position"), "set_target_position", "get_target_position");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "update_interval", PROPERTY_HINT_RANGE, "0.0,1.0,0.01,suffix:s"), "set_update_interval", "get_update_interval");
    ADD_PROPERTY(PropertyInfo(Variant::INT,   "ray_count", PROPERTY_HINT_RANGE, "1,32,1"), "set_ray_count", "get_ray_count");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "half_fov_deg"), "set_half_fov_deg", "get_half_fov_deg");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "lookahead_min"), "set_lookahead_min", "get_lookahead_min");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "lookahead_max"), "set_lookahead_max", "get_lookahead_max");
    
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "expected_move_speed"), "set_expected_move_speed", "get_expected_move_speed");

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "stop_distance"), "set_stop_distance", "get_stop_distance");
    ADD_PROPERTY(PropertyInfo(Variant::INT,   "obstacle_mask", PROPERTY_HINT_LAYERS_2D_PHYSICS), "set_obstacle_mask", "get_obstacle_mask");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "stuck_timeout"), "set_stuck_timeout", "get_stuck_timeout");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "stuck_move_ratio"), "set_stuck_move_ratio", "get_stuck_move_ratio");

    BIND_ENUM_CONSTANT(TRACKING);
    BIND_ENUM_CONSTANT(HALTED);
    BIND_ENUM_CONSTANT(FINISHED);
    
    BIND_ENUM_CONSTANT(PROBE_CIRCLE);
    BIND_ENUM_CONSTANT(PROBE_RECT);
}

void SimpleTracker2D::set_target_position(const Vector2 &p) {
    target_position = p;
    has_target = true;
}

void SimpleTracker2D::resume() {
    if (state == HALTED) {
        state = TRACKING;
        stuck_accum = 0.0f;
        blocked_accum = 0.0f;
        first_tick = true; 
    }
}

void SimpleTracker2D::_physics_process(double delta) {
    if (update_interval <= 0.0f) return; 
    
    tick_accum += (float)delta;
    if (tick_accum >= update_interval) {
        float dt = tick_accum;
        tick_accum = 0.0f; 
        tick(dt); 
    }
}

void SimpleTracker2D::tick(float dt) {
    if (state == HALTED) return; 
    if (!has_target) { desired_direction = Vector2(); return; }
    if (dt <= 0.0f) return;

    Node2D *body = Object::cast_to<Node2D>(get_parent());
    if (!body) body = this;

    const Vector2 pos = body->get_global_position();
    const Vector2 to_target = target_position - pos;
    const float dist = to_target.length();

    if (dist <= stop_distance) {
        desired_direction = Vector2();
        state = FINISHED;
        first_tick = true;
        return;
    }
    state = TRACKING;
    const Vector2 desired = to_target / dist; 

    // 位移证据检测 
    if (first_tick) {
        last_pos = pos;
        first_tick = false;
    } else {
        const float moved  = pos.distance_to(last_pos); 
        const float wanted = expected_move_speed * dt; 
        last_pos = pos;

        if (moved < wanted * stuck_move_ratio) {
            stuck_accum += dt;
        } else {
            stuck_accum = 0.0f; 
        }
    }

    // 构建探测器形状
    Ref<Shape2D> probe_shape;
    if (probe_shape_type == PROBE_CIRCLE) {
        Ref<CircleShape2D> circle;
        circle.instantiate();
        circle->set_radius(probe_radius);
        probe_shape = circle;
    } else {
        Ref<RectangleShape2D> rect;
        rect.instantiate();
        rect->set_size(probe_size);
        probe_shape = rect;
    }

    // 环境查询初始化
    const float lookahead = CLAMP(dist, lookahead_min, lookahead_max);
    const float half_fov  = Math::deg_to_rad(half_fov_deg);
    Ref<World2D> world = body->get_world_2d();
    PhysicsDirectSpaceState2D *space = world.is_valid() ? world->get_direct_space_state() : nullptr;

    TypedArray<RID> exclude;
    if (CollisionObject2D *co = Object::cast_to<CollisionObject2D>(body)) {
        exclude.push_back(co->get_rid());
    }

    float  best_ang = INFINITY; 
    Vector2 best_dir;

    // 形状扫掠探测 (cast_motion)
    if (space && probe_shape.is_valid()) {
        for (int i = 0; i < ray_count; ++i) {
            const float t = (ray_count == 1) ? 0.0f : ((float)i / (float)(ray_count - 1) * 2.0f - 1.0f);
            const float ang = half_fov * t;
            const Vector2 dir = desired.rotated(ang);

                        // 正确的地方
            Ref<PhysicsShapeQueryParameters2D> q;
            q.instantiate();
            q->set_shape(probe_shape);
            q->set_transform(Transform2D(0, pos));
            q->set_motion(dir * lookahead);
            q->set_collision_mask(obstacle_mask);
            q->set_exclude(exclude);

            PackedFloat32Array result = space->cast_motion(q);
            
            // safe 为 [0, 1] 之间的值。若 >= 0.95，说明带体积扫掠前方基本没有障碍。
            if (result.size() > 0 && result[0] >= 0.95f) {
                const float score = Math::abs(ang); 
                if (score < best_ang) {
                    best_ang = score;
                    best_dir = dir; 
                }
            }
        }
    }

    // 解析探测结果
    if (best_ang == INFINITY) {
        blocked_accum += dt;
        desired_direction = Vector2(); 
    } else {
        blocked_accum = 0.0f;
        desired_direction = best_dir; 
    }

    // 终止判定 
    if (stuck_accum >= stuck_timeout || blocked_accum >= stuck_timeout) {
        state = HALTED;
        desired_direction = Vector2();
        stuck_accum = 0.0f;
        blocked_accum = 0.0f;
        first_tick = true;
        
        if (on_halted) on_halted();
    }
}