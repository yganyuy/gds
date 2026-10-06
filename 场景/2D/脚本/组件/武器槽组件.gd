extends Node2D
class_name 武器槽组件


@export var 启用输入: bool = false
@export var 背包组件引用:MaterialContainer=null##如果为空的话就不查找直接切换 
@export var 当前武器: Node2D = null
@export var 强制当前武器作为自身子节点:bool=true


signal 切换武器时(新武器: Node2D,旧武器:Node2D)

func _ready() -> void:
	if 背包组件引用==null:
		print(self.name,"找不到背包组件")
	if 强制当前武器作为自身子节点==true and 当前武器!=null:
		# 将子节点 当前武器 重新挂载到 self 下
		当前武器.reparent(self)

func 切换武器(新武器: PackedScene):##不需要背包组件,使用的是节点对象互换
	var 旧武器:Node=当前武器
	if 新武器 !=null:
		var 新武器加入场景=实体功能.生成物体(新武器,self)
		当前武器=新武器加入场景
		切换武器时.emit(新武器加入场景,旧武器)
	else:return
	if 当前武器!=null:
		实体功能.删除物体(当前武器.get_meta("id"))
