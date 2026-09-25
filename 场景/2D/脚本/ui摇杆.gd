extends VirtualJoystick

@export var 遥感图片:Node2D=null

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	var 输入方向 := Input.get_vector("a", "d", "w", "s")
	if 玩家当前角色.玩家角色.size()<=0:
		return
	if 玩家当前角色.玩家角色[0].get_node_or_null("移动组件")!=null:
		var 玩家移动组件 =玩家当前角色.玩家角色[0].get_node("移动组件")
		if 输入方向.length()>0:
			#print(输入方向)####№############№@@####
			玩家移动组件.开始移动(输入方向)
		else:
			玩家移动组件.结束移动()
	_on_flicked(输入方向)
		

func _on_flicked(输出向量: Vector2) -> void:
	if 遥感图片!=null:
		遥感图片.position=输出向量*100#设置图像
