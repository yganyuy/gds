@tool
extends EditorPlugin
## 中文节点选择器 - 插件入口
## 拦截场景树停靠面板的「添加节点」入口（+ 按钮 / Ctrl+A 快捷键 / 右键菜单），
## 将原版英文节点选择对话框替换为中文版。各入口可独立开关（至少保留一个）。

const 创建节点对话框 := preload("res://addons/ChineseNodeSelector/ui/create_node_dialog.gd")

# 目标快捷键名（Godot 内部稳定标识，不受界面语言影响）
const 添加节点快捷键 := "scene_tree/add_child_node"
# 劫持设置存储键
const 劫持设置键 := "中文节点选择器/劫持设置"
# 右键菜单替换用的自定义项 id（避开 SceneTreeDock 的 Tool 枚举）
const 右键菜单项id := 100000001

var 对话框: ConfirmationDialog = null

# ---- 按钮劫持状态 ----
var 被替换按钮: Button = null
var 原按钮连接: Array = []
var 原按钮快捷键: Shortcut = null
var _重试次数 := 0

# ---- 右键菜单劫持状态 ----
var _右键菜单: PopupMenu = null

# ---- 快捷键输入拦截 ----
var 快捷键监听: Control = null

# 快捷键监听控件：重写 _shortcut_input 接收 Ctrl+A
class 快捷键监听控件:
	extends Control
	var 回调: Callable = Callable()
	func _init(p回调: Callable) -> void:
		回调 = p回调
		set_process_shortcut_input(true)
	func _shortcut_input(event: InputEvent) -> void:
		回调.call(event)

# ---- 劫持开关 ----
var 加号劫持 := true
var 快捷键劫持 := true
var 右键劫持 := true

# ============================================================
# 生命周期
# ============================================================
func _enter_tree() -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings != null and not settings.settings_changed.is_connected(_设置变化):
		settings.settings_changed.connect(_设置变化)
	_读取劫持设置()
	call_deferred("_应用全部劫持")

func _exit_tree() -> void:
	_清除全部劫持()
	var settings := EditorInterface.get_editor_settings()
	if settings != null and settings.settings_changed.is_connected(_设置变化):
		settings.settings_changed.disconnect(_设置变化)

func _disable_plugin() -> void:
	_清除全部劫持()
	if 对话框 != null and is_instance_valid(对话框):
		对话框.queue_free()
		对话框 = null

# ============================================================
# 设置变化监听（开关切换时重新应用劫持）
# ============================================================
func _设置变化() -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings == null or not settings.check_changed_settings_in_group("中文节点选择器"):
		return
	_读取劫持设置()
	_应用全部劫持()

func _读取劫持设置() -> void:
	加号劫持 = true
	快捷键劫持 = true
	右键劫持 = true
	var settings := EditorInterface.get_editor_settings()
	if settings == null or not settings.has_setting(劫持设置键):
		return
	var 数据 = settings.get_setting(劫持设置键)
	if 数据 is Dictionary:
		加号劫持 = bool(数据.get("加号", true))
		快捷键劫持 = bool(数据.get("快捷键", true))
		右键劫持 = bool(数据.get("右键", true))

# ============================================================
# 应用 / 清除全部劫持
# ============================================================
func _应用全部劫持() -> void:
	call_deferred("_尝试劫持按钮")
	if 快捷键劫持:
		_启用快捷键拦截()
	else:
		_禁用快捷键拦截()
	if 右键劫持:
		call_deferred("_尝试劫持右键")
	else:
		_还原右键()

func _清除全部劫持() -> void:
	_还原按钮()
	_还原右键()
	_禁用快捷键拦截()

# ============================================================
# 按钮劫持（+ 按钮 与 Ctrl+A 快捷键）
# ============================================================
func _尝试劫持按钮() -> void:
	var 按钮 := _查找添加节点按钮()
	if 按钮 == null:
		_重试次数 += 1
		if _重试次数 < 200:
			call_deferred("_尝试劫持按钮")
		return
	_重试次数 = 0
	_应用按钮劫持(按钮)

func _查找添加节点按钮() -> Button:
	var base := EditorInterface.get_base_control()
	if base == null:
		return null
	# 按类型查找（节点名可能因 Godot 内部实现变化，类型更稳定）
	var 停靠面板 := base.find_children("*", "SceneTreeDock", true, false)
	if 停靠面板.is_empty():
		return null
	var dock: Node = 停靠面板[0]
	# 策略 1：通过快捷键名精确定位
	for 控件 in dock.find_children("*", "Button", true, false):
		if 控件 is Button:
			var shortcut := (控件 as Button).get_shortcut()
			if shortcut != null and shortcut.get_name() == 添加节点快捷键:
				return 控件
	# 策略 2：通过"过滤节点"输入框定位所在工具栏行，取行内第一个按钮
	for 控件 in dock.find_children("*", "LineEdit", true, false):
		if 控件 is LineEdit:
			var ph: String = (控件 as LineEdit).get_placeholder()
			if "ilter" in ph or "过滤" in ph or "筛选" in ph:
				var 父行: Node = 控件.get_parent()
				if 父行 != null:
					for 子 in 父行.get_children():
						if 子 is Button:
							return 子
	return null

