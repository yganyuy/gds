extends Node
## 属性同步调用器 —— 全局单例（Autoload）
## 客户端发请求 → 服务端应用 → 广播回所有客户端
##
## 用法：
##   属性同步管理.属性同步(物体ID, {"position": Vector2(1,2)})
##   属性同步管理.申请同步(物体ID, {...})   # 客户端主动请求服务端应用

@export var debug: bool = false
## 可选：手动指定依赖，为空则用 实体功能.属性同步需要调用的节点
@export var 属性依赖覆盖: 属性同步的依赖 = null

signal 属性已同步(物体ID: int, 数据: Dictionary)

# ============================================================
#  对外接口
# ============================================================
func 属性同步(物体ID: int, 数据: Dictionary) -> void:
	实体功能.类型判断()
	match 实体功能.服务还是客户:
		0:  # 单机：本地应用一次（值不变，无害）
			_执行同步(物体ID, 数据)
		1:  # 服务端：广播给所有客户端
			rpc("rpc同步属性", 物体ID, 数据)
		2:  # 客户端：默认不主动推（保持原语义），走"申请同步"
			pass

func 申请同步(物体ID: int, 数据: Dictionary) -> void:
	var ef = 实体功能
	if ef == null: return
	ef.类型判断()
	if ef.服务还是客户 == 2:
		rpc_id(1, "rpc请求同步属性", 物体ID, 数据)
	else:
		属性同步(物体ID, 数据)

# ============================================================
#  RPC
# ============================================================
@rpc("any_peer", "call_local", "reliable")
func rpc同步属性(物体ID: int, 数据: Dictionary) -> void:
	_执行同步(物体ID, 数据)   # 服务端也执行（幂等，安全）

@rpc("any_peer", "reliable")
func rpc请求同步属性(物体ID: int, 数据: Dictionary) -> void:
	var ef = 实体功能
	if ef == null or ef.服务还是客户 != 1: return
	# 可选：在这里做权限校验（物体.pid == 请求者）
	属性同步(物体ID, 数据)   # 内部会 rpc 广播，服务端也会应用
# ============================================================
#  执行核心
# ============================================================
func _执行同步(物体ID: int, 数据: Dictionary) -> bool:
	var ef = 实体功能
	if ef == null or ef.自身物体表 == null:
		if debug: push_warning("[属性同步] 物体表未初始化")
		return false
	var 物体 = ef.自身物体表.查找物体(物体ID)
	if 物体 == null:
		if debug: push_warning("[属性同步] 找不到物体 ID=" + str(物体ID))
		return false
	var 依赖 = _获取依赖()
	if 依赖 == null:
		if debug: push_warning("[属性同步] 属性同步的依赖 未设置")
		return false
	依赖.进行属性设置同步(物体, 数据)
	属性已同步.emit(物体ID, 数据)
	return true

func _获取依赖() -> 属性同步的依赖:
	if 属性依赖覆盖 != null:
		return 属性依赖覆盖
	var ef = 实体功能
	if ef == null: return null
	return ef.属性同步需要调用的节点
	# ============ 代理到 实体功能（供同步属性组件使用） ============
var 服务还是客户: int:
	get:
		var ef = 实体功能
		return ef.服务还是客户 if ef != null else 0

var 查找器:
	get:
		var ef = 实体功能
		return ef.查找器 if ef != null else null
