extends Node
@export var 条件:String=""
signal 触发信号真()
signal 触发信号假()
func 信号():
	var 实例化后的条件 = Expression.new()##创建的这个新的量可以让条件那种文本变为真正可以被读取的代码
	var 错误 = 实例化后的条件.parse(条件)##用来判断这个条件是否可以被读取
	if 错误 != OK:
		print("条件解析失败: " + 实例化后的条件.get_error_text())##里面会打印出报错的原因
		return
	var 结果 = 实例化后的条件.execute()##这是布尔值它返回的是否达成条件
	if 结果==true:
		触发信号真.emit()
	else:
		触发信号假.emit()
