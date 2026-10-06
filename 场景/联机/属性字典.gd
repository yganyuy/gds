extends Node
class_name 需要同步的属性

var 属性配置: Dictionary = {
	# ===== 实体自身属性（直接在实体上查找） =====
	"position": "Vector2",
	"rotation": "float",
	"modulate": "Color",
	"visible": "bool",
	
	# ===== 组件属性（实体自身没有，自动走 CXT） =====
	"生命组件.当前血量": "float",
	"生命组件.最大血量": "float",
	"背包组件.items_sync": "Array",
	"背包组件.current_capacity": "float",
	"背包组件.max_capacity": "float",
}

func 获取默认值(属性名: String):
	var 类型 = 属性配置.get(属性名, "")
	match 类型:
		"Vector2": return Vector2.ZERO
		"float": return 0.0
		"int": return 0
		"bool": return false
		"String": return ""
		"Array": return []
		"Dictionary": return {}
		_: return null

func 获取属性名列表() -> Array:
	return 属性配置.keys()
