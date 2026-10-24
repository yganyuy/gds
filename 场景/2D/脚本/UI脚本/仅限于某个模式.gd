extends Node
class_name 仅限于
@export_enum("俯视角","2d跳跃","无") var 仅显示在模式上:int=0
@export_enum("安卓","窗户","无") var 仅显示在设备上:int=0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("android"):
		#print("当前运行在安卓设备上")
		if 仅显示在设备上!=0 and 仅显示在设备上!=2:self.get_parent().visible=false
	elif OS.has_feature("windows"):
		if 仅显示在设备上!=1 and 仅显示在设备上!=2:self.get_parent().visible=false
		#print("当前运行在 Windows 上")
	#await get_tree().create_timer(0.1).timeout
	if 玩家当前角色.玩家角色.size()>0:
		var 玩家=玩家当前角色.玩家角色[0]
		if  实体功能.查找器.FIND(玩家,"物理组件",-1,true)!=null :
			var 物理=实体功能.查找器.FIND(玩家,"物理组件",-1,true)
			if 仅显示在模式上==2:return
			if 物理.当前物理模式==0 and 仅显示在模式上!=1 :
				self.get_parent().visible=false
			if 物理.当前物理模式==1 and 仅显示在模式上!=0:
				self.get_parent().visible=false
