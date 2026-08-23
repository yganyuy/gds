extends Node
class_name 物体表#在全局变量中叫"全局物体表"  {这个是专门用来针对于物体的 映射 以及本地查找物体需要用到的 } 

var 物体对应id: Dictionary = {}
@export var 容许新物体为null: bool = true
@export var 工具: 生成物体 = null
@export var 启动调试功能:bool=false


signal 物体数变化了(新物体: Node, 物体id: int)

func 加入物体(新物体: Node = null, 加入物体的id: int = 1):
	if 新物体 == null and 容许新物体为null == false:
		return
	物体对应id[加入物体的id] = weakref(新物体)
	新物体.tree_exited.connect(当物体销毁.bind(加入物体的id))
	物体数变化时(新物体, 加入物体的id)

func 查找物体(id: int):
	if 物体对应id.has(id):
		var 物体 = 物体对应id[id]
		if is_instance_valid(物体):
			return 物体
		else:
			移除空数据(id)
			return null
	return null

func 移除物体(物体id: int):
	if 物体对应id.has(物体id):
		物体对应id.erase(物体id)
		打印字典(物体id)

func 当物体销毁(物体id: int):
	if 物体对应id.has(物体id):
		物体对应id.erase(物体id)
		打印字典(物体id)

func 移除空数据(物体id: int):
	if not 物体对应id.has(物体id):
		return null
	
	var 数据 = 物体对应id[物体id]
	var 物体: Node = null
	
	if 数据 is WeakRef:##WeakRef=一种弱引用需要转换一下才能当作对象
		物体 = 数据.get_ref()
	else:
		物体 = 数据
	
	if 物体 == null:
		移除物体(物体id)
		return null
	打印字典(物体id)
	return 物体

func 物体数变化时(新物体, 物体id):
	打印字典(物体id)
	物体数变化了.emit(新物体, 物体id)

func 打印字典(加入物体的id):
	if 工具 == null:
		工具 = 实体功能
		if 启动调试功能==false:
			return
	print(工具.服务还是客户, "服务端=1,客户端=2", "\n", 物体对应id, " ID:", 加入物体的id)
	print(获取所有ID())
	print(获取所有物体的场景路径映射())
	获取所有物体的场景路径映射()

func 获取所有ID() -> Array:
	print()
	return 物体对应id.keys()

func 获取所有物体的场景路径映射() -> Dictionary:
	var 映射: Dictionary = {}
	for id in 物体对应id.keys():
		var 数据 = 物体对应id[id]
		var 物体: Node = null
		
		# 将 WeakRef 转为真实节点
		if 数据 is WeakRef:
			物体 = 数据.get_ref()
		else:
			物体 = 数据
		
		# 如果节点无效或没有元数据，跳过
		if 物体 == null or not is_instance_valid(物体):
			continue
		if not 物体.has_meta("chang_jing_lu_jing"):
			continue
		
		映射[id] = 物体.get_meta("chang_jing_lu_jing")
	
	return 映射
