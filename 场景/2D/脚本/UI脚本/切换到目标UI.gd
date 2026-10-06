extends Node
class_name 切换到目标UI
#@export var 目标UI场景:PackedScene=null
@export var 目标UI场景:String=""

func 执行切UI():
#	if 目标UI场景!=null:
#		UI管理.切换UI(目标UI场景.resource_path)
	if 目标UI场景!="res://" and 目标UI场景!="":
		UI管理.切换UI(目标UI场景)
	
