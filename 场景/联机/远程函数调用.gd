extends Node
## 服务器调用 —— 全局单例（Autoload）远程函数调用
## 客户端发意图 → 服务端执行 → 属性同步广播回所有客户端
##
## 用法（任何地方）：
##   服务器调用.申请调用(物体ID, "背包组件", "购买物品", ["药水", 3])
##   服务器调用.申请调用(物体ID, "", "受击", [10])   # 空组件名 = 调物体自身

@export var 查找深度: int = -1
@export var 是否仅查找脚本名: bool = true
@export var 校验权限: bool = false   ## 开启后只有物体 pid 匹配请求者才允许调用
@export var debug: bool = false

signal 收到调用(物体: Node, 组件名: String, 函数名: String, 参数: Array, 请求者: int)

var _节点缓存: Dictionary = {}

# ============================================================
#  对外接口
# ============================================================
func 申请调用(物体ID: int, 组件名: String, 函数名: String, 参数: Array = []) -> void:
	var ef = 实体功能
	#_获取实体功能()
	if ef == null: return
	ef.类型判断()

	match ef.服务还是客户:
		0:  # 单机
			_本地执行(物体ID, 组件名, 函数名, 参数, 0)
		1:  # 服务端
			_本地执行(物体ID, 组件名, 函数名, 参数, multiplayer.get_unique_id())
		2:  # 客户端 → 发到服务端
			rpc_id(1, "rpc_接收调用请求", 物体ID, 组件名, 函数名, 参数)

# ============================================================
#  RPC
# ============================================================
@rpc("any_peer", "reliable")
func rpc_接收调用请求(物体ID: int, 组件名: String, 函数名: String, 参数: Array) -> void:
	var ef =实体功能 
	#_获取实体功能()
	if ef == null or ef.服务还是客户 != 1: return
	var 请求者 = multiplayer.get_remote_sender_id()
	_本地执行(物体ID, 组件名, 函数名, 参数, 请求者)

# ============================================================
#  执行核心
# ============================================================
func _本地执行(物体ID: int, 组件名: String, 函数名: String, 参数: Array, 请求者: int) -> void:
	var ef = 实体功能
	#_获取实体功能()
	if ef == null or ef.物体表 == null:
		if debug: push_warning("[服务器调用] 物体表未初始化")
		return

	var 物体 = ef.物体表.查找物体(物体ID)
	if 物体 == null:
		if debug: push_warning("[服务器调用] 找不到物体 ID=" + str(物体ID))
		return

	if 校验权限:
		var pid = 物体.get_meta("pid", -1)
		if pid != 请求者:
			if debug:
				push_warning("[服务器调用] 请求者 %d 无权操作物体 %d（pid=%d）" % [请求者, 物体ID, pid])
			return

	var 目标 = _查找目标节点(物体, 组件名)
	if 目标 == null:
		if debug: push_warning(物体.name,"[服务器调用] 物体 %d 上找不到组件: %s" % [物体ID, 组件名])
		return

	if not 目标.has_method(函数名):
		if debug: push_warning(物体.name,"[服务器调用] %s 上找不到方法: %s" % [组件名, 函数名])
		return

	if debug:
		print(物体.name,"[服务器调用] ", 目标, ".", 函数名, "(", 参数, ") 请求者=", 请求者)

	目标.callv(函数名, 参数)
	收到调用.emit(物体, 组件名, 函数名, 参数, 请求者)

# ============================================================
#  查找目标节点
# ============================================================
func _查找目标节点(物体: Node, 组件名: String) -> Node:
	if 组件名 == "":
		return 物体

	var 缓存Key = str(物体.get_instance_id()) + "|" + 组件名
	if _节点缓存.has(缓存Key):
		var 缓存 = _节点缓存[缓存Key].get_ref()
		if is_instance_valid(缓存):
			return 缓存
		_节点缓存.erase(缓存Key)

	var ef = 实体功能
	#_获取实体功能()
	var 找到: Node = null
	if ef != null and ef.查找器 != null:
		#print(物体,"/", 组件名,"/", 查找深度,"/", 是否仅查找脚本名)
		找到 = 实体功能.查找器.FIND(物体, 组件名, 查找深度, 是否仅查找脚本名)
		#print(找到,"/",物体,"/", 组件名,"/", 查找深度,"/", 是否仅查找脚本名)
		
	if 找到 == null:
		找到 = 物体.get_node_or_null(组件名)

	if 找到 != null:
		_节点缓存[缓存Key] = weakref(找到)
	return 找到

# ============================================================
#  延迟获取实体功能（避免 Autoload 加载顺序坑）
## ============================================================
#func _获取实体功能() -> 生成物体:
	## 你的项目里"实体功能"是个全局名（Autoload 或全局变量），直接引用
	#if 实体功能 is 生成物体:
		#return 实体功能
	#return null

func 清理物体缓存(物体: Node) -> void:
	if 物体 == null: return
	var 前缀 = str(物体.get_instance_id()) + "|"
	for k in _节点缓存.keys():
		if k.begins_with(前缀):
			_节点缓存.erase(k)
