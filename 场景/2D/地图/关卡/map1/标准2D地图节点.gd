extends Node2D

@export var 出生点2D坐标:Array[Vector2]=[]##可手动创建,也可以由出生点2D节点设置
signal 当有玩家进入时
signal 当创建房间时
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rpc联机方法.有人进来.connect(_当有玩家进入)
	rpc联机方法.创建了房间.connect(_当创建房间)
	if rpc联机方法.shi_fou_chuang_jian_le:
		call_deferred("_当创建房间")

func _当有玩家进入(pid:int):
	当有玩家进入时.emit()

func _当创建房间():
	当创建房间时.emit()
