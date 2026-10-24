@tool
extends Node
class_name 监听插帧

## 监听插帧器：骨骼属性变化时自动插帧；播放预览时通过信号自动暂停/恢复监听

@export var 骨架: Skeleton2D
@export var 动画播放器: AnimationPlayer
@export var 属性名列表: PackedStringArray = ["rotation"]

@export_group("插帧控制")
@export var 监听属性变化自动插帧: bool = false:
	set(值):
		监听属性变化自动插帧 = 值
		_同步处理()
@export var 临时暂停监听: bool = false
## 播放预览时自动置为 true，播放结束信号发出后自动恢复
@export_range(0.0, 60.0, 0.01, "s") var 属性变化插帧时间: float = 0.0
@export var 属性变化阈值: float = 0.001

@export_group("调试")
@export var 显示诊断日志: bool = true

@export_tool_button("插帧时间 +0.1s") var _加 = _推进
@export_tool_button("插帧时间 -0.1s") var _减 = _回退

var _缓存: Dictionary = {}
var _已初始化: bool = false
var _上次日志毫秒: int = 0
var _已连接信号: bool = false

# ---------- 生命周期与信号连接 ----------

func _ready() -> void:
	_同步处理()
	_尝试连接信号()

func _同步处理() -> void:
	if Engine.is_editor_hint():
		set_process(监听属性变化自动插帧 and not 临时暂停监听)

func _尝试连接信号() -> void:
	if not Engine.is_editor_hint() or _已连接信号: return
	if 动画播放器 == null: return
	if not 动画播放器.animation_started.is_connected(_当动画开始):
		动画播放器.animation_started.connect(_当动画开始)
	if not 动画播放器.animation_finished.is_connected(_当动画结束):
		动画播放器.animation_finished.connect(_当动画结束)
	_已连接信号 = true
	_诊断("已连接 animation_started / animation_finished")

func _当动画开始(_动画名: StringName) -> void:
	临时暂停监听 = true
	_同步处理()
	_诊断("播放开始，监听自动暂停")

func _当动画结束(_动画名: StringName) -> void:
	临时暂停监听 = false
	_同步处理()
	_缓存.clear()
	_已初始化 = false  # 强制下一帧重新采样，避免把播放后的姿态误判为用户操作
	_诊断("播放结束，监听已恢复")

# ---------- 核心监听 ----------

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return
	if not 监听属性变化自动插帧 or 临时暂停监听: return
	if not is_inside_tree(): return
	_监听()

func _监听() -> void:
	if 动画播放器 == null or 骨架 == null:
		_诊断("缺少动画播放器或骨架引用"); return
	var 动画 := _获取动画()
	if 动画 == null:
		_诊断("动画播放器中没有动画"); return
	var 骨骼列表 := _收集骨骼(骨架)
	if 骨骼列表.is_empty():
		_诊断("骨架下没有 Bone2D"); return

	if not _已初始化:
		_刷新缓存(骨骼列表)
		_已初始化 = true
		_诊断("缓存初始化，骨骼数=%d" % 骨骼列表.size())
		return

	var 根 := _获取根节点()
	for 骨骼 in 骨骼列表:
		for 属性名 in 属性名列表:
			var 键 := str(骨骼.get_path()) + ":" + 属性名
			var 当前 = 骨骼.get(属性名)
			if 当前 == null or not _缓存.has(键): continue
			if _相等(_缓存[键], 当前): continue

			print("[监听插帧] %s.%s @ %.3fs = %s" % [骨骼.name, 属性名, 属性变化插帧时间, str(当前)])
			_缓存[键] = 当前
			var 路径 := str(根.get_path_to(骨骼)) + ":" + 属性名
			var 索引 := 动画.find_track(NodePath(路径), Animation.TYPE_VALUE)
			if 索引 == -1:
				索引 = 动画.add_track(Animation.TYPE_VALUE)
				动画.track_set_path(索引, NodePath(路径))
			动画.track_insert_key(索引, 属性变化插帧时间, 当前)
			EditorInterface.mark_scene_as_unsaved()

func _刷新缓存(列表: Array[Bone2D]) -> void:
	_缓存.clear()
	for 骨骼 in 列表:
		for 属性名 in 属性名列表:
			var 值 = 骨骼.get(属性名)
			if 值 != null: _缓存[str(骨骼.get_path()) + ":" + 属性名] = 值

# ---------- 工具 ----------

func _推进() -> void: 属性变化插帧时间 += 0.1
func _回退() -> void: 属性变化插帧时间 = max(0.0, 属性变化插帧时间 - 0.1)

func _诊断(消息: String) -> void:
	if not 显示诊断日志: return
	var 现在 := Time.get_ticks_msec()
	if 现在 - _上次日志毫秒 < 500: return
	_上次日志毫秒 = 现在
	print("[监听插帧器] ", 消息)

func _相等(a, b) -> bool:
	if a is float and b is float: return abs(a - b) <= 属性变化阈值
	if a is Vector2 and b is Vector2: return a.distance_to(b) <= 属性变化阈值
	return a == b

func _获取动画() -> Animation:
	var 列表 := 动画播放器.get_animation_list()
	return 动画播放器.get_animation(列表[0]) if not 列表.is_empty() else null

func _获取根节点() -> Node:
	var 根 := 动画播放器.get_node_or_null(动画播放器.root_node)
	return 根 if 根 != null else 动画播放器

func _收集骨骼(节点: Node) -> Array[Bone2D]:
	var 结果: Array[Bone2D] = []
	for 子 in 节点.get_children():
		if 子 is Bone2D: 结果.append(子)
		结果.append_array(_收集骨骼(子))
	return 结果