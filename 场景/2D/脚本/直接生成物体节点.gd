extends Node
class_name 直接生成物体节点
@export var 初始时生成:bool=false
@export var 生成的场景:PackedScene=null
@export var 目标节点:Node2D=null
# Called when the node enters the scene tree for the first time.
var 重试次数:int=20
signal 生成时(物体:Node)
signal 生成了
func _ready() -> void:
	if 初始时生成:
		直接生成物体()
func 直接生成物体():
	while 实体功能.服务还是客户==0:
		实体功能.类型判断()
		await get_tree().create_timer(0.1).timeout##等待类型设置
	重试次数=20
	if 实体功能.服务还是客户==2:
		while 实体功能.初始化场景已经同步==false or 重试次数<=0:
			await get_tree().create_timer(0.1).timeout
			重试次数-=1
		
		if 重试次数<=0:
			重试次数=20
			print("erro  res://场景/2D/脚本/直接生成物体节点.gd 尝试生成失败 ")
			return
		
		var 物体 = 实体功能.生成物体(生成的场景,目标节点)
		生成时.emit(物体)
		生成了.emit()
	
	if 实体功能.服务还是客户==1:
		var 物体 = 实体功能.生成物体(生成的场景,目标节点)
		生成时.emit(物体)
		生成了.emit()
