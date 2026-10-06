extends Node
class_name 可拾取物

## 拾取后交给武器槽的武器场景
@export var 拾取的武器: PackedScene=null
@export var 数量:int=1
@export var 每个占用的容量:float=1


func _ready() -> void:
	var 区域 = self.get_parent()
	if 区域 is Area2D:
		区域.body_entered.connect(_当有物体进入)

func _当有物体进入(物体: Node2D) -> void:
	if 实体功能 == null or 实体功能.服务还是客户 != 1:return#保证只由服务端运行 
	var 槽 = _查找武器槽(物体)
	var 容器 =_查找背包组件(物体)
	if 槽 == null:
		return
	if 容器 == null:
		return
	拾取(槽,容器)

## 把武器交给槽，并移除自己
func 拾取(槽: Node2D,容器:背包组件) -> void:
	if 实体功能 == null:return
	if 拾取的武器 != null:
		槽.切换武器(拾取的武器)
		容器.拾取(拾取的武器.resource_path,每个占用的容量,数量)
		#实体功能.生成物体(拾取的武器, 槽)
		实体功能.删除物体(self.get_parent().get_meta("id"))

## 在目标身上找武器槽组件（走 CXT 查找器）
func _查找武器槽(物体: Node2D) -> Node:
	if 实体功能 == null:
		print(self.name,"找不到武器槽组件")
		return null
	return 实体功能.查找器.FIND(物体, "武器槽组件", -1, false)
func _查找背包组件(物体:Node2D) -> Node:
	if 实体功能 == null:
		print(self.name,"找不到背包组件")
		return null 
	return 实体功能.查找器.FIND(物体, "背包组件", -1, true)
