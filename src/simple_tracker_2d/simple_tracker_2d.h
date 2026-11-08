#pragma once

#include <godot_cpp/classes/node2d.hpp>
#include <functional>

namespace godot {

class SimpleTracker2D : public Node2D {
    GDCLASS(SimpleTracker2D, Node2D)

public:
    // 组件状态枚举
    enum State { 
        TRACKING, // 正在追踪
        HALTED,   // 卡死/被阻挡，停止运算
        FINISHED  // 到达目标
    };

    // 探测器形状枚举
    enum ProbeShapeType {
        PROBE_CIRCLE, // 圆形 (适合步兵等大部分 RTS 单位)
        PROBE_RECT    // 矩形 (适合坦克、建筑等长宽比例明显的单位)
    };

private:
    // ---- 目标数据 ----
    Vector2 target_position;      // 目标点的世界坐标
    bool has_target = false;      // 是否已经设置了目标

    // ---- 避障探测参数 ----
    ProbeShapeType probe_shape_type = PROBE_CIRCLE; // 探测器形状类型
    float   probe_radius       = 9.0f;    // 圆形探测半径 (建议比自身碰撞体大 1~2 像素作为安全边际)
    Vector2 probe_size         = Vector2(18, 18); // 矩形探测长宽

    int     ray_count          = 9;       // 扇形探测数量 (推荐 5~9)
    float   half_fov_deg       = 60.0f;   // 探测扇形的半角 (度)
    float   lookahead_min      = 24.0f;   // 探测的最小距离
    float   lookahead_max      = 96.0f;   // 探测的最大距离
    float   stop_distance      = 6.0f;    // 到达目标的判定阈值
    uint32_t obstacle_mask     = 1;       // 障碍物物理层 (只检测静态地形)

    // ---- 移动与卡死判定参数 ----
    float   expected_move_speed = 120.0f; // 预期移动速度 (用于卡死判定，不直接输出)
    float   stuck_move_ratio   = 0.2f;    // 实际位移 < 预期位移 * 此比例，视为"没动"
    float   stuck_timeout      = 0.4f;    // 连续多久判定为卡死 (秒)
    float   update_interval    = 0.0f;    // 运算频率 (0 = 手动 tick，>0 = 内部自动节流)

    // ---- 运行时内部状态 ----
    State    state = TRACKING;            
    Vector2  desired_direction;           // 输出给外部的纯方向向量 (长度 0 或 1)
    Vector2  last_pos;                    
    float    stuck_accum   = 0.0f;        
    float    blocked_accum = 0.0f;        
    float    tick_accum    = 0.0f;        
    bool     first_tick    = true;        

    std::function<void()> on_halted;

protected:
    static void _bind_methods();

public:
    SimpleTracker2D() = default;
    ~SimpleTracker2D() = default;

    void _physics_process(double delta) override;

    // 唯一计算入口
    void tick(float dt);

    void resume();

    void    set_target_position(const Vector2 &p);
    Vector2 get_target_position() const { return target_position; }
    bool    has_target_position() const { return has_target; }

    void  set_update_interval(float s) { update_interval = s; }
    float get_update_interval() const  { return update_interval; }

    Vector2 get_desired_direction() const { return desired_direction; }
    State   get_state() const             { return state; }
    bool    is_halted() const             { return state == HALTED; }

    void set_on_halted(const std::function<void()> &cb) { on_halted = cb; }

    // --- Getter / Setter ---
    void  set_probe_shape_type(ProbeShapeType p_type) { probe_shape_type = p_type; }
    ProbeShapeType get_probe_shape_type() const { return probe_shape_type; }

    void  set_probe_radius(float p_radius) { probe_radius = p_radius; }
    float get_probe_radius() const { return probe_radius; }

    void  set_probe_size(const Vector2& p_size) { probe_size = p_size; }
    Vector2 get_probe_size() const { return probe_size; }

    void  set_ray_count(int v)             { ray_count = v < 1 ? 1 : v; }
    int   get_ray_count() const            { return ray_count; }
    void  set_half_fov_deg(float v)        { half_fov_deg = v; }
    float get_half_fov_deg() const         { return half_fov_deg; }
    void  set_lookahead_min(float v)       { lookahead_min = v; }
    float get_lookahead_min() const        { return lookahead_min; }
    void  set_lookahead_max(float v)       { lookahead_max = v; }
    float get_lookahead_max() const        { return lookahead_max; }
    
    void  set_expected_move_speed(float v) { expected_move_speed = v; }
    float get_expected_move_speed() const  { return expected_move_speed; }

    void  set_stop_distance(float v)       { stop_distance = v; }
    float get_stop_distance() const        { return stop_distance; }
    void  set_obstacle_mask(uint32_t v)    { obstacle_mask = v; }
    uint32_t get_obstacle_mask() const     { return obstacle_mask; }
    void  set_stuck_timeout(float v)       { stuck_timeout = v; }
    float get_stuck_timeout() const        { return stuck_timeout; }
    void  set_stuck_move_ratio(float v)    { stuck_move_ratio = v; }
    float get_stuck_move_ratio() const     { return stuck_move_ratio; }
};

} // namespace godot

VARIANT_ENUM_CAST(godot::SimpleTracker2D::State);
VARIANT_ENUM_CAST(godot::SimpleTracker2D::ProbeShapeType);