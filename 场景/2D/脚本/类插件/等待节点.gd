extends Node
class_name 等待节点 
signal 等待结束后触发()
signal 等待开始触发()
signal 等待中触发()
@export var 等待时间 :float=0.2
@export var 每帧等待时间:float=0.02
var 已执行等待时间:float=0.0
func 执行():
	等待开始触发.emit()
	while 已执行等待时间>=等待时间:
		await get_tree().create_timer(每帧等待时间).timeout
		已执行等待时间+=每帧等待时间
		等待中触发.emit()
	等待结束后触发.emit()
	
