extends Node


func _ready() -> void:
	
	#while self.get_tree().get_meta("pid")==null:
	#await get_tree().create_timer(5).timeout##等待类型设置
	#print(rpc联机方法.wang_luo_id,"...",self.get_parent().get_meta("pid"))
	if rpc联机方法.wang_luo_id!=self.get_parent().get_meta("pid"):return
	var cxt=CXT.new()
	var 摄像头 =cxt.FIND(get_tree().current_scene,"摄像头管理",-1,true)
	while 摄像头==null:
		摄像头 =cxt.FIND(get_tree().current_scene,"摄像头管理",-1,true)
		await get_tree().create_timer(0.1).timeout##等待类型设置
	摄像头.方式=1
	摄像头.目标缩放=0.7
	self.queue_free()
