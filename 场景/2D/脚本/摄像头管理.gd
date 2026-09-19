extends Node
class_name 摄像头管理
@export_enum("仅跟踪一个玩家角色","不跟踪角色而是固定") var 方式: int = 0
@export var 摄像头缩放:float=2.7
var 摄像头:Camera2D=null


func _ready() -> void:
	摄像头=Camera2D.new()
	self.add_child(摄像头)
	#while true:
func _physics_process(_delta:float):
		if 玩家当前角色.玩家角色.size()>0 and 摄像头!=null:
			摄像头.position=玩家当前角色.玩家角色[玩家当前角色.玩家角色.size()-1].position
			摄像头.zoom=Vector2(摄像头缩放,摄像头缩放)
