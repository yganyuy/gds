extends Node
class_name 玩家_子
@export var 是玩家吗:bool=true
@export var 玩家节点:Node=null ##null=父节点

func _ready() -> void:
	if 是玩家吗==false:
		return
	
	if 玩家节点!=null and 玩家当前角色.玩家角色.has(玩家节点)==true:
		print("ppppppppppppppppppppppppp",玩家当前角色.玩家角色)
		return
	else :
		if 玩家节点==null:
			await get_tree().create_timer(0.1).timeout##等待类型设置
			玩家节点=self.get_parent()
		if rpc联机方法.wang_luo!=null:
			if rpc联机方法.wang_luo_id!=玩家节点.get_meta("pid"):
				return
		if 玩家当前角色.玩家角色.has(玩家节点)==false:
			#玩家当前角色.玩家角色.append(玩家节点)#append=在末尾插入
			玩家当前角色.玩家角色.insert(0,玩家节点)
		print("ppppppppppppppppppppppppp",玩家当前角色.玩家角色)
	
