extends Node
## 移动组件 ⇄ 动画播放器 桥接
## 双通道驱动：
##   ① 信号 —— 单机/服务端即时响应，零延迟
##   ② 每帧检测 —— 客户端属性同步后的兜底，防止联机动画不同步
##
## 混合秒数统一由 玩家动画播放器 查 动画速度表.渐变时长，
## 本脚本不硬编码任何时长。

@export var 关联的移动组件_2d: 移动组件_2D = null
@export var 关联的动画播放器: AnimationPlayer = null
@export var 动画名_站立: String = "站立"
@export var 动画名_移动: String = "移动"
@export var 动画名_跳跃开始: String = "跳跃_起跳"
@export var 需要翻转的节点: Node2D = null
@export var 调试: bool = false

var _当前朝向: int = 1          ## 1=右，-1=左
var _等待落地: bool = false     ## 取消跳跃后仍在空中，等落地再切地面动画
var _上次移动: bool = false
var _上次跳跃: bool = false

#=============================== 初始化 ===============================
func _ready() -> void:
	await get_tree().process_frame
	_自动查找依赖()
	if 关联的移动组件_2d == null or 关联的动画播放器 == null:
		push_warning("[移动动画关联] 依赖查找失败，禁用")
		set_process(false)
		return
	_连接信号()
	_上次移动 = 关联的移动组件_2d.正在移动
	_上次跳跃 = 关联的移动组件_2d.正在跳跃
	_刷新默认动画()
	if 调试:
		print("[移动动画关联] 已就绪，动画数=", 关联的动画播放器.get_animation_list().size())

func _自动查找依赖() -> void:
	var 父 := get_parent()
	if 父 == null: 父 = self

	if 关联的移动组件_2d == null:
		var n1 := 父.get_node_or_null("移动组件")
		if n1 is 移动组件_2D:
			关联的移动组件_2d = n1
		if 关联的移动组件_2d == null:
			var cxt := CXT.new()
			关联的移动组件_2d = cxt.FIND(父, "移动组件_2D", -1, true)

	if 关联的动画播放器 == null:
		var n2 := 父.get_node_or_null("骨骼动画序列/mi/动画播放器")
		if n2 is AnimationPlayer:
			关联的动画播放器 = n2
		if 关联的动画播放器 == null:
			var cxt2 := CXT.new()
			关联的动画播放器 = cxt2.FIND(父, "AnimationPlayer", -1, false)

	if 需要翻转的节点 == null:
		需要翻转的节点 = 父 as Node2D

func _连接信号() -> void:
	var mc := 关联的移动组件_2d
	if not mc.移动开始时.is_connected(_on_移动开始):
		mc.移动开始时.connect(_on_移动开始)
	if not mc.移动结束时.is_connected(_on_移动结束):
		mc.移动结束时.connect(_on_移动结束)
	if not mc.跳跃开始时.is_connected(_on_跳跃开始):
		mc.跳跃开始时.connect(_on_跳跃开始)
	if not mc.跳跃结束时.is_connected(_on_跳跃结束):
		mc.跳跃结束时.connect(_on_跳跃结束)

#=============================== 信号回调 ===============================
func _on_移动开始(_移动状态: bool, 跳跃状态: bool) -> void:
	_上次移动 = true
	_上次跳跃 = 跳跃状态
	if 调试: print("[移动动画关联] 移动开始 跳跃=", 跳跃状态)
	if 跳跃状态: return
	_播放(动画名_移动)

func _on_移动结束(_移动状态: bool, 跳跃状态: bool) -> void:
	_上次移动 = false
	_上次跳跃 = 跳跃状态
	var 在地面 := _在地面()
	if 调试: print("[移动动画关联] 移动结束 跳跃=", 跳跃状态, " 在地面=", 在地面)
	# 只要在地面，不管跳跃标记如何都切到地面动画
	if 在地面:
		_等待落地 = false
		_播放(动画名_站立)
	else:
		# 空中结束移动 → 保留跳跃姿势，落地后由 _process 恢复
		_等待落地 = 跳跃状态

