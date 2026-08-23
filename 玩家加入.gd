extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Rpc联机方法.连上了.connect(_当连上了)

func _当连上了(id:int):
	实体功能.请求场景同步(id)
	pass
