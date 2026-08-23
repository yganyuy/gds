extends Node2D

# ==========================================
# 第一部分：字典管理核心
# ==========================================

# 字典：用来存储 ID → 物体的对应关系
var 物体字典 = {}

# ID计数器：每次使用后+1，保证ID唯一
var id计数器 = 0

# 用来测试的物体场景（你可以拖入一个场景文件）
@export var 测试物体场景: PackedScene = null
@export var 生成位置: Vector2 = Vector2(100, 100)


# ==========================================
# 第二部分：生成物体并分配ID
# ==========================================

func _ready():
	# 测试：生成3个物体
	for i in range(3):
		生成物体()
	
	# 延迟后测试：通过ID查找物体
	await get_tree().create_timer(1.0).timeout
	测试查找物体()


func 生成物体():
	if 测试物体场景 == null:
		print("[错误] 没有设置测试物体场景")
		return
	
	# 1️⃣ ID计数器+1，生成新ID
	id计数器 += 1
	var 新ID = id计数器
	
	# 2️⃣ 创建物体实例
	var 新物体 = 测试物体场景.instantiate()
	
	# 3️⃣ 把ID存到物体的元数据中（给物体贴标签）
	新物体.set_meta("我的ID", 新ID)
	
	# 4️⃣ 设置位置（让它们排列开）
	if 新物体 is Node2D:
		新物体.position = 生成位置 + Vector2(新ID * 150, 0)
	
	# 5️⃣ 添加到场景
	add_child(新物体)
	
	# 6️⃣ 把 ID → 物体 的对应关系存入字典
	物体字典[新ID] = 新物体
	
	# 7️⃣ 监听销毁事件
	新物体.tree_exited.connect(_当物体销毁.bind(新ID))
	
	print("[生成] 物体 ID:", 新ID, " 物体:", 新物体.name, " 字典大小:", 物体字典.size())


# ==========================================
# 第三部分：通过ID查找物体
# ==========================================

func 通过ID查找物体(查找ID: int):
	# 方法1：直接从字典取
	if 物体字典.has(查找ID):
		var 物体 = 物体字典[查找ID]
		# 检查物体是否还有效（没被销毁）
		if is_instance_valid(物体):
			return 物体
		else:
			# 物体已被销毁，清理字典
			物体字典.erase(查找ID)
			return null
	else:
		return null


func 测试查找物体():
	print("========== 开始查找测试 ==========")
	
	# 查找 ID = 1 的物体
	var 物体1 = 通过ID查找物体(1)
	if 物体1 != null:
		print("[查找] 找到 ID=1 的物体:", 物体1.name, " 位置:", 物体1.position)
		# 修改它
		物体1.position += Vector2(0, 50)
		物体1.scale = Vector2(1.5, 1.5)
		print("  已修改 ID=1 的物体")
	else:
		print("[查找] 没有找到 ID=1 的物体")
	
	# 查找 ID = 2 的物体
	var 物体2 = 通过ID查找物体(2)
	if 物体2 != null:
		print("[查找] 找到 ID=2 的物体:", 物体2.name, " 位置:", 物体2.position)
	else:
		print("[查找] 没有找到 ID=2 的物体")
	
	# 查找一个不存在的ID
	var 物体99 = 通过ID查找物体(99)
	if 物体99 != null:
		print("[查找] 找到 ID=99 的物体:", 物体99.name)
	else:
		print("[查找] ID=99 不存在")


# ==========================================
# 第四部分：物体销毁时自动清理
# ==========================================

func _当物体销毁(物体ID: int):
	if 物体字典.has(物体ID):
		物体字典.erase(物体ID)
		print("[销毁] 物体 ID:", 物体ID, " 已从字典移除，当前字典大小:", 物体字典.size())
	else:
		print("[销毁] 物体 ID:", 物体ID, " 不在字典中")


# ==========================================
# 第五部分：手动测试按钮
# ==========================================

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_G:  # 按 G 键生成
				生成物体()
				print("当前字典:", 物体字典.keys())
			
			KEY_F:  # 按 F 键查找
				测试查找物体()
			
			KEY_D:  # 按 D 键删除第一个物体
				删除第一个物体()
			
			KEY_P:  # 按 P 键打印所有物体
				打印所有物体()


func 删除第一个物体():
	if 物体字典.is_empty():
		print("[删除] 字典为空，没有物体可删除")
		return
	
	# 获取第一个ID
	var 第一个ID = 物体字典.keys()[0]
	var 物体 = 物体字典[第一个ID]
	
	if is_instance_valid(物体):
		物体.queue_free()
		print("[删除] 已请求删除 ID:", 第一个ID)
	else:
		物体字典.erase(第一个ID)
		print("[删除] ID:", 第一个ID, " 已无效，直接清理")


func 打印所有物体():
	print("========== 所有物体 ==========")
	print("字典大小:", 物体字典.size())
	for id in 物体字典:
		var 物体 = 物体字典[id]
		if is_instance_valid(物体):
			print("  ID:", id, " → ", 物体.name, " 位置:", 物体.position)
		else:
			print("  ID:", id, " → 已销毁（待清理）")
	print("=================================")