func _on_跳跃开始(移动状态: bool, _跳跃状态: bool) -> void:
	_上次移动 = 移动状态
	_上次跳跃 = true
	_等待落地 = false
	if 调试: print("[移动动画关联] 跳跃开始")
	_播放(动画名_跳跃开始)

func _on_跳跃结束(移动状态: bool, _跳跃状态: bool) -> void:
	_上次移动 = 移动状态
	_上次跳跃 = false
	if _在地面():
		_等待落地 = false
		if 调试: print("[移动动画关联] 跳跃结束（已落地）")
		_播放(动画名_移动 if 移动状态 else 动画名_站立)
	else:
		_等待落地 = true
		if 调试: print("[移动动画关联] 跳跃结束（仍在空中，等待落地）")

#=============================== 每帧兜底 ===============================
func _process(_delta: float) -> void:
	if 关联的移动组件_2d == null: return
	var mc := 关联的移动组件_2d

	# ① 客户端属性同步后 / 信号漏发时
	if mc.正在移动 != _上次移动 or mc.正在跳跃 != _上次跳跃:
		var 旧移动 := _上次移动
		var 旧跳跃 := _上次跳跃
		_上次移动 = mc.正在移动
		_上次跳跃 = mc.正在跳跃

		var 上升 := mc.正在跳跃 and not 旧跳跃
		var 落下 := not mc.正在跳跃 and 旧跳跃
		var 移动变化 := mc.正在移动 != 旧移动

		if 上升:
			_等待落地 = false
			_播放(动画名_跳跃开始)
		elif 落下:
			if _在地面():
				_等待落地 = false
				_播放(动画名_移动 if mc.正在移动 else 动画名_站立)
			else:
				_等待落地 = true
		elif 移动变化 and not mc.正在跳跃:
			_播放(动画名_移动 if mc.正在移动 else 动画名_站立)

	# ② 等待落地恢复
	if _等待落地 and _在地面():
		_等待落地 = false
		_播放(动画名_移动 if mc.正在移动 else 动画名_站立)

	# ③ 方向翻转
	if 需要翻转的节点 != null:
		var 输入x: float = mc.当前输入方向.x
		if abs(输入x) > 0.01:
			var 新朝向 := 1 if 输入x > 0.0 else -1
			if 新朝向 != _当前朝向:
				_当前朝向 = 新朝向
				var sx: float = abs(需要翻转的节点.scale.x)
				需要翻转的节点.scale.x = sx * 新朝向

#=============================== 工具 ===============================
func _刷新默认动画() -> void:
	var mc := 关联的移动组件_2d
	if mc == null: return
	if mc.正在跳跃 and not _在地面():
		_播放(动画名_跳跃开始, 0.0)   # 初始化硬切
	elif mc.正在移动:
		_播放(动画名_移动, 0.0)
	else:
		_播放(动画名_站立, 0.0)

func _在地面() -> bool:
	if 关联的移动组件_2d == null or 关联的移动组件_2d.引用的物理组件 == null:
		return true
	var 实体 = 关联的移动组件_2d.引用的物理组件.目标节点
	if 实体 is CharacterBody2D:
		return 实体.is_on_floor()
	return true

## 混合秒数 -1 = 查渐变表；0 = 硬切；> 0 = 强制用该秒数
func _播放(动画名: String, 混合秒数: float = -1.0) -> void:
	if 关联的动画播放器 == null: return
	if not 关联的动画播放器.has_animation(动画名):
		if 调试: push_warning("[移动动画关联] 找不到动画: " + 动画名)
		return

	if 关联的动画播放器 is 玩家动画播放器:
		(关联的动画播放器 as 玩家动画播放器).播放动画(动画名, true, 0.0, 混合秒数)
		return

	# 回退：非 玩家动画播放器 时的最简实现
	if 关联的动画播放器.current_animation == 动画名 \
		and 关联的动画播放器.is_playing():
		return
	关联的动画播放器.speed_scale = 1.0
	if 混合秒数 > 0.0:
		关联的动画播放器.play(动画名, 混合秒数)
	else:
		关联的动画播放器.play(动画名)
	if 调试: print("[移动动画关联] play(", 动画名, ", blend=", 混合秒数, ") 回退模式")
