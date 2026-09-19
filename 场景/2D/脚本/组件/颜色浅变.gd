extends Node
class_name 浅变颜色gd

@export var 浅变时长: float = 1.0
@export var 浅变颜色: Color
#@export_color_no_alpha var bug: Color = Color.RED
@export var 目标节点: CanvasItem  ## 空=父节点
@export var 自动填充目标节点为父级: bool = true
@export var 是否恢复: bool = false

var 父级 = get_parent()
var 原本颜色: Color
var 执行中: bool = false
var 当前动画: Tween

signal 当浅变开始时(物体:CanvasItem)
signal 当浅变中止时(物体:CanvasItem)
signal 当浅变结束时(物体:CanvasItem)
signal 当记录颜色时(物体:CanvasItem)


func 是否已执行() -> bool:
	if 执行中:
		return true   # 正在执行，阻止启动
	执行中 = true
	return false      # 未执行，允许启动


func 查询节点存在() -> bool:
	if 目标节点 == null and 自动填充目标节点为父级 == false:
		print("错误：目标节点为空且不允许自动填充")
		return false
	elif 自动填充目标节点为父级 == true and 目标节点 == null:
		获取节点()
	return 目标节点 != null


func 获取节点():
	if 目标节点 == null:
		父级=get_parent()
		目标节点 = 父级


func 记录初始颜色():
	if not 查询节点存在():
		return
	原本颜色 = 目标节点.modulate
	当记录颜色时.emit()
	print("记录初始颜色：", 原本颜色)


func 执行浅变():
	# 检查执行
	if 是否已执行():
		return
	
	# 检查节点存在
	if not 查询节点存在():
		执行中 = false  
		return
	
	当浅变开始时.emit()
	print("浅变开始")
	
	当前动画 = get_tree().create_tween()

	当前动画.tween_property(目标节点, "modulate",浅变颜色, 浅变时长)
	#当前动画.tween_property(目标节点, "modulate",Color.AQUA,2)
	当前动画.finished.connect(func():
		执行中 = false
		当前动画 = null
		当浅变结束时.emit(目标节点)
		print("浅变结束")
	)


func 中断浅变():
	if 当前动画 == null or not 当前动画.is_running():
		print("终止")
		return
	
	当前动画.kill()
	当前动画 = null
	执行中 = false
	
	if 是否恢复:
		目标节点.modulate = 原本颜色
	else:
		pass
	
	当浅变中止时.emit()
