extends Node
class_name 物理组件

## 速度向量 (X,Y)
@export var 速度向量: Vector2 = Vector2.ZERO
## 重力 (浮点) 平台跳跃设为980左右，俯视角或太空设为0
@export var 重力: float = 980.0
## 质量 (浮点) 默认为父节点
@export var 质量: float = 1.0

## 【核心配置】物理模式决定移动组件如何接管速度
enum 物理模式 {
	平台跳跃, ## 重力>0，移动组件只接管X轴，Y轴交给重力
	俯视角,   ## 重力=0，移动组件接管X轴和Y轴
	纯惯性    ## 重力=0，移动组件接管X轴和Y轴，但松开后不减速（需将移动组件的减速度设为0）
}
var 当前物理模式: 物理模式 = 物理模式.平台跳跃

var 目标节点: Node2D = null

func _ready() -> void:
	目标节点 = get_parent() as Node2D
	if 目标节点 == null:
		push_error("物理组件必须挂载在 Node2D 节点下")
		return
		
	# 自动查找父级是否存在移动组件，并设置引用的物理组件为 self
	for 子节点 in 目标节点.get_children():
		if 子节点 is 移动组件:
			子节点.引用的物理组件 = self
			break
	if 重力==0:
		当前物理模式=物理模式.俯视角
	else :
		当前物理模式=物理模式.平台跳跃

func _physics_process(delta: float) -> void:
	if 目标节点 == null: return
	
	# 1. 应用重力（只有平台跳跃等需要重力的模式才加）
	if 当前物理模式 == 物理模式.平台跳跃:
		速度向量.y += 重力 * delta
	
	# 2. 执行物理移动
	if 目标节点 is CharacterBody2D:
		目标节点.velocity = 速度向量
		目标节点.move_and_slide()
		速度向量 = 目标节点.velocity # 同步碰撞后的实际速度
	else:
		目标节点.position += 速度向量 * delta
