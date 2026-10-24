extends Node
class_name 摄像头管理

#=============================== 模式 ===============================
@export_enum("固定视角", "追踪玩家", "自由视角") var 方式: int = 1
@export var 目标缩放: float = 2.7
@export var 缩放平滑: float = 8.0
@export var 跟随平滑: float = 6.0

@export_group("固定视角")
@export var 固定位置: Vector2 = Vector2.ZERO

@export_group("边界（可选）")
@export var 启用边界: bool = false
@export var 左边界: int = -1000
@export var 右边界: int = 1000
@export var 上边界: int = -1000
@export var 下边界: int = 1000

@export_group("自由视角")
@export var 自由最小缩放: float = 0.5
@export var 自由最大缩放: float = 5.0
@export var 自由拖拽按钮: MouseButton = MOUSE_BUTTON_LEFT
@export var 自由滚轮步进: float = 0.12
@export var 自由启用鼠标: bool = true

@export_group("调试")
@export var 调试: bool = false
@export var 启用F1诊断: bool = true

#=============================== 状态 ===============================
var 摄像头: Camera2D = null
var 当前目标: Node2D = null

var _实际目标缩放: float = 2.7
var _自由拖拽中: bool = false

# 触摸手势状态（安卓）
var _触摸点: Dictionary = {}
var _上次双指距离: float = 0.0

# 调试节流
var _上次状态日志: float = 0.0
var _上次移动日志帧: int = -1

#=============================== 生命周期 ===============================
func _ready() -> void:
	自由拖拽按钮 = MOUSE_BUTTON_LEFT   # 左键 / 单指
	_实际目标缩放 = 目标缩放
	_确保摄像头()
	应用方式()
	if 调试:
		await get_tree().create_timer(1.0).timeout
		一键诊断()

func _process(delta: float) -> void:
	if 摄像头 == null: return

	match 方式:
		0:
			pass
		1:
			_process_追踪()
		2:
			# 自由模式：关闭位置平滑（小位移会被平滑稀释）
			if 摄像头.position_smoothing_enabled:
				摄像头.position_smoothing_enabled = false

	# 缩放平滑（所有模式通用）
	if 缩放平滑 > 0.0:
		var 当前z := 摄像头.zoom.x
		var 新z := lerpf(当前z, _实际目标缩放, clampf(缩放平滑 * delta, 0.0, 1.0))
		摄像头.zoom = Vector2(新z, 新z)
	else:
		摄像头.zoom = Vector2(_实际目标缩放, _实际目标缩放)

	# 调试：每 0.5 秒打印状态
	if 调试:
		_上次状态日志 += delta
		if _上次状态日志 >= 0.5:
			_上次状态日志 = 0.0
			print("[摄像-状态] 方式=", 方式,
				" 位置=", 摄像头.global_position,
				" zoom=", 摄像头.zoom.x,
				" 拖拽中=", _自由拖拽中,
				" 触摸点数=", _触摸点.size())

#=============================== 摄像头准备 ===============================
func _确保摄像头() -> void:
	for c in get_children():
		if c is Camera2D:
			摄像头 = c
			break
	if 摄像头 == null:
		摄像头 = Camera2D.new()
		摄像头.name = "自动摄像头"
		add_child(摄像头)

	摄像头.position_smoothing_enabled = 跟随平滑 > 0.0
	摄像头.position_smoothing_speed = 跟随平滑

	if 启用边界:
		摄像头.limit_left   = 左边界
		摄像头.limit_right  = 右边界
		摄像头.limit_top    = 上边界
		摄像头.limit_bottom = 下边界
	else:
		摄像头.limit_left   = -10000000
		摄像头.limit_right  = 10000000
		摄像头.limit_top    = -10000000
		摄像头.limit_bottom = 10000000

	摄像头.zoom = Vector2(_实际目标缩放, _实际目标缩放)
	摄像头.enabled = true

#=============================== 模式切换 ===============================
func 设置方式(新方式: int) -> void:
	方式 = 新方式
	应用方式()

