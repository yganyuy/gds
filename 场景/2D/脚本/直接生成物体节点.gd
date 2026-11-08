extends Node
class_name 直接生成物体节点

@export var 初始时生成: bool = false
@export var 生成的场景: PackedScene = null
@export var 目标节点: Node2D = null
@export var 一次性: bool = false
@export var 挂载属性同步器: bool = true
@export var 延迟计时: float = 0.0
@export_enum("服务端主动", "客户端请求") var 方式: int = 0

signal 生成时(物体ID: int)   # ★ 改成 int
signal 生成了

func _ready() -> void:
	if 初始时生成:
		直接生成物体()

func 直接生成物体():
	if 生成的场景 == null:
		push_error("[直接生成物体节点] 生成的场景未赋值: " + name)
		return
	if 目标节点 == null:
		push_error("[直接生成物体节点] 目标节点未赋值: " + name)
		return

	if 延迟计时 > 0:
		await get_tree().create_timer(延迟计时).timeout

	实体功能.类型判断()

	# 联机未建立时等信号，别急着单机生成
	if 实体功能.服务还是客户 == 0:
		if rpc联机方法.shi_fou_chuang_jian_le:
			await rpc联机方法.创建了房间
		else:
			await rpc联机方法.连上了
		实体功能.类型判断()

	var 实际执行 = false
	var 新ID := 0
	match 方式:
		0:  # 服务端主动
			if 实体功能.服务还是客户 == 1:
				var pid = rpc联机方法.wang_luo_id if rpc联机方法 else 1
				新ID = 实体功能.生成物体(生成的场景, 目标节点, 挂载属性同步器, pid)
				实际执行 = true
		1:  # 客户端请求
			if 实体功能.服务还是客户 == 2:
				新ID = 实体功能.生成物体(生成的场景, 目标节点, 挂载属性同步器, rpc联机方法.wang_luo_id)
				实际执行 = true

	if 实际执行:
		生成时.emit(新ID)
		生成了.emit()
		if 一次性:
			queue_free()
