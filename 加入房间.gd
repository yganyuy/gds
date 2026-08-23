extends Button


func _ready():
	# 把“自己的信号”连接到“自己的函数”
	button_down.connect(_当信号触发)

func _当信号触发():
	实体功能.清理本地所有物体()
	Rpc联机方法.Jia_ru_fang_jian()
	await Rpc联机方法.连上了
	await get_tree().create_timer(1.0).timeout
	# 3. 请求场景同步
#	实体功能.请求场景同步()
	print("ufhsufseufhaowea")
