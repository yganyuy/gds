extends Node
class_name 切换到目标UI
#@export var 目标UI场景:PackedScene=null
@export var 备用方法:String=""

func 执行切UI():
#	if 目标UI场景!=null:
#		UI管理.切换UI(目标UI场景.resource_path)
	if 备用方法!="res://" and 备用方法!="":
		UI管理.切换UI(备用方法)
	
