extends TextureButton

@onready var control: Control = $".."
#@export var 生成素材:PackedScene=null
#@export var 节点:Node2D=null

signal 成功创建房间时()
signal 加入房间时()

func _on_button_down() -> void:
	
	if name=="创建房间":
		rpc联机方法.Chuang_jian_fang_jian()
		while  rpc联机方法.shi_fou_chuang_jian_le==false:#保持等待直到房间被正确创建 
			await get_tree().create_timer(1).timeout
		成功创建房间时.emit()
	if name=="加入房间":
		rpc联机方法.Jia_ru_fang_jian()
		while  rpc联机方法.shi_fou_jia_ru_fang_jian_le==false:#保持等待直到房间被正确加入 
			await get_tree().create_timer(1).timeout
		加入房间时.emit()
	
	#print("1",rpc联机方法.Chuang_jian_fang_jian)
	#print("2",rpc联机方法.Jia_ru_fang_jian)
	
	await get_tree().create_timer(0.1).timeout
	
	if control ==null:
		print("control==null")
		return
	实体功能.类型判断()
	
	await get_tree().create_timer(0.5).timeout
	if 实体功能.服务还是客户!=1:
			实体功能.场景同步器.请求场景同步(rpc联机方法.wang_luo_id)
	
	if 实体功能.服务还是客户!=0:
		control.visible=false#设置这个控件隐藏 
	
