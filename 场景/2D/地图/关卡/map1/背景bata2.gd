extends Node2D

func _ready():
	print("=== 开始测试二维表 Table2D ===")
	
	# 1. 实例化我们的通用二维表
	var 表 = Table2D.new()
	#表.load_from_json("res://存档.json")##读取表格 
	#print(表.get_value("a0","攻击力"))
	表.add_column("攻击力","int", "0")##新建一列 
	表.add_column("sb","bool", "true")##新建一列 
	var i=0
	while i<33:
		#表.remove_row("a"+str(i))##从第x行移除 
		表.add_row("a"+str(i),[])##新建一行 
		i+=1
	 
	表.save_to_json("res://存档.json")##保存文件 
	#print(表.get_value("1","攻击力"))
	print("=== 结束测试二维表 Table2D ===")
