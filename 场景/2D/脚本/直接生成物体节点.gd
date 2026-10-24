extends Node
class_name 直接生成物体节点
@export var 初始时生成:bool=false
@export var 生成的场景:PackedScene=null
@export var 目标节点:Node2D=null
@export var 一次性:bool=false
@export var 挂载属性同步器:bool=true
@export var 延迟计时:float=0.0
#@export var 场景预加载:bool=false
@export_enum("双端通用","仅服务端","仅客户端") var 方式:int=0
#@export var 向量偏移:Vector2
# Called when the node enters the scene tree for the first time.

signal 生成时(物体:Node)
signal 生成了

func _ready() -> void:
	if 初始时生成==true:
		直接生成物体()

func 直接生成物体():
	await get_tree().create_timer(延迟计时).timeout##等待类型设置
	if 方式==1:
		if 实体功能.服务还是客户==1:
			var 物体 = 实体功能.生成物体(生成的场景,目标节点,挂载属性同步器,1)
			生成时.emit(物体)
			生成了.emit()
	elif 方式==2:
		if 实体功能.服务还是客户!=1:
			var 物体 = 实体功能.生成物体(生成的场景,目标节点,挂载属性同步器,rpc联机方法.wang_luo_id)
			生成时.emit(物体)
			生成了.emit()
	elif 方式==0:
		var 物体 = 实体功能.生成物体(生成的场景,目标节点,挂载属性同步器,rpc联机方法.wang_luo_id)
		生成时.emit(物体)
		生成了.emit()
	if 一次性==true:self.queue_free()
