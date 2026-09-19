extends VirtualJoystick

@export var 遥感图片:Node2D=null
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	var 输入方向 := Input.get_vector("a", "d", "w", "s")
	#if 输入方向.length()>0:
	_on_flicked(输入方向)
		

func _on_flicked(输出向量: Vector2) -> void:
	遥感图片.position=输出向量*100