func 应用方式() -> void:
	if 摄像头 == null: return
	match 方式:
		0:
			_设置目标(null)
			摄像头.global_position = 固定位置
			摄像头.reset_smoothing()
			_实际目标缩放 = 目标缩放
		1:
			_自动选择目标(true)
			_实际目标缩放 = 目标缩放
			# 追踪模式恢复平滑
			摄像头.position_smoothing_enabled = 跟随平滑 > 0.0
			摄像头.position_smoothing_speed = 跟随平滑
		2:
			_自动选择目标(true)
			_实际目标缩放 = clampf(目标缩放, 自由最小缩放, 自由最大缩放)
			# 自由模式关闭平滑（下一帧会自动切回）

#=============================== 追踪 ===============================
func _process_追踪() -> void:
	if 当前目标 == null or not is_instance_valid(当前目标):
		_自动选择目标(false)
		return
	if 玩家当前角色 != null:
		var arr = 玩家当前角色.玩家角色
		if arr != null and arr.size() > 0:
			var 最新 = arr[arr.size() - 1]
			if is_instance_valid(最新) and 最新 is Node2D and 最新 != 当前目标:
				_设置目标(最新)
	if 当前目标 != null and is_instance_valid(当前目标):
		摄像头.global_position = 当前目标.global_position

func _设置目标(节点: Node2D) -> void:
	当前目标 = 节点

func _自动选择目标(瞬间: bool = false) -> void:
	if 玩家当前角色 == null:
		_设置目标(null); return
	var arr = 玩家当前角色.玩家角色
	if arr == null or arr.size() <= 0:
		_设置目标(null); return
	var 最新 = arr[arr.size() - 1]
	if not is_instance_valid(最新) or not (最新 is Node2D):
		_设置目标(null); return
	if 最新 != 当前目标:
		_设置目标(最新)
		if 瞬间 and 摄像头 != null:
			摄像头.global_position = 最新.global_position
			摄像头.reset_smoothing()

#=============================== 输入 ===============================
## 用 _unhandled_input：让 UI（摇杆/按钮）优先，避免拖视角时误触 UI
func _unhandled_input(event: InputEvent) -> void:
	# F1 一键诊断
	if 启用F1诊断 and event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		一键诊断()
		get_viewport().set_input_as_handled()
		return

	if 方式 != 2: return
	if not 自由启用鼠标: return
	if 摄像头 == null: return

	# 自由模式关闭平滑
	if 摄像头.position_smoothing_enabled:
		摄像头.position_smoothing_enabled = false

	# ============================================================
	# 触摸事件（安卓）——优先
	# ============================================================
	if event is InputEventScreenTouch:
		if event.pressed:
			_触摸点[event.index] = event.position
		else:
			_触摸点.erase(event.index)
		if _触摸点.size() < 2:
			_上次双指距离 = 0.0
		if 调试:
			print("[摄像-触摸] idx=", event.index, " pressed=", event.pressed,
				" 触摸点数=", _触摸点.size())
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		_触摸点[event.index] = event.position
		if _触摸点.size() == 1:
			# 单指拖动
			摄像头.global_position -= event.relative / 摄像头.zoom.x
			_限制在边界内()
			if 调试: print("[摄像-触摸拖动] relative=", event.relative,
				" 位置=", 摄像头.global_position)
		elif _触摸点.size() >= 2:
			# 双指捏合缩放
			_处理双指缩放()
		get_viewport().set_input_as_handled()
		return

	# 触摸激活时忽略鼠标（避免模拟鼠标造成双份位移）
	if _触摸点.size() > 0:
		return

	# ============================================================
	# 鼠标事件（桌面 / 安卓单指模拟）
	# ============================================================
	if event is InputEventMouseButton:
		if event.button_index == 自由拖拽按钮:
			_自由拖拽中 = event.pressed
			if 调试: print("[摄像-鼠标] 左键 ", _自由拖拽中)
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_实际目标缩放 = clampf(
				_实际目标缩放 * (1.0 + 自由滚轮步进),
				自由最小缩放, 自由最大缩放)
			if 调试: print("[摄像-滚轮] 放大 → ", _实际目标缩放)
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_实际目标缩放 = clampf(
				_实际目标缩放 / (1.0 + 自由滚轮步进),
				自由最小缩放, 自由最大缩放)
			if 调试: print("[摄像-滚轮] 缩小 → ", _实际目标缩放)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _自由拖拽中:
		var 旧位置 := 摄像头.global_position
		摄像头.global_position -= event.relative / 摄像头.zoom.x
		_限制在边界内()
		var 当前帧 := Engine.get_process_frames()
		if 调试 and 当前帧 != _上次移动日志帧:
			_上次移动日志帧 = 当前帧
			print("[摄像-拖动] relative=", event.relative,
				" 位置 ", 旧位置, " → ", 摄像头.global_position)
		get_viewport().set_input_as_handled()

