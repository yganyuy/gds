extends Node

# ================= 配置区 =================
# 暴露变量，方便在编辑器里把 C++ 容器节点拖进来
# 注意：类型必须是 C++ 注册的类名 "MaterialContainer"
@export var 素材容器: MaterialContainer

# 物品数据，在编辑器里为每个拾取物单独填写
@export var 物品: PackedScene = null
@export var 物品体积: float = 10.0                  # 单个占容
@export var 拾取数量: int = 1                       # 拾取数量
@export var 丢弃:bool=false
@export var new_box:=false

func _当拾取时():
	# 判断进入的是不是玩家（确保玩家在编辑器的"节点"->"分组"里被加入了 "玩家" 组）
	#if not 进入的物体.is_in_group("玩家"):
		#return
		
	# 安全检查：确保容器引用没丢
	if not 素材容器:
		#push_warning("【拾取组件】没有绑定 MaterialContainer 容器！")
		if new_box==true:
			var 新建容器=Material.new()
			素材容器=新建容器
		else:
			print("Error null_box!")
		return
		
	# 调用 C++ 的方法，向容器内添加物品
	# 注意：这里的 add_material 是 C++ 注册的英文方法名，不能改
	# 参数依次为：路径、单个体积、数量
	var DSz:String =物品.resource_path
	if 丢弃==true:
		if 素材容器.find_material(DSz)!="":
			素材容器.remove_material(DSz,拾取数量)
			print("丢了")
	else :
		#if 素材容器.current_capacity<素材容器.max_capacity:
			素材容器.add_material(DSz, 物品体积, 拾取数量)
			print("[拾取] 拾取了: ", 物品.resource_path, " x", 拾取数量)
	# 拾取成功，播放音效/动画后销毁自身
	
	#queue_free()


func _on_material_container_backpack_full(current: float, max: float) -> void:
	print(current,max)
