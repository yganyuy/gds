extends Node
class_name UI启用
@export var 修改ui:CanvasItem=null
signal 关掉了
signal 打开了

func 关掉():
	修改ui.visible=false
	关掉了.emit(修改ui)
func 打开():
	修改ui.visible=true
	打开了.emit(修改ui)
