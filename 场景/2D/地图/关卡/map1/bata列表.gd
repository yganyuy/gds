extends Node

func _ready():
	var 列表 = ItemTableManagerGodot.new()
	var mm=Table2D.new()
	mm.add_child(self)
	# 【重要】尽量用 user:// 测试，因为 res:// 在 Godot 中通常是只读的
	# 如果你想在编辑器里直接改 res:// 下的文件，Godot 默认是会拦截的
	var 路径 = "res://src/item_table/items.json"
	
	# 如果文件不存在
	if not FileAccess.file_exists(路径):
		printerr("null")
	
	# 加一行
	
	var aaa:int=1
	while aaa<10:
		var ok2 = 列表.append_row_to_json(路径, str(aaa),str(aaa),aaa,)
		print("加行成功: ", ok2, " 错误信息: ", 列表.get_last_error())
		aaa+=1
	# 重新读取验证
	var ok3 = 列表.load_from_json(路径)
	print("重新加载成功: ", ok3)
	print("测试剑价格: ", 列表.get_price("测试剑"))