#=============================== 触摸缩放 ===============================
func _处理双指缩放() -> void:
	if _触摸点.size() < 2:
		_上次双指距离 = 0.0
		return
	var keys = _触摸点.keys()
	var 距离: float = (_触摸点[keys[0]] as Vector2).distance_to(_触摸点[keys[1]])
	if _上次双指距离 > 0.0 and 距离 > 1.0:
		var 比例 := 距离 / _上次双指距离
		_实际目标缩放 = clampf(
			_实际目标缩放 * 比例,
			自由最小缩放, 自由最大缩放)
		if 调试: print("[摄像-双指] 比例=", 比例, " zoom=", _实际目标缩放)
	_上次双指距离 = 距离

#=============================== 边界 ===============================
func _限制在边界内() -> void:
	if not 启用边界: return
	var z: float = 摄像头.zoom.x
	var 视口尺寸: Vector2 = get_viewport().get_visible_rect().size
	var 半屏宽: float = 视口尺寸.x / (2.0 * z)
	var 半屏高: float = 视口尺寸.y / (2.0 * z)
	摄像头.global_position.x = clampf(摄像头.global_position.x,
		左边界 + 半屏宽, 右边界 - 半屏宽)
	摄像头.global_position.y = clampf(摄像头.global_position.y,
		上边界 + 半屏高, 下边界 - 半屏高)

#=============================== 对外 API ===============================
func 获取摄像头() -> Camera2D:
	return 摄像头

func 让摄像头立刻对准目标() -> void:
	if 摄像头 == null: return
	if 方式 == 1 and 当前目标 != null and is_instance_valid(当前目标):
		摄像头.global_position = 当前目标.global_position
	摄像头.reset_smoothing()

func 设置缩放(倍率: float) -> void:
	_实际目标缩放 = clampf(倍率, 0.1, 20.0)

func 自由视角平移(世界位移: Vector2) -> void:
	if 摄像头 != null:
		摄像头.global_position += 世界位移
		_限制在边界内()

#=============================== 一键诊断 ===============================
func 一键诊断() -> void:
	print("\n=========== 摄像头管理诊断 ===========")
	print("方式 = ", 方式, " （0=固定 1=追踪 2=自由）")
	print("自由启用鼠标 = ", 自由启用鼠标)
	print("自由拖拽按钮 = ", 自由拖拽按钮, " （1=左键 2=右键）")
	print("本节点路径 = ", get_path())
	print("本节点类型 = ", get_class())
	print("--- 摄像头 ---")
	print("摄像头对象 = ", 摄像头)
	if 摄像头 != null:
		print("摄像头路径 = ", 摄像头.get_path())
		print("摄像头 global_position = ", 摄像头.global_position)
		print("摄像头 position(local) = ", 摄像头.position)
		print("摄像头 zoom = ", 摄像头.zoom)
		print("摄像头 enabled = ", 摄像头.enabled)
		if 摄像头.has_method("is_current"):
			print("摄像头 is_current = ", 摄像头.is_current())
		print("摄像头 平滑 = ", 摄像头.position_smoothing_enabled)
	print("--- 输入状态 ---")
	print("_自由拖拽中 = ", _自由拖拽中)
	print("_触摸点数量 = ", _触摸点.size())
	print("--- 场景中所有 Camera2D ---")
	var cam_list = get_tree().root.find_children("*", "Camera2D", true, false)
	print("数量 = ", cam_list.size())
	for c in cam_list:
		print("  - ", c.get_path(), " enabled=", c.enabled)
		if c != 摄像头:
			push_warning("[警告] 存在其他 Camera2D：" + str(c.get_path()))
	print("=======================================\n")
