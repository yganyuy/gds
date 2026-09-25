extends Node

func _ready():
	# 英文类名 CXT
	var 查找器 = CXT.new()
	print("CXT 实例化成功！")
	
	# 英文方法名 FIND
	var 结果 = 查找器.FIND(self, "生命组件", -1, true)
	if 结果:
		print("查找到了：", 结果)
	else:
		print("没找到")
