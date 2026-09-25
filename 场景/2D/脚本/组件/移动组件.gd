extends Node
class_name 移动组件

## 最小速度 px/s [int]
@export var 最小速度: int = 0
## 最大速度 px/s [int]
@export var 最大速度: int = 300
## 加速度 px/s² [int]
@export var 加速度: int = 1000
## 减速度 px/s² [int]
@export var 减速度: int = 1500
## 引用的物理组件 [Node]
@export var 引用的物理组件: 物理组件 = null

var 当前输入方向: Vector2 = Vector2.ZERO
var 正在移动: bool = false

func _ready() -> void:
	if 引用的物理组件 == null:
		var 父节点 = get_parent()
		if 父节点:
			for 子节点 in 父节点.get_children():
				if 子节点 is 物理组件:
					引用的物理组件 = 子节点
					break
			if 引用的物理组件 == null:
				引用的物理组件 = 物理组件.new()
				父节点.add_child(引用的物理组件)

func _physics_process(delta: float) -> void:
	if 引用的物理组件 == null: return
	
	var 当前速度 = 引用的物理组件.速度向量
	
	if 正在移动:
		# 开始移动（不触发减速）
		var 目标速度 = 当前输入方向 * 最大速度
		
		# 【关键】根据物理组件的模式，决定移动组件干涉哪些轴
		if 引用的物理组件.当前物理模式 == 物理组件.物理模式.平台跳跃:
			# 平台跳跃：只接管水平（X轴），Y轴绝对不管，留给重力！
			当前速度.x = move_toward(当前速度.x, 目标速度.x, 加速度 * delta)
		else:
			# 俯视角/纯惯性：接管X和Y轴
			当前速度.x = move_toward(当前速度.x, 目标速度.x, 加速度 * delta)
			当前速度.y = move_toward(当前速度.y, 目标速度.y, 加速度 * delta)
		
	else:
		# 结束移动（触发减速）
		if 引用的物理组件.当前物理模式 == 物理组件.物理模式.平台跳跃:
			# 平台跳跃：只减速X轴，不能干扰Y轴的下落！
			当前速度.x = move_toward(当前速度.x, 0, 减速度 * delta)
			if abs(当前速度.x) <= 最小速度:
				当前速度.x = 0
		else:
			# 俯视角/纯惯性：减速X和Y
			当前速度.x = move_toward(当前速度.x, 0, 减速度 * delta)
			当前速度.y = move_toward(当前速度.y, 0, 减速度 * delta)
			if abs(当前速度.x) <= 最小速度:
				当前速度.x = 0
			if abs(当前速度.y) <= 最小速度:
				当前速度.y = 0
				
	引用的物理组件.速度向量 = 当前速度

func 执行移动 (输入向量: Vector2)->void:
	if 输入向量.length() > 0:
			当前输入方向 = 输入向量.normalized()
			正在移动 = true
	else:
		当前输入方向 = Vector2.ZERO

func 开始移动(输入向量: Vector2) -> void:
	if rpc联机方法.wang_luo_id==0:
		执行移动(输入向量)
	else :
		if  rpc联机方法.wang_luo_id != 1 :#触发以下分支必须是客户端 
			var id = self.get_parent().get_meta("id")#保证只能由客户端申请 
			rpc_id(1, "客户端发来的请求移动", id,输入向量) #发给服务端了让他移动 
			return
		if rpc联机方法.wang_luo_id == 1 :#触发以下分支必须是服务端
			执行移动(输入向量)
@rpc("any_peer","reliable")
func 客户端发来的请求移动 (id:int,输入向量:Vector2):#这条指令必须在服务端运行 
	var 弱引用 =全局物体表.查找物体(id)
	var 物体:Node= 弱引用.get_ref() if 弱引用 is WeakRef else 弱引用
	if 物体 == null: return
	if 物体.get_node_or_null("移动组件")!=null:
		物体.get_node("移动组件").开始移动(输入向量)#由于现在已经属于是服务端的这条指令所以在调用开始移动之后 开始移动那边是不会达成无限循环 


func 结束移动() -> void:
	if rpc联机方法.wang_luo_id == 0:
		正在移动 = false
	else:
		if rpc联机方法.wang_luo_id != 1:#客户端
			var id = self.get_parent().get_meta("id")
			rpc_id(1, "客户端发来的请求停止", id)
			return
		if rpc联机方法.wang_luo_id == 1:#服务端
			正在移动 = false
@rpc("any_peer", "reliable")
func 客户端发来的请求停止(id: int):
	if 实体功能 == null or 实体功能.服务还是客户 != 1:
		return
	var 弱引用 = 全局物体表.查找物体(id)
	var 物体: Node = 弱引用.get_ref() if 弱引用 is WeakRef else 弱引用
	if 物体 == null: return

	# 防作弊：只有物体主人能停
	var 发起者 = multiplayer.get_remote_sender_id()
	if 物体.get_meta("pid", -1) != 发起者:
		return

	var mc = 物体.get_node_or_null("移动组件")
	if mc != null:
		mc.正在移动 = false
