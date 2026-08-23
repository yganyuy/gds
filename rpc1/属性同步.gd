extends Node
class_name 同步属性##这个是动态创建的东西,他专门负责上传属性进行同步用{他会上传自己父节点对象,还有变化的属性.它一般由服务端发送到客户端时使用 } 

@export var 同步方式: int = 2##1=自动触发 2=改变时触发 0=不会触发 
@export var 初始化同步: bool = true
@export var 次每秒: int = 50
@export var 属性配置: Node=null  ##null=自动引用 

var 上次值: Dictionary = {}
var 父节点: Node2D
var 物体ID: int = -1
var 初始化: bool = false
var 计时器: float = 0.0

func _ready():
	await get_tree().create_timer(0.02).timeout##对父节点一个初始化的时间 
	父节点 = get_parent()
	if 父节点 and 父节点.has_meta("id"):
		物体ID = 父节点.get_meta("id")
		_保存当前值()
	if 属性配置==null:
		属性配置=属性#______________________注意这里
	初始化 = true
	if 初始化同步:
		申请进行同步()

func _process(delta):
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

func _保存当前值():
	if 属性配置 == null:
		return
	for 属性名 in 属性配置.获取属性名列表():
		上次值[属性名] = _获取属性值(属性名)

func _获取属性值(属性名: String):
	# 尝试从父节点读取属性
	if 父节点.has_method("get"):
		return 父节点.get(属性名)
	# 如果 get 方法不存在，直接读取属性
	return 父节点.get(属性名)

func _值是否变化(属性名: String, 当前值):
	var 上次 = 上次值.get(属性名)
	# 根据类型做比较
	var 类型 = 属性配置.属性配置.get(属性名, "")
	match 类型:##以后要加入新类型就在这里加 
		"Vector2", "Vector3":
			return 当前值 != 上次
		"float", "int":
			return 当前值 != 上次
		"bool":
			return 当前值 != 上次
		"String":
			return 当前值 != 上次
		"Array":
			# 数组比较内容是否相同（简单版本）
			return str(当前值) != str(上次)
		"Dictionary":
			# 字典比较内容是否相同（简单版本）
			return str(当前值) != str(上次)
		_:
			# 默认比较
			return 当前值 != 上次

func 自动触发():
	var 数据 = {}
	for 属性名 in 属性配置.获取属性名列表():
		数据[属性名] = _获取属性值(属性名)
	实体功能.属性同步(物体ID, 数据)

func 变化时同步():
	if 初始化==true:
		var 变化 = {}
		for 属性名 in 属性配置.获取属性名列表():
			var 当前值 = _获取属性值(属性名)
			if _值是否变化(属性名, 当前值):
				变化[属性名] = 当前值
				上次值[属性名] = 当前值
		if 变化.size() > 0:
			实体功能.属性同步(物体ID, 变化)

func 申请进行同步():
	if 实体功能 == null or 实体功能.服务还是客户 != 1 or 父节点 == null or not 父节点.has_meta("id") or 属性配置==null:
		return
	match 同步方式:
		1: 自动触发()
		2: 变化时同步()
