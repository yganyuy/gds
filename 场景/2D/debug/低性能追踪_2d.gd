extends CharacterBody2D

@onready var tracker: SimpleTracker2D = $SimpleTracker2D

# 获取同级节点 bata1
@onready var target_node: CharacterBody2D = get_parent().get_node("bata1")

var my_speed: float = 120.0
var last_target_pos: Vector2

func _ready() -> void:
	# 1. 设置障碍层掩码 (非常关键！)
	# 假设地形在 Layer 1，bata1 和 bata2 都在 Layer 2。
	# 这里只填 1，意味着射线只会被墙挡住，绝不会打在 bata1 身上。
	tracker.obstacle_mask = 1 
	
	# 2. 设置组件运算频率：10Hz (每0.1秒算一次方向)
	# 这比你每物理帧(60Hz)去算要节省太多性能了
	tracker.update_interval = 0.1 
	
	# 3. 告诉组件我们的移动速度，用于它的卡死判定
	tracker.expected_move_speed = my_speed
	
	# 初始化目标位置记录
	last_target_pos = target_node.global_position


func _physics_process(delta: float) -> void:
	if is_instance_valid(target_node):
		# 4. 实时更新追踪目标点
		tracker.set_target_position(target_node.global_position)
		
		# 5. 防卡死唤醒机制
		# 如果追踪者被墙卡住了，但 bata1 跑远了，给它个机会重新爬起来追
		if tracker.is_halted():
			if target_node.global_position.distance_to(last_target_pos) > 50.0:
				tracker.resume() # 唤醒组件
				last_target_pos = target_node.global_position
		else:
			last_target_pos = target_node.global_position

	# 6. 获取纯方向向量，并乘上自身速度
	var dir: Vector2 = tracker.get_desired_direction()
	velocity = dir * my_speed
	
	# 7. 执行物理移动
	move_and_slide()
