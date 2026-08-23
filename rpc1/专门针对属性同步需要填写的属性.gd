extends Node
class_name 属性同步的依赖 ##这个脚本在自动加载中叫做 属性设置需要的依赖{它是在自动加载之后专门负责同步需要同步的物体属性用的}

@export var 属性配置: Node  #  拖入同一个配置文件

func _ready() -> void:
	if 属性配置==null:
		属性配置=属性

func 进行属性设置同步(物体: Node, 数据: Dictionary):
	if 物体 == null or 属性配置 == null:
		return
	
	for 属性名 in 数据.keys():
		# 检查是否在配置中
		if 属性名 not in 属性配置.属性配置:
			continue
		
		var 值 = 数据[属性名]
		var 类型 = 属性配置.属性配置[属性名]
		
		# 根据类型应用值
		match 类型:
			"Vector2", "Vector3", "float", "int", "bool", "String":
				# 直接赋值
				if 物体.has_method("set"):
					物体.set(属性名, 值)
				else:
					物体[属性名] = 值
			"Array", "Dictionary":
				# 复杂类型深拷贝
				if 物体.has_method("set"):
					物体.set(属性名, 值.duplicate(true))
				else:
					物体[属性名] = 值.duplicate(true)
			_:
				# 默认方式
				if 物体.has_method("set"):
					物体.set(属性名, 值)
				else:
					物体[属性名] = 值
