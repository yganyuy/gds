extends TextureProgressBar
@export var 玩家:Node=null
@export var 生命值组件:Node=null

func _ready() -> void:
	var aaa =CXT.new()
	while true:
		if 玩家==null:
			玩家=玩家当前角色.玩家角色[0]
			while 生命值组件==null:
				生命值组件=aaa.FIND(玩家,"生命组件",-1,false)
				#print("已经找到生命组件了 ")
				await get_tree().create_timer(0.02).timeout#延时触发 查找
		else :
			await get_tree().create_timer(0.02).timeout#延时触发 查找

func _process(_delta: float) -> void:
	if 生命值组件!=null:
		max_value=生命值组件.最大血量
		value=生命值组件.当前血量
