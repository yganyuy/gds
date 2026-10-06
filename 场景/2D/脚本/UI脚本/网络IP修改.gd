extends LineEdit

func _ready() -> void:
	text=rpc联机方法.ip


func _on_text_changed(new_text: String) -> void:##当文字被更改时 
	rpc联机方法.ip=new_text
	text=rpc联机方法.ip
