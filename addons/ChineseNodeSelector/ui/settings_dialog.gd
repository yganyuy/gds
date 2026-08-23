@tool
extends ConfirmationDialog
## 设置对话框
## 提供：数据保存范围（全局 / 仅当前项目）、自定义翻译映射编辑。

const 节点数据库 := preload("res://addons/ChineseNodeSelector/data/node_database.gd")
const 支持作者 := preload("res://addons/ChineseNodeSelector/ui/support_author.gd")

const 设置前缀 := "中文节点选择器"
const 范围键 := "保存范围"
const 翻译键 := "自定义翻译"
const 捐赠链接键 := "捐赠链接"
const 劫持设置键 := "中文节点选择器/劫持设置"

signal 设置已更改

var 保存范围选择: OptionButton
var 加号勾选: CheckBox
var 快捷键勾选: CheckBox
var 右键勾选: CheckBox
var 搜索框: LineEdit
var 翻译树: Tree
var 自定义翻译: Dictionary = {}
var 当前范围: String = "global"
var 支持作者窗口: Window = null

# ============================================================
func _init() -> void:
	title = "节点选择器设置"
	ok_button_text = "完成"
	cancel_button_text = "取消"
	exclusive = false
	_build_ui()
	confirmed.connect(_完成)

# ============================================================
# 高 DPI：窗口尺寸随编辑器缩放（Editor Scale）放大，否则显示不全
func _编辑器缩放() -> float:
	if not Engine.is_editor_hint():
		return 1.0
	return EditorInterface.get_editor_scale()

# ============================================================
func _build_ui() -> void:
	var 缩放 := _编辑器缩放()
	# 整体可滚动，窗口较小时也能看到下方翻译列表
	var scroll := ScrollContainer.new()
	scroll.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	scroll.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.set_custom_minimum_size(Vector2(560, 440) * 缩放)
	vbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	scroll.add_child(vbox)

	# 数据保存范围
	var 范围行 := HBoxContainer.new()
	var 范围标签 := Label.new()
	范围标签.text = "数据保存位置："
	范围行.add_child(范围标签)
	保存范围选择 = OptionButton.new()
	保存范围选择.add_item("全局（所有项目共用）", 0)
	保存范围选择.add_item("仅当前项目", 1)
	保存范围选择.item_selected.connect(_范围改变)
	范围行.add_child(保存范围选择)
	vbox.add_child(范围行)

	# 关于作者（可选、完全自愿）
	var 捐赠标签 := Label.new()
	捐赠标签.text = "关于作者"
	捐赠标签.set_theme_type_variation("HeaderSmall")
	vbox.add_child(捐赠标签)
	var 捐赠说明 := Label.new()
	捐赠说明.text = "本插件完全免费，开源且无任何功能限制。"
	捐赠说明.modulate.a = 0.7
	vbox.add_child(捐赠说明)
	var 预览 := Button.new()
	预览.text = "作者信息"
	预览.pressed.connect(_打开支持作者)
	vbox.add_child(预览)

	# 节点选择器入口劫持开关
	var 劫持标题 := Label.new()
	劫持标题.text = "节点选择器入口劫持"
	劫持标题.set_theme_type_variation("HeaderSmall")
	vbox.add_child(劫持标题)
	加号勾选 = CheckBox.new()
	加号勾选.text = "劫持「+」按钮"
	加号勾选.toggled.connect(_劫持勾选变化.bind("加号"))
	vbox.add_child(加号勾选)
	快捷键勾选 = CheckBox.new()
	快捷键勾选.text = "劫持快捷键 Ctrl+A"
	快捷键勾选.toggled.connect(_劫持勾选变化.bind("快捷键"))
	vbox.add_child(快捷键勾选)
	右键勾选 = CheckBox.new()
	右键勾选.text = "劫持右键菜单「添加子节点」"
	右键勾选.toggled.connect(_劫持勾选变化.bind("右键"))
	vbox.add_child(右键勾选)

	var 提示 := Label.new()
	提示.text = "自定义翻译：红色节点 = 尚未翻译，修改后实时生效。留空可恢复默认。"
	提示.set_theme_type_variation("HeaderSmall")
	vbox.add_child(提示)

	搜索框 = LineEdit.new()
	搜索框.set_placeholder("搜索类名 / 中文名…")
	搜索框.text_changed.connect(func(_t): _构建翻译树())
	vbox.add_child(搜索框)

	翻译树 = Tree.new()
	翻译树.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	翻译树.set_custom_minimum_size(Vector2(0, 300) * 缩放)
	翻译树.set_columns(2)
	翻译树.set_column_titles_visible(true)
	翻译树.set_column_title(0, "类名（英文）")
	翻译树.set_column_title(1, "中文名")
	翻译树.set_column_expand(0, true)
	翻译树.set_column_expand(1, true)
	翻译树.item_edited.connect(_翻译编辑)
	vbox.add_child(翻译树)

	var 重置 := add_button("恢复内置翻译", true, "reset")
	重置.pressed.connect(_重置翻译)

# ============================================================
func 打开() -> void:
	_读取范围()
	_读取翻译()
	_读取劫持勾选()
	_构建翻译树()
	popup_centered(Vector2(600, 520) * _编辑器缩放())

func _读取范围() -> void:
	var settings := EditorInterface.get_editor_settings()
	当前范围 = "global"
	if settings.has_setting("%s/%s" % [设置前缀, 范围键]):
		当前范围 = settings.get_setting("%s/%s" % [设置前缀, 范围键])
	保存范围选择.selected = 0 if 当前范围 == "global" else 1

