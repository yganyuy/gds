extends Node
class_name 属性同步的依赖

@export var 属性配置: Node

func _ready() -> void:
	if 属性配置 == null:
		属性配置 = 属性

func _设置属性(物体: Node, 属性路径: String, 值):
	var 目标节点 = 物体
	var 分段 = 属性路径.split(".")
	var i = 0
	while i < 分段.size() - 1:
		var 分段名 = 分段[i]
		if 分段名 == "..":
			目标节点 = 目标节点.get_parent()
			if 目标节点 == null:
				return false
		else:
			if 目标节点.has_node(分段名):
				目标节点 = 目标节点.get_node(分段名)
			else:
				return false
		i += 1
	var 属性 = 分段[-1]
	if 目标节点 == null:
		return false
	
	var 类型 = 属性配置.属性配置.get(属性路径, "")
	match 类型:
		"Vector2", "Vector3", "float", "int", "bool", "String":
			if 目标节点.has_method("set"):
				目标节点.set(属性, 值)
			else:
				目标节点[属性] = 值
		"Array", "Dictionary":
			if 目标节点.has_method("set"):
				目标节点.set(属性, 值.duplicate(true))
			else:
				目标节点[属性] = 值.duplicate(true)
		_:
			if 目标节点.has_method("set"):
				目标节点.set(属性, 值)
			else:
				目标节点[属性] = 值
	return true

func 进行属性设置同步(物体: Node, 数据: Dictionary):
	if 物体 == null or 属性配置 == null:
		return
	for 属性路径 in 数据.keys():
		if 属性路径 not in 属性配置.属性配置:
			continue
		var 值 = 数据[属性路径]
		_设置属性(物体, 属性路径, 值)
