extends TextureButton

var 自身:Node=self




func 创建房间():
	rpc联机方法.Chuang_jian_fang_jian()
	
	
	


func 加入房间():
	rpc联机方法.Jia_ru_fang_jian()
	
	
	
	




func _on_button_down() -> void:
	if 自身.name=="创建房间":
		创建房间()
	elif 自身.name=="加入房间":
		加入房间()
