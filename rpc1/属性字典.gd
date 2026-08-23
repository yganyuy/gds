extends Node
class_name 需要同步的属性##这个b东西在自动加载里面叫  属性   {你可以把这个当做为 一个注册表,以后需要同步什么属性注册什么属性 } 

var 属性配置: Dictionary = {
	"position": "Vector2",
	"rotation": "float",
	# "新属性name":"类型",
}

# 根据类型获取默认值
func 获取默认值(属性名: String):
	var 类型 = 属性配置.get(属性名, "")
	match 类型:
		"Vector2": return Vector2.ZERO##你可以理解为高中的向量或者是小学的坐标 
		"float": return 0.0##你可以理解为允许是小数
		"int": return 0##你可以理解为它只能是整数 
		"bool": return false##你可以理解为这个是二选一 
		"String": return ""##你可以理解为这是一行文字 
		"Array": return []##你可以理解为这是高中的数组
		"Dictionary": return {}##你可以理解为这是一个字典
		_: return null

# 获取所有属性名（方便遍历）
func 获取属性名列表() -> Array:
	return 属性配置.keys()
