extends Node
class_name UI启用
signal 设置好了(物体:CanvasItem)
@export var 设置节点:CanvasItem=null

func 启用ui(物体:CanvasItem):
	if 设置节点!=null:
		物体=设置节点
	物体.visible=true
	设置好了.emit(物体)
func 关闭ui(物体:CanvasItem):
	if 设置节点!=null:
		物体=设置节点
	物体.visible=false
	设置好了.emit(物体)
