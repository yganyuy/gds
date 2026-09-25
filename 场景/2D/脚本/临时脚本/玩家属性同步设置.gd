extends Node

func _ready() -> void:
	var 属性同步:String="属性同步"
	var 物体f:Node=null
	while true:
		
		if 查找节点.查找节点(self.get_parent(),属性同步)==null:
			await get_tree().create_timer(0.1).timeout
		else:
			物体f=查找节点.查找节点(self.get_parent(),属性同步)
			break
	#像是要设置的属性同步全写到下面这将会在第一次默认时进行设置 
	物体f.同步方式=1
	物体f.次每秒=120
	
	
