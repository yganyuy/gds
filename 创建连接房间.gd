extends Button


func _ready():
	# 把“自己的信号”连接到“自己的函数”
	button_down.connect(_当信号触发)

func _当信号触发():
	Rpc联机方法.Chuang_jian_fang_jian()
	
