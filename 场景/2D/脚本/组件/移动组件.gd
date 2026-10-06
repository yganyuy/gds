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
## 跳跃高度px/次 [float]
@export var 跳跃最大高度:float=100##这里的设计思路是达到最大高度或者是它取消输入后就取消修改向上的物理速度 
## 跳跃段数:int
@export var  跳跃段数:int=1


var 当前输入方向: Vector2 = Vector2.ZERO
var 正在移动: bool = false
var 当前跳跃段数:int=0
var 正在跳跃:bool=false
var 父节点 :Node=null
var 初始化 :bool=false

func _ready() -> void:
	if 父节点 == null:
		while true :
			if self.get_parent()!=null:
				父节点=self.get_parent()
				break
	if 引用的物理组件==null:
		print(self,"你并没有手动引用物理组件那么我就自己创建一个!")
		var 创建的物理组件=物理组件.new()
		self.add_child(创建的物理组件)
		引用的物理组件=创建的物理组件
		创建的物理组件.目标节点=父节点
	初始化=true

func _physics_process(delta: float) -> void:
	if 引用的物理组件 == null: return
	if 初始化==false:return
	
	# ★ 落地时重置跳跃段数与正在跳跃标记
	_检测落地()
	
	var 当前速度 = 引用的物理组件.速度向量
	if rpc联机方法.wang_luo_id!=1 and rpc联机方法.wang_luo_id!=0:return##保证在服务端运行 
	if 正在移动:
		# 开始移动（不触发减速）
		var 目标速度 = 当前输入方向 * 最大速度
		
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

#____________________________以下是关于移动的____________________________
func 执行移动 (输入向量: Vector2)->void:
	if 输入向量.length() > 0:
			当前输入方向 = 输入向量.normalized()
			正在移动 = true
	else:
		当前输入方向 = Vector2.ZERO

func 开始移动(输入向量: Vector2) -> void:
	
	if rpc联机方法.wang_luo_id==0:执行移动(输入向量)
	else :
		if  rpc联机方法.wang_luo_id != 1 :#触发以下分支必须是客户端 
			if 父节点 ==null:return
			var id = 父节点.get_meta("id")#保证只能由客户端申请 
			rpc_id(1, "客户端发来的请求移动",id,输入向量) #发给服务端了让他移动 
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
			var id = 父节点.get_meta("id")
			rpc_id(1, "客户端发来的请求停止", id)
			return
		if rpc联机方法.wang_luo_id == 1:#服务端
			正在移动 = false

@rpc("any_peer", "reliable")
func 客户端发来的请求停止(id: int):
	if 实体功能 == null or 实体功能.服务还是客户 != 1:return
	var 弱引用 = 全局物体表.查找物体(id)
	var 物体: Node = 弱引用.get_ref() if 弱引用 is WeakRef else 弱引用
	if 物体 == null: return

	## 防作弊：只有物体主人能停
	#var 发起者 = multiplayer.get_remote_sender_id()
	#if 物体.get_meta("pid", -1) != 发起者:
		#return

	var mc = 物体.get_node_or_null("移动组件")
	if mc != null:
		mc.正在移动 = false
#__________________________以下是关于跳跃以及其他的_______________________

# ★ 内部：落地检测（每帧调用，重置段数）
func _检测落地() -> void:
	if 引用的物理组件 == null: return
	var 实体 = 引用的物理组件.目标节点
	if 实体 == null: return
	if not (实体 is CharacterBody2D): return
	if 实体.is_on_floor() and 引用的物理组件.速度向量.y >= 0:
		当前跳跃段数 = 0
		正在跳跃 = false

# ★ 内部：根据当前重力计算达到 跳跃最大高度 所需的初速度（负值，向上）
func _计算跳跃初速度() -> float:
	if 引用的物理组件 == null:
		return 0.0
	var 重力值 = 引用的物理组件.重力
	if 重力值 <= 0.0:
		return 0.0
	return -sqrt(2.0 * 重力值 * 跳跃最大高度)

# ★ 内部：真正执行一次跳跃（只在服务端/单机调用）
func _执行跳跃() -> void:
	if 引用的物理组件 == null: return
	if 当前跳跃段数 >= 跳跃段数: return
	当前跳跃段数 += 1
	正在跳跃 = true
	引用的物理组件.速度向量.y = _计算跳跃初速度()

# ★ 内部：松手取消上升（保留一半上升速度，和注释里写的一致）
func _执行取消跳跃() -> void:
	if 引用的物理组件 == null: return
	if 正在跳跃 and 引用的物理组件.速度向量.y < 0:
		引用的物理组件.速度向量.y *= 0.5
	正在跳跃 = false

# ★ 对外入口：开始跳跃（单机/服务端/客户端统一走这里）
func 开始跳跃() -> void:
	if rpc联机方法.wang_luo_id == 0:
		_执行跳跃()
	else:
		if rpc联机方法.wang_luo_id != 1:  # 客户端
			var id = self.get_parent().get_meta("id")
			rpc_id(1, "客户端发来的请求跳跃", id)
			return
		if rpc联机方法.wang_luo_id == 1:  # 服务端
			_执行跳跃()

# ★ 对外入口：松手取消跳跃
func 取消跳跃() -> void:
	if rpc联机方法.wang_luo_id == 0:
		_执行取消跳跃()
	else:
		if rpc联机方法.wang_luo_id != 1:  # 客户端
			var id = self.get_parent().get_meta("id")
			rpc_id(1, "客户端发来的请求取消跳跃", id)
			return
		if rpc联机方法.wang_luo_id == 1:  # 服务端
			_执行取消跳跃()

@rpc("any_peer", "reliable")
func 客户端发来的请求跳跃(id: int):
	if 实体功能 == null or 实体功能.服务还是客户 != 1:
		return
	var 弱引用 = 全局物体表.查找物体(id)
	var 物体: Node = 弱引用.get_ref() if 弱引用 is WeakRef else 弱引用
	if 物体 == null: return

	## 防作弊：只有物体主人能跳
	#var 发起者 = multiplayer.get_remote_sender_id()
	#if 物体.get_meta("pid", -1) != 发起者:
		#return

	var mc = 物体.get_node_or_null("移动组件")
	if mc != null:
		mc._执行跳跃()

@rpc("any_peer", "reliable")
func 客户端发来的请求取消跳跃(id: int):
	if 实体功能 == null or 实体功能.服务还是客户 != 1:
		return
	var 弱引用 = 全局物体表.查找物体(id)
	var 物体: Node = 弱引用.get_ref() if 弱引用 is WeakRef else 弱引用
	if 物体 == null: return
#
	#var 发起者 = multiplayer.get_remote_sender_id()##防作弊  确认归属者 
	#if 物体.get_meta("pid", -1) != 发起者:
		#return

	var mc = 物体.get_node_or_null("移动组件")
	if mc != null:
		mc._执行取消跳跃()
