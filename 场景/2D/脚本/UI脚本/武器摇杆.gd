extends VirtualJoystick

@export var 遥感图片: Node2D = null
var 武器槽: Node2D = null

func 输入移动摇杆(输入向量:Vector2):
	if 武器槽.当前武器==null:return
	var 角度 := 输入向量.angle()
	远程函数调用.申请调用(武器槽.当前武器.get_meta("id"),"武器_2D", "修改角度", [输入向量, 角度])

func _process(_delta) -> void:
	if 玩家当前角色.玩家角色.size() <= 0: return
	if 武器槽 == null:武器槽 = 实体功能.查找器.FIND(玩家当前角色.玩家角色[0], "武器槽组件", -1, true)
	var 输入向量 := Input.get_vector("h", "k", "u", "j")
	if 武器槽.当前武器==null:return
	if 输入向量.length()>0.01:输入移动摇杆(输入向量)
	_on_flicked(输入向量)

func _on_flicked(输出向量: Vector2) -> void:
	if 遥感图片!=null:
		遥感图片.position=输出向量*100#设置图像
