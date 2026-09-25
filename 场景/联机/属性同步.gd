extends Node
class_name 同步属性##这是一个自动创建的 属性同步器 

@export var 同步方式: int = 1 ##0=不进行网络,1=自动同步,2=改变时进行同步 3=同步多少秒
@export var 初始化同步: bool = true
@export var 次每秒: int = 6
@export var 属性配置: Node = null
@export var 同步多少秒:float=3

var 上次值: Dictionary = {}
var 父节点: Node2D
var 物体ID: int = -1
var 初始化: bool = false
var 计时器: float = 0.0

func _ready():
	await get_tree().create_timer(0.02).timeout#延时触发 查找父物体 
	父节点 = get_parent()
	if 父节点 and 父节点.has_meta("id"):
		物体ID = 父节点.get_meta("id")
		_保存当前值()
	if 属性配置 == null:
		属性配置 = 属性
	初始化 = true
	if 初始化同步:
		申请进行同步()

func _process(delta):##delta=帧间隔运行时间 
	if 实体功能 == null or 实体功能.服务还是客户 != 1 or not 初始化:
		return
	match 同步方式:
		1:
			计时器 += delta
			if 次每秒 > 0 and 计时器 >= 1.0 / 次每秒:
				计时器 = 0.0
				自动触发()
		2:
			变化时同步()
		3:
			if 同步多少秒>0:
				self.同步多少秒-=delta
				自动触发()

func _保存当前值():
	if 属性配置 == null:
		return
	for 属性名 in 属性配置.获取属性名列表():
		上次值[属性名] = _获取属性值(属性名)

func _获取属性值(属性名: String):
	# 如果包含 "."，解析路径
	if "." in 属性名:
		var 分段 = 属性名.split(".")
		var 当前节点: Node = 父节点
		var i = 0
		while i < 分段.size() - 1:
			var 分段名 = 分段[i]
			if 分段名 == "..":
				当前节点 = 当前节点.get_parent()
				if 当前节点 == null:
					return null
			else:
				if 当前节点.has_node(分段名):
					当前节点 = 当前节点.get_node(分段名)
				else:
					return null
			i += 1
		var 属性 = 分段[-1]
		if 当前节点 == null:
			return null
		if 当前节点.has_method("get"):
			return 当前节点.get(属性)
		else:
			return 当前节点.get(属性)
	else:
		# 直接查父节点
		if 父节点.has_method("get"):
			return 父节点.get(属性名)
		else:
			return 父节点.get(属性名)

func _值是否变化(属性名: String, 当前值):
	var 上次 = 上次值.get(属性名)
	var 类型 = 属性配置.属性配置.get(属性名, "")
	match 类型:
		"Vector2", "Vector3":
			return 当前值 != 上次
		"float", "int":
			return 当前值 != 上次
		"bool":
			return 当前值 != 上次
		"String":
			return 当前值 != 上次
		"Array":
			return str(当前值) != str(上次)
		"Dictionary":
			return str(当前值) != str(上次)
		_:
			return 当前值 != 上次

func 自动触发():
	var 数据 = {}
	for 属性名 in 属性配置.获取属性名列表():
		数据[属性名] = _获取属性值(属性名)
	实体功能.属性同步(物体ID, 数据)

func 变化时同步():
	if 初始化 == true:
		var 变化 = {}
		for 属性名 in 属性配置.获取属性名列表():
			var 当前值 = _获取属性值(属性名)
			if _值是否变化(属性名, 当前值):
				变化[属性名] = 当前值
				上次值[属性名] = 当前值
		if 变化.size() > 0:
			实体功能.属性同步(物体ID, 变化)

func 申请进行同步():
	if 实体功能 == null or 实体功能.服务还是客户 != 1 or 父节点 == null or not 父节点.has_meta("id") or 属性配置 == null:
		return
	match 同步方式:
		1: 自动触发()
		2: 变化时同步()
