extends LineEdit



func _当信号触发(ip2:String):
	Rpc联机方法.ip=ip2
	print(ip2)	

func _on_text_changed(new_text: String) -> void:
	_当信号触发(new_text)
