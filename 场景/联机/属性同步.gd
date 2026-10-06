extends Node
class_name 同步属性

@export var 同步方式: int = 3##0=不进行网络,1=自动同步,2=改变时进行同步 3=同步多少秒
@export var 初始化同步: bool = true
@export var 次每秒: int = 30
@export var 属性配置: Node = null
@export var 同步多少秒: float = 0.5
@export var 查找深度: int = -1
@export var 是否仅查找脚本名: bool = false

var 上次值: Dictionary = {}
var 父节点: Node2D
var 物体ID: int = -1
var 初始化: bool = false
var 计时器: float = 0.0
var 调试:bool=false

# CXT 查找缓存
var 节点缓存: Dictionary = {}

func _ready():
	await get_tree().create_timer(0.02).timeout##延迟查找 防止父节点未被初始化 
	if 实体功能 and 实体功能.服务还是客户 == 2:##如果是客户端则不执行 
		#queue_free()
		return
	父节点 = get_parent()
	if 父节点 and 父节点.has_meta("id"):
		物体ID = 父节点.get_meta("id")
		_保存当前值()
	if 属性配置 == null:
		属性配置 = 属性
	if 初始化同步:
		申请进行同步()
	初始化 = true

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
		3:
			计时器 += delta
			if 计时器 >= 同步多少秒:
				计时器 = 0.0
				自动触发()

func _保存当前值():
	if 属性配置 == null: return
	for 属性名 in 属性配置.获取属性名列表():
		上次值[属性名] = _获取属性值(属性名)

# ============  核心：先自身，后 CXT，最后报错 ============
func _获取属性值(属性路径: String):
	var 实体 = self.get_parent()
	
	# 1. 先尝试作为实体自身属性
	if 属性路径 in 实体:
		return 实体.get(属性路径)
	#
	## 2. 实体自身没有，解析为组件路径
	#if "." not in 属性路径:
		## 没有点号说明本来就是想找实体属性，但没找到
		#push_warning("那个是",父节点,"[同步属性] 找不到实体属性: " + 属性路径 + " (实体: " + str(实体) + ")")
		#return null
	#
	var 分段 = 属性路径.split(".")
	var 组件类名 = 分段[0]
	var 属性名 = 分段[-1]
	var 组件节点 = _查找组件节点(组件类名)
	
	if 组件节点==null:
		return null
	if 调试==true and 组件节点==null:
		print("你知道组件节点是个空值吗?")
		
	#if 组件节点 == null and 调试==true:
		#push_warning("那个是",父节点," [同步属性] 找不到组件: " + 组件类名 + " (属性路径: " + 属性路径 + ")")
		#return null
	## 3. 组件节点上找属性
	#if not (属性名 in 组件节点):
		#push_warning("那个是",父节点,"[同步属性] 组件 " + 组件类名 + " 上找不到属性: " + 属性名)
		#return null
	#
	return 组件节点.get(属性名)

# CXT 查找 + 缓存
func _查找组件节点(组件类名: String) -> Node:
	if 节点缓存.has(组件类名):
		var 缓存节点 = 节点缓存[组件类名].get_ref()
		if is_instance_valid(缓存节点):
			return 缓存节点
		else:
			节点缓存.erase(组件类名)
	
	var 实体 = self.get_parent()
	#print("实体:",实体,"组件类名:",组件类名)
	var 节点 = 实体功能.查找器.FIND(实体,组件类名, 查找深度, 是否仅查找脚本名)
	if 节点 != null:
		节点缓存[组件类名] = weakref(节点)
	return 节点

func _值是否变化(属性名: String, 当前值):
	var 上次 = 上次值.get(属性名)
	var 类型 = 属性配置.属性配置.get(属性名, "")
	match 类型:
		"Array", "Dictionary":
			return str(当前值) != str(上次)
		_:
			return 当前值 != 上次

func 自动触发():
	var 数据 = {}
	for 属性名 in 属性配置.获取属性名列表():
		数据[属性名] = _获取属性值(属性名)
	实体功能.属性同步(物体ID, 数据)

func 变化时同步():
	if not 初始化: return
	var 变化 = {}
	for 属性名 in 属性配置.获取属性名列表():
		var 当前值 = _获取属性值(属性名)
		if _值是否变化(属性名, 当前值):
			变化[属性名] = 当前值
			上次值[属性名] = 当前值
	if 变化.size() > 0:
		实体功能.属性同步(物体ID, 变化)

func 申请进行同步():
	if 实体功能 == null or 实体功能.服务还是客户 != 1 \
		or 父节点 == null or not 父节点.has_meta("id") \
		or 属性配置 == null:
		return
	match 同步方式:
		1, 3: 自动触发()
		2: 变化时同步()
