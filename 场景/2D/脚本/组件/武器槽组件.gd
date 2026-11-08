extends Node2D
class_name 武器槽组件_2D

@export var 启用输入: bool = false
@export var 背包组件引用:MaterialContainer=null
@export var 当前武器: Node2D = null
@export var 强制当前武器作为自身子节点:bool=true

signal 切换武器时(新武器: Node2D)


func _ready() -> void:
	if 背包组件引用 == null:
		print(self.name, "找不到背包组件")
	if 强制当前武器作为自身子节点 and 当前武器 != null:
		当前武器.reparent(self)

	# ★ 连接全局单例的信号
	if 实体功能 != null:
		if not 实体功能.生成时.is_connected(_当全局物体生成):
			实体功能.生成时.connect(_当全局物体生成)


func _exit_tree() -> void:
	# ★ 断开连接，防止残留 Callable
	if 实体功能 != null and 实体功能.生成时.is_connected(_当全局物体生成):
		实体功能.生成时.disconnect(_当全局物体生成)


func 切换武器(新武器: PackedScene) -> void:
	if 新武器 == null:
		return

	# 先删旧武器
	if 当前武器 != null and is_instance_valid(当前武器):
		var 旧ID: int = 当前武器.get_meta("id", 0)
		if 旧ID > 0:
			实体功能.删除物体(旧ID)
	当前武器 = null

	# 生成新武器
	var 新武器id: int = 实体功能.生成物体(新武器, self)

	# ★ 服务端/单机：id > 0，节点已在物体表里，直接拿
	# ★ 客户端：id <= 0，什么都不做，等 _当全局物体生成 补位
	if 新武器id > 0:
		var 新武器实例 = 实体功能.自身物体表.查找物体(新武器id)   # 或 实体功能.自身物体表.查找物体(新武器id)
		if 新武器实例 != null:
			当前武器 = 新武器实例
			切换武器时.emit(新武器实例)


# ★ 客户端靠这条信号补位
func _当全局物体生成(物体: Node, _ID: int) -> void:
	if 物体 == null or not is_instance_valid(物体):
		return
	if 物体.get_parent() != self:
		return   # 不是挂在我下面的，不关我事
	if 物体 == 当前武器:
		return   # 已经认领过了

	当前武器 = 物体 as Node2D
	切换武器时.emit(当前武器)
	print("[武器槽] 认领武器: ", 物体.name, " ID=", 物体.get_meta("id", 0))
