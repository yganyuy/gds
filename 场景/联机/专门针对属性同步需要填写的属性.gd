extends Node
class_name 属性同步的依赖

@export var 属性配置: Node
@export var 查找深度: int = -1
@export var debug:bool=false


# CXT 缓存（按实体ID隔离，防止不同实体间串味）
var 写入缓存: Dictionary = {}

func _ready() -> void:
	if 属性配置 == null:
		属性配置 = 属性

# ============ 自身 → CXT → 报错 ============
func _设置属性(物体: Node, 属性路径: String, 值) -> bool:
	
	# 1. 先尝试作为实体自身属性
	if 属性路径 in 物体:
		_写入(物体, 属性路径, 值)
		return true
	
	# 2. 实体自身没有，解析为组件路径
	if "." not in 属性路径:
		push_warning("[属性依赖] 找不到实体属性: " + 属性路径)
		return false
	
	var 分段 = 属性路径.split(".")
	var 组件类名 = 分段[0]
	var 属性名 = 分段[-1]
	
	var 组件节点 = _查找组件节点(物体, 组件类名)
	if debug==true:
		if 组件节点 == null:
			push_warning("[属性依赖] 找不到组件: " + 组件类名 + " (属性路径: " + 属性路径 + ")")
			return false
		if not (属性名 in 组件节点):
			push_warning("[属性依赖] 组件 " + 组件类名 + " 上找不到属性: " + 属性名)
			return false
		return false
	# 3. 组件节点上找属性
	_写入(组件节点, 属性名, 值)
	return true

# 统一写入（复杂类型做深拷贝）
func _写入(目标节点: Node, 属性名: String, 值):
	if 目标节点==null:return
	#var 类型 = 属性配置.属性配置.get(属性名, "")
	# 复杂类型用深拷贝，避免两端共享引用
	var 实际类型 = 属性配置.属性配置.get(属性名, "")
	if 实际类型 in ["Array", "Dictionary"]:
		目标节点.set(属性名, 值.duplicate(true))
	else:
		目标节点.set(属性名, 值)

# CXT 查找 + 缓存
func _查找组件节点(物体: Node, 组件类名: String) -> Node:
	var 缓存Key = str(物体.get_instance_id()) + "_" + 组件类名
	
	if 写入缓存.has(缓存Key):
		var 缓存节点 = 写入缓存[缓存Key].get_ref()
		if is_instance_valid(缓存节点):
			return 缓存节点
		else:
			写入缓存.erase(缓存Key)
	
	var 节点 = 实体功能.查找器.FIND(物体,组件类名, 查找深度,false)
	if 节点 != null:
		写入缓存[缓存Key] = weakref(节点)
	return 节点

func 进行属性设置同步(物体: Node, 数据: Dictionary):
	if 物体 == null or 属性配置 == null:
		return
	for 属性路径 in 数据.keys():
		if 属性路径 not in 属性配置.属性配置:
			continue
		var 值 = 数据[属性路径]
		_设置属性(物体, 属性路径, 值)