# 按开关配置按钮行为（幂等，可反复调用）
func _应用按钮劫持(按钮: Button) -> void:
	# 首次记录原状态
	if 被替换按钮 == null:
		被替换按钮 = 按钮
		原按钮连接 = 按钮.pressed.get_connections()
		原按钮快捷键 = 按钮.get_shortcut()
	# 加号开关：劫持 / 还原按钮点击
	if 加号劫持:
		for conn in 原按钮连接:
			if conn is Dictionary and conn.has("callable"):
				if 按钮.pressed.is_connected(conn["callable"]):
					按钮.pressed.disconnect(conn["callable"])
		if not 按钮.pressed.is_connected(_打开对话框):
			按钮.pressed.connect(_打开对话框)
		按钮.tooltip_text = "添加 / 创建新节点（中文版）"
	else:
		if 按钮.pressed.is_connected(_打开对话框):
			按钮.pressed.disconnect(_打开对话框)
		for conn in 原按钮连接:
			if conn is Dictionary and conn.has("callable"):
				if not 按钮.pressed.is_connected(conn["callable"]):
					按钮.pressed.connect(conn["callable"])
	# 快捷键由独立输入拦截处理，移除按钮 shortcut 避免双重触发
	按钮.set_shortcut(null)

func _还原按钮() -> void:
	if 被替换按钮 == null or not is_instance_valid(被替换按钮):
		被替换按钮 = null
		return
	var 按钮 := 被替换按钮
	if 按钮.pressed.is_connected(_打开对话框):
		按钮.pressed.disconnect(_打开对话框)
	for conn in 原按钮连接:
		if conn is Dictionary and conn.has("callable"):
			if not 按钮.pressed.is_connected(conn["callable"]):
				按钮.pressed.connect(conn["callable"])
	if 原按钮快捷键 != null:
		按钮.set_shortcut(原按钮快捷键)
	被替换按钮 = null
	原按钮连接 = []
	原按钮快捷键 = null

# ============================================================
# 快捷键独立拦截（Ctrl+A 输入事件）
# ============================================================
func _启用快捷键拦截() -> void:
	if 快捷键监听 != null and is_instance_valid(快捷键监听):
		return
	var base := EditorInterface.get_base_control()
	if base == null:
		return
	快捷键监听 = 快捷键监听控件.new(Callable(self, "_快捷键输入"))
	base.add_child(快捷键监听)

func _禁用快捷键拦截() -> void:
	if 快捷键监听 != null:
		if is_instance_valid(快捷键监听):
			快捷键监听.queue_free()
		快捷键监听 = null

func _快捷键输入(event: InputEvent) -> void:
	if not 快捷键劫持:
		return
	var settings := EditorInterface.get_editor_settings()
	if settings == null or not settings.has_shortcut(添加节点快捷键):
		return
	var sc := settings.get_shortcut(添加节点快捷键)
	if sc != null and sc.matches_event(event):
		if 快捷键监听 != null:
			快捷键监听.accept_event()
		_打开对话框()

# ============================================================
# 右键菜单劫持
# ============================================================
func _尝试劫持右键() -> void:
	var 菜单 := _查找右键菜单()
	if 菜单 == null:
		return
	_右键菜单 = 菜单
	if not _右键菜单.about_to_popup.is_connected(_替换添加节点项):
		_右键菜单.about_to_popup.connect(_替换添加节点项)
	if not _右键菜单.id_pressed.is_connected(_右键菜单处理):
		_右键菜单.id_pressed.connect(_右键菜单处理)

func _查找右键菜单() -> PopupMenu:
	var base := EditorInterface.get_base_control()
	if base == null:
		return null
	var 停靠面板 := base.find_children("*", "SceneTreeDock", true, false)
	if 停靠面板.is_empty():
		return null
	var dock: Node = 停靠面板[0]
	# 右键菜单是 SceneTreeDock 的直接 PopupMenu 子节点
	for 子 in dock.get_children():
		if 子 is PopupMenu:
			return 子
	return null

# 菜单每次右键前重建，about_to_popup 时把「添加子节点」项 id 换成我们的
func _替换添加节点项() -> void:
	if not 右键劫持 or _右键菜单 == null or not is_instance_valid(_右键菜单):
		return
	var idx := _右键菜单.get_item_index(0)  # TOOL_NEW 的枚举值为 0
	if idx == -1:
		return
	if _右键菜单.get_item_id(idx) == 0:
		_右键菜单.set_item_id(idx, 右键菜单项id)
		_右键菜单.set_item_text(idx, "添加子节点")

func _右键菜单处理(id: int) -> void:
	if id == 右键菜单项id:
		_打开对话框()

func _还原右键() -> void:
	if _右键菜单 == null or not is_instance_valid(_右键菜单):
		_右键菜单 = null
		return
	if _右键菜单.about_to_popup.is_connected(_替换添加节点项):
		_右键菜单.about_to_popup.disconnect(_替换添加节点项)
	if _右键菜单.id_pressed.is_connected(_右键菜单处理):
		_右键菜单.id_pressed.disconnect(_右键菜单处理)
	_右键菜单 = null

# ============================================================
# 打开中文对话框
# ============================================================
func _打开对话框() -> void:
	if not _创建对话框():
		return
	对话框.打开("Node")

func _创建对话框() -> bool:
	if 对话框 != null and is_instance_valid(对话框):
		return true
	var base := EditorInterface.get_base_control()
	if base == null:
		return false
	对话框 = 创建节点对话框.new()
	base.add_child(对话框)
	return true
