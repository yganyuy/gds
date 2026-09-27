extends Node
class_name 查找组件名物体 ##注意一下其中这个CXT插件是一个C++模块 

@export var 查找名 :String="属性同步"
@export var 查找物体:Node=null
@export var 查找深度:int=-1##-1=历遍所有子节点,x>=0指定查找深度子节点 
var 结果:Node = null
var 查找器 = CXT.new()
signal 输出节点(node:Node)


func _ready() -> void:
	if 查找物体==null:查找物体=self.get_parent()
	结果 = 查找器.FIND(查找物体, 查找名, 1, true)
	while true:
		if 结果!=null:
			输出节点.emit(结果)
			break
		else:
			await get_tree().create_timer(0.1).timeout
			结果 = 查找器.FIND(查找物体, 查找名, 1, true)
			