func _范围改变(_idx: int) -> void:
	var settings := EditorInterface.get_editor_settings()
	当前范围 = "global" if 保存范围选择.selected == 0 else "project"
	settings.set_setting("%s/%s" % [设置前缀, 范围键], 当前范围)
	_读取翻译()
	_构建翻译树()

func _读取翻译() -> void:
	var settings := EditorInterface.get_editor_settings()
	自定义翻译 = {}
	if 当前范围 == "global":
		if settings.has_setting("%s/%s" % [设置前缀, 翻译键]):
			自定义翻译 = settings.get_setting("%s/%s" % [设置前缀, 翻译键])
	else:
		var 数据 = settings.get_project_metadata(设置前缀, 翻译键, {})
		if 数据 is Dictionary:
			自定义翻译 = 数据

# ============================================================
func _构建翻译树() -> void:
	翻译树.clear()
	var 根 := 翻译树.create_item()
	var 全部 := 节点数据库.扫描类型("Node")

	var 已翻译 := []
	var 未翻译 := []
	var 词 := 搜索框.text.strip_edges().to_lower()
	for e in 全部:
		if e.来源 == 节点数据库.来源编辑器:
			continue
		var 当前: String = 自定义翻译.get(e.类名, 节点数据库.翻译表.get(e.类名, ""))
		if not 词.is_empty() and not e.类名.to_lower().contains(词) and not 当前.to_lower().contains(词):
			continue
		if 当前.is_empty():
			未翻译.append([e, 当前])
		else:
			已翻译.append([e, 当前])
	未翻译.sort_custom(func(a, b): return a[0].类名 < b[0].类名)
	已翻译.sort_custom(func(a, b): return a[0].类名 < b[0].类名)

	for 对 in 未翻译:
		_加行(根, 对[0], 对[1])
	for 对 in 已翻译:
		_加行(根, 对[0], 对[1])

	翻译树.set_column_title(0, "类名（英文）— 未翻译 %d 个置顶" % 未翻译.size())

func _加行(根: TreeItem, 条目, 当前名: String) -> void:
	var item := 翻译树.create_item(根)
	item.set_text(0, 条目.类名)
	item.set_text(1, 当前名)
	item.set_editable(1, true)
	item.set_metadata(0, 条目.类名)
	if 当前名.is_empty():
		item.set_custom_color(0, Color("#e07a7a"))

func _翻译编辑() -> void:
	var item := 翻译树.get_edited()
	if item == null:
		return
	var 类名 := String(item.get_metadata(0))
	var 新名 := item.get_text(1).strip_edges()
	if 新名.is_empty():
		自定义翻译.erase(类名)
		item.set_custom_color(0, Color("#e07a7a"))
	else:
		自定义翻译[类名] = 新名
		item.set_custom_color(0, Color.WHITE)
	_保存翻译()

func _重置翻译() -> void:
	自定义翻译 = {}
	_保存翻译()
	_构建翻译树()

func _保存翻译() -> void:
	var settings := EditorInterface.get_editor_settings()
	if 当前范围 == "global":
		settings.set_setting("%s/%s" % [设置前缀, 翻译键], 自定义翻译)
	else:
		settings.set_project_metadata(设置前缀, 翻译键, 自定义翻译)
	节点数据库.重新加载自定义翻译()
	设置已更改.emit()

func _打开支持作者() -> void:
	if 支持作者窗口 == null or not is_instance_valid(支持作者窗口):
		支持作者窗口 = 支持作者.new()
		get_parent().add_child(支持作者窗口)
		支持作者窗口.hide()  # Window 默认可见，需先隐藏，由 打开() 控制显示
	# 已打开则置顶，否则弹出
	if 支持作者窗口.visible:
		支持作者窗口.grab_focus()
	else:
		支持作者窗口.打开()

func _读取劫持勾选() -> void:
	var settings := EditorInterface.get_editor_settings()
	var 数据 := {}
	if settings.has_setting(劫持设置键):
		数据 = settings.get_setting(劫持设置键)
	加号勾选.set_pressed_no_signal(bool(数据.get("加号", true)))
	快捷键勾选.set_pressed_no_signal(bool(数据.get("快捷键", true)))
	右键勾选.set_pressed_no_signal(bool(数据.get("右键", true)))

func _劫持勾选变化(_勾选: bool, _键: String) -> void:
	# 至少保留一个入口劫持：全部取消时自动全部点亮
	var 已勾选数 := (1 if 加号勾选.button_pressed else 0) \
			+ (1 if 快捷键勾选.button_pressed else 0) \
			+ (1 if 右键勾选.button_pressed else 0)
	if 已勾选数 == 0:
		加号勾选.set_pressed_no_signal(true)
		快捷键勾选.set_pressed_no_signal(true)
		右键勾选.set_pressed_no_signal(true)
	_保存劫持设置()

func _保存劫持设置() -> void:
	EditorInterface.get_editor_settings().set_setting(劫持设置键, {
		"加号": 加号勾选.button_pressed,
		"快捷键": 快捷键勾选.button_pressed,
		"右键": 右键勾选.button_pressed,
	})

func _弹提示(文本: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = 文本
	dlg.ok_button_text = "知道了"
	get_parent().add_child(dlg)
	dlg.popup_centered()

func _完成() -> void:
	_保存翻译()
	hide()
