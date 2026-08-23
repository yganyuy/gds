@tool
extends ConfirmationDialog
## 创建节点对话框
## 完全复刻 Godot 原生"添加节点"对话框（CreateDialog），
## 但所有名称 / 分类 / 描述均为中文，并支持中英文双语搜索。

const 节点数据库 := preload("res://addons/ChineseNodeSelector/data/node_database.gd")
const 设置对话框 := preload("res://addons/ChineseNodeSelector/ui/settings_dialog.gd")

const 过滤内置: int = 0
const 过滤自定义: int = 1
const 过滤编辑器: int = 2

const 收藏树设置键 := "收藏列表"
const 最近设置键 := "最近使用"
const 过滤设置键 := "类型过滤"
const 窗口尺寸设置键 := "窗口Rect"

# ---------- UI ----------
var 搜索框: LineEdit
var 结果树: Tree
var 收藏树: Tree
var 最近列表: ItemList
var 收藏按钮: Button
var 设置按钮: Button
var 过滤按钮: MenuButton
var 重置过滤按钮: Button
var 描述框: RichTextLabel
var 设置对话框实例: ConfirmationDialog = null

# ---------- 数据 ----------
var 基础类型 := "Node"
var 全部类型: Array[节点数据库.节点条目] = []   # 全部节点类型
var 已建节点映射 := {}                          # 类名 -> TreeItem
var 类型过滤 := {
	过滤内置: true,
	过滤自定义: true,
	过滤编辑器: false,
}
var 收藏列表: Array = []                        # Array[String] 类名
var 最近使用列表: Array = []                    # Array[String] 类名

# ============================================================
# 生命周期
# ============================================================
func _init() -> void:
	title = "创建新节点"
	ok_button_text = "创建"
	cancel_button_text = "取消"
	set_hide_on_ok(false)
	_build_ui()
	confirmed.connect(_确认创建)
	canceled.connect(hide)
	visibility_changed.connect(_可见性变化)
	close_requested.connect(hide)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_更新主题()

# ============================================================
# UI 构建（复刻原版 CreateDialog 布局）
# ============================================================
func _build_ui() -> void:
	var 缩放 := EditorInterface.get_editor_scale()
	var hsc := HSplitContainer.new()
	add_child(hsc)

	var vsc := VSplitContainer.new()
	hsc.add_child(vsc)

	var vsc_right := VSplitContainer.new()
	hsc.add_child(vsc_right)

	# ---- 左：收藏 + 最近使用 ----
	var fav_vb := VBoxContainer.new()
	fav_vb.set_custom_minimum_size(Vector2(150, 100) * 缩放)
	fav_vb.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	vsc.add_child(fav_vb)

	收藏树 = Tree.new()
	收藏树.set_hide_root(true)
	收藏树.set_hide_folding(true)
	收藏树.set_allow_reselect(true)
	收藏树.set_theme_type_variation("TreeSecondary")
	收藏树.cell_selected.connect(_收藏选中)
	收藏树.item_activated.connect(_收藏激活)
	_添加分组(fav_vb, "收藏:", 收藏树, true)

	var rec_vb := VBoxContainer.new()
	rec_vb.set_custom_minimum_size(Vector2(150, 100) * 缩放)
	rec_vb.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	vsc.add_child(rec_vb)

	最近列表 = ItemList.new()
	最近列表.set_allow_reselect(true)
	最近列表.set_theme_type_variation("ItemListSecondary")
	最近列表.item_selected.connect(_最近选中)
	最近列表.item_activated.connect(_最近激活)
	_添加分组(rec_vb, "最近使用:", 最近列表, true)

	# ---- 右：搜索 + 结果 + 描述 ----
	var vbc := VBoxContainer.new()
	vbc.set_custom_minimum_size(Vector2(300, 0) * 缩放)
	vbc.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	vbc.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	vsc_right.add_child(vbc)

	var search_hb := HBoxContainer.new()
	搜索框 = LineEdit.new()
	搜索框.set_clear_button_enabled(true)
	搜索框.set_placeholder("搜索节点（中文 / 英文）…")
	搜索框.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	搜索框.text_changed.connect(_文本变化)
	search_hb.add_child(搜索框)

	收藏按钮 = Button.new()
	收藏按钮.set_toggle_mode(true)
	收藏按钮.set_tooltip_text("将选中的节点加入 / 移出收藏")
	收藏按钮.pressed.connect(_收藏切换)
	search_hb.add_child(收藏按钮)

	设置按钮 = Button.new()
	设置按钮.set_tooltip_text("设置")
	设置按钮.set_theme_type_variation("FlatButton")
	设置按钮.pressed.connect(_打开设置)
	search_hb.add_child(设置按钮)
	_添加分组(vbc, "搜索:", search_hb)

	var matches_hb := HBoxContainer.new()
	vbc.add_child(matches_hb)

	var matches_label := Label.new()
	matches_label.text = "匹配:"
	matches_label.set_theme_type_variation("HeaderSmall")
	matches_label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	matches_hb.add_child(matches_label)

	重置过滤按钮 = Button.new()
	重置过滤按钮.set_theme_type_variation("FlatButton")
	重置过滤按钮.set_h_size_flags(Control.SIZE_SHRINK_END)
	重置过滤按钮.set_tooltip_text("重置过滤选项")
	重置过滤按钮.pressed.connect(_重置过滤)
	matches_hb.add_child(重置过滤按钮)

	过滤按钮 = MenuButton.new()
	过滤按钮.set_text("过滤")
	过滤按钮.set_theme_type_variation("FlatMenuButton")
	过滤按钮.set_h_size_flags(Control.SIZE_SHRINK_END)
	var popup := 过滤按钮.get_popup()
	popup.add_check_item("显示内置", 过滤内置)
	popup.add_check_item("显示自定义", 过滤自定义)
	popup.add_check_item("显示编辑器", 过滤编辑器)
	popup.set_hide_on_checkable_item_selection(false)
	popup.id_pressed.connect(_过滤切换)
	matches_hb.add_child(过滤按钮)

	结果树 = Tree.new()
	结果树.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	结果树.set_theme_type_variation("TreeSecondary")
	结果树.item_activated.connect(_确认创建)
	结果树.cell_selected.connect(_结果选中)
	vbc.add_child(结果树)

	# ---- 右：描述 ----
	var vbc_desc := VBoxContainer.new()
	vbc_desc.set_custom_minimum_size(Vector2(300, 0) * 缩放)
	描述框 = RichTextLabel.new()
	描述框.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	描述框.set_custom_minimum_size(Vector2(0, 90) * 缩放)
	描述框.bbcode_enabled = true
	描述框.fit_content = false
	描述框.scroll_active = true
	描述框.add_theme_color_override("font_link_color", Color("#4a9fff"))
	_添加分组(vbc_desc, "描述:", 描述框, true)
	vsc_right.add_child(vbc_desc)

	register_text_enter(搜索框)

# ============================================================
# 辅助：给 VBoxContainer 添加"标签 + 控件"分组（等价原版 add_margin_child）
# ============================================================
func _添加分组(容器: VBoxContainer, 标签: String, 控件: Control, 扩展: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = 标签
	lbl.set_theme_type_variation("HeaderSmall")
	容器.add_child(lbl)
	var margin := MarginContainer.new()
	margin.add_child(控件)
	容器.add_child(margin)
	if 扩展:
		margin.set_v_size_flags(Control.SIZE_EXPAND_FILL)

# ============================================================
# 主题
# ============================================================
func _更新主题() -> void:
	var 图标尺寸 := 0
	if has_theme_constant("class_icon_size", "Editor"):
		图标尺寸 = get_theme_constant("class_icon_size", "Editor")
	if 图标尺寸 <= 0:
		图标尺寸 = 16
	结果树.add_theme_constant_override("icon_max_width", 图标尺寸)
	收藏树.add_theme_constant_override("icon_max_width", 图标尺寸)
	最近列表.set_fixed_icon_size(Vector2(图标尺寸, 图标尺寸))
	if has_theme_icon("Favorites", "EditorIcons"):
		收藏按钮.icon = get_theme_icon("Favorites", "EditorIcons")
	if has_theme_icon("Reload", "EditorIcons"):
		重置过滤按钮.icon = get_theme_icon("Reload", "EditorIcons")
	if has_theme_icon("GuiDropdown", "EditorIcons"):
		过滤按钮.icon = get_theme_icon("GuiDropdown", "EditorIcons")
	# 设置按钮图标：插件自带的单色齿轮 SVG（编辑器图标库中无齿轮图标，
	# 颜色取编辑器官方图标一致的 #e0e0e0，深浅主题下均可见）
	if 设置按钮 != null and 设置按钮.icon == null:
		var 纹理 := _加载齿轮图标()
		if 纹理 != null:
			设置按钮.icon = 纹理
		else:
			设置按钮.text = "设置"  # 图标加载失败时回退为文字

# 运行时解析齿轮 SVG 为纹理，不依赖资源导入系统（插件分发时无 .import 缓存）
func _加载齿轮图标() -> Texture2D:
	var svg := FileAccess.get_file_as_string("res://addons/ChineseNodeSelector/icons/settings.svg")
	if svg.is_empty():
		return null
	var img := Image.new()
	if img.load_svg_from_buffer(svg.to_utf8_buffer()) != OK:
		return null
	return ImageTexture.create_from_image(img)

# ============================================================
# 打开对话框
# ============================================================
func 打开(p_基础类型: String = "Node") -> void:
	基础类型 = p_基础类型
	title = "创建新节点"

	# 应用设置里的自定义翻译
	节点数据库.重新加载自定义翻译()
	全部类型 = 节点数据库.扫描类型(基础类型)

	# 加载持久化状态
	加载过滤()
	加载收藏()
	加载最近()

	搜索框.clear()
	更新过滤按钮状态()
	更新收藏树()
	更新最近列表()
	更新搜索()

	_弹出居中()

# ============================================================
# 弹出（记忆窗口尺寸）
# ============================================================
func _弹出居中() -> void:
	var 保存: Rect2 = _读取数据(窗口尺寸设置键, Rect2())
	if 保存 != Rect2():
		popup(保存)
	else:
		popup_centered_clamped(Vector2(900, 700) * EditorInterface.get_editor_scale(), 0.8)

func _可见性变化() -> void:
	if visible:
		搜索框.grab_focus()
		搜索框.select_all()
	else:
		# 记忆窗口位置与尺寸
		_保存数据(窗口尺寸设置键, Rect2(get_position(), get_size()))

# ============================================================
# 搜索与结果树
# ============================================================
func _文本变化(_文本: String) -> void:
	更新过滤按钮状态()
	更新搜索()

func 更新搜索() -> void:
	结果树.clear()
	已建节点映射.clear()

	# 根节点 = 基础类型
	var 根 := 结果树.create_item()
	根.set_text(0, 节点数据库.翻译表.get(基础类型, 基础类型))
	根.set_icon(0, 节点数据库.获取图标(基础类型))
	根.set_metadata(0, 基础类型)
	已建节点映射[基础类型] = 根

	var 搜索词 := 搜索框.text.strip_edges()

	# 收集匹配项并评分排序
	var 匹配结果 := []
	for 条目 in 全部类型:
		if 类型过滤.has(条目.来源) and not 类型过滤[条目.来源]:
			continue
		var 分 := _评分(条目, 搜索词)
		if 分 >= 0.0:
			匹配结果.append([分, 条目])
	匹配结果.sort_custom(func(a, b): return a[0] > b[0])

	# 构建树
	for 结果 in 匹配结果:
		_添加类型到树(结果[1])

	# 选中最佳结果（优先可实例化条目，避免默认停在不可创建的抽象分类上）
	if 搜索词.is_empty():
		选中类型(基础类型)
	elif 匹配结果.size() > 0:
		var 最佳: 节点数据库.节点条目 = 匹配结果[0][1]
		for 结果 in 匹配结果:
			if 结果[1].可实例化:
				最佳 = 结果[1]
				break
		选中类型(最佳.类名)
	else:
		收藏按钮.set_disabled(true)
		描述框.text = "未找到匹配 “%s” 的节点。" % 搜索词
		get_ok_button().disabled = true
		结果树.deselect_all()

func _评分(条目: 节点数据库.节点条目, 搜索词: String) -> float:
	if 搜索词.is_empty():
		return 0.0
	var 英文 := 条目.类名.to_lower()
	var 中文 := 条目.显示名.to_lower()
	var 词 := 搜索词.to_lower()
	var 在中文 := 中文.find(词)
	var 在英文 := 英文.find(词)
	if 在中文 == -1 and 在英文 == -1:
		return -1.0

	# 精确匹配最高分
	if 条目.类名.to_lower() == 词 or 中文 == 词:
		return 2.0

	var 分 := 1.0
	if 在中文 > -1:
		分 += 0.2                          # 中文匹配加分
		分 -= 0.4 * minf(1.0, 在中文 / 10.0)
	else:
		分 -= 0.4 * minf(1.0, 在英文 / 10.0)
	if 条目.类名 in 收藏列表:
		分 += 0.1
	return 分

func _添加类型到树(条目: 节点数据库.节点条目) -> void:
	if 已建节点映射.has(条目.类名):
		return
	var 父项: TreeItem = null
	if 条目.父类 != 基础类型 and not 条目.父类.is_empty() and 条目.父类 != "Object":
		var 父条目 := _获取父条目(条目)
		if 父条目 != null:
			_添加类型到树(父条目)
			父项 = 已建节点映射.get(父条目.类名, null)
	if 父项 == null:
		父项 = 已建节点映射.get(基础类型, null)
	var item := 结果树.create_item(父项)
	item.set_text(0, 条目.显示名)
	item.set_icon(0, 条目.图标)
	item.set_metadata(0, 条目.类名)
	item.set_tooltip_text(0, 条目.类名)
	if not 条目.可实例化:
		item.set_custom_color(0, 结果树.get_theme_color("font_disabled_color", "Editor"))

	# 实验性 / 弃用 警告标记（复刻原版）
	if 条目.是否弃用 and 结果树.has_theme_icon("StatusError", "EditorIcons"):
		item.add_button(0, 结果树.get_theme_icon("StatusError", "EditorIcons"), 0, false, "该类已标记为弃用。")
	elif 条目.是否实验性 and 结果树.has_theme_icon("NodeWarning", "EditorIcons"):
		item.add_button(0, 结果树.get_theme_icon("NodeWarning", "EditorIcons"), 0, false, "该类已标记为实验性。")

	# 折叠逻辑（复刻原版）：搜索时全部展开；否则只展开根与第一层抽象分类节点
	var 根文本 := 节点数据库.翻译表.get(基础类型, 基础类型)
	if 搜索框.text.strip_edges().is_empty():
		var 应折叠 := true
		var 父 := item.get_parent()
		if 条目.类名 == 基础类型:
			应折叠 = false
		elif 父 != null and 父.get_text(0) == 根文本 and not 条目.可实例化:
			应折叠 = false
		# 若用户设置了"创建对话框完全展开"，则不折叠
		var 设置 := EditorInterface.get_editor_settings()
		if 应折叠 and 设置.has_setting("docks/scene_tree/start_create_dialog_fully_expanded") \
				and 设置.get_setting("docks/scene_tree/start_create_dialog_fully_expanded"):
			应折叠 = false
		item.set_collapsed(应折叠)
	else:
		item.set_collapsed(false)

	已建节点映射[条目.类名] = item

func _获取父条目(条目: 节点数据库.节点条目) -> 节点数据库.节点条目:
	var 父类名 := 条目.父类
	if 父类名.is_empty():
		return null
	for t in 全部类型:
		if t.类名 == 父类名:
			return t
	# 父类不在列表中（被过滤），构建一个纯分类节点
	var 父 := 节点数据库.节点条目.new()
	父.类名 = 父类名
	父.显示名 = 节点数据库.翻译表.get(父类名, 父类名)
	父.图标 = 节点数据库.获取图标(父类名)
	父.父类 = ClassDB.get_parent_class(父类名) if ClassDB.class_exists(父类名) else ""
	父.可实例化 = false
	return 父

# ============================================================
# 选中与描述
# ============================================================
func _结果选中() -> void:
	选中类型(获取选中类名())

func 选中类型(类名: String) -> void:
	if not 已建节点映射.has(类名):
		return
	var item: TreeItem = 已建节点映射[类名]
	item.select(0)
	结果树.scroll_to_item(item, true)
	_更新描述(类名)
	收藏按钮.set_disabled(false)
	收藏按钮.set_pressed(收藏列表.has(类名))
	var 条目 := _按类名查找(类名)
	if 条目 != null and not 条目.可实例化:
		get_ok_button().disabled = true
		get_ok_button().tooltip_text = "选中的类无法实例化"
	else:
		get_ok_button().disabled = false
		get_ok_button().tooltip_text = ""

func 获取选中类名() -> String:
	var selected := 结果树.get_selected()
	if selected == null:
		return ""
	return String(selected.get_metadata(0))

func _更新描述(类名: String) -> void:
	var 条目 := _按类名查找(类名)
	if 条目 == null:
		描述框.text = ""
		return
	var 文本 := 条目.描述
	# 节点名引用翻译成中文 + 蓝色链接
	文本 = _翻译描述引用(文本)
	# 段落：单换行转为空行，让描述更透气
	文本 = 文本.replace("\n", "\n\n")
	if 文本.is_empty():
		文本 = "（暂无描述）"
	# 英文类名置顶显示
	描述框.text = "[color=#a0a0a0]%s[/color]\n\n%s" % [条目.类名, 文本]

# 将描述里的类名引用（如 [Node2D] / [member CanvasItem.z_index]）翻译成中文，
# 并转为不可点击的蓝色链接样式（[url]）。
func _翻译描述引用(文本: String) -> String:
	var re := RegEx.new()
	# 裸类名链接 [Node2D]（首字母大写，避免误匹配 [b] [code] 等小写标签）
	re.compile("\\[([A-Z][A-Za-z0-9_]*)\\]")
	文本 = _替换正则(文本, re, _回调裸类名)
	# 带类型标签：[member X.y] [method X.y] [signal X] 等
	re.compile("\\[(member|method|signal|property|theme_item|constant|enum|annotation) ([A-Za-z@][A-Za-z0-9_.]*)\\]")
	文本 = _替换正则(文本, re, _回调带类型)
	return 文本

# 用回调逐个替换正则匹配（RegEx.sub 不接受 Callable，手动拼接）
func _替换正则(文本: String, re: RegEx, 回调: Callable) -> String:
	var 结果 := ""
	var last := 0
	for m in re.search_all(文本):
		结果 += 文本.substr(last, m.get_start() - last)
		结果 += 回调.call(m)
		last = m.get_end()
	结果 += 文本.substr(last)
	return 结果

func _回调裸类名(m: RegExMatch) -> String:
	var 类名 := m.get_string(1)
	return "[url=%s]%s[/url]" % [类名, 节点数据库.翻译表.get(类名, 类名)]

func _回调带类型(m: RegExMatch) -> String:
	var 引用 := m.get_string(2)
	var 点 := 引用.find(".")
	var 类名 := 引用
	var 剩余 := ""
	if 点 != -1:
		类名 = 引用.substr(0, 点)
		剩余 = 引用.substr(点)
	return "[url=%s]%s%s[/url]" % [引用, 节点数据库.翻译表.get(类名, 类名), 剩余]

func _按类名查找(类名: String) -> 节点数据库.节点条目:
	for 条目 in 全部类型:
		if 条目.类名 == 类名:
			return 条目
	return null

# ============================================================
# 创建节点
# ============================================================
func _确认创建() -> void:
	var 类名 := 获取选中类名()
	if 类名.is_empty():
		return
	var 条目 := _按类名查找(类名)
	if 条目 == null or not 条目.可实例化:
		return
	_创建节点(条目)

func _创建节点(条目: 节点数据库.节点条目) -> void:
	var child: Node = null
	if 条目.来源 == 节点数据库.来源自定义:
		if 条目.脚本路径.is_empty():
			return
		var 脚本 := load(条目.脚本路径)
		if 脚本 == null:
			return
		child = 脚本.new()
	else:
		child = ClassDB.instantiate(条目.类名)
	if child == null:
		return

	# 设置中文名（add_child 时会自动处理重名加序号）
	child.name = 条目.显示名

	var scene_root := EditorInterface.get_edited_scene_root()
	var undo_redo := EditorInterface.get_editor_undo_redo()

	if scene_root == null:
		# 空场景：创建为场景根节点
		EditorInterface.add_root_node(child)
	else:
		var 父 := _获取父节点()
		undo_redo.create_action("创建节点")
		undo_redo.add_do_method(父, "add_child", child, true)
		undo_redo.add_do_method(child, "set_owner", scene_root)
		undo_redo.add_do_reference(child)
		undo_redo.add_undo_method(父, "remove_child", child)
		undo_redo.commit_action()

	# 记录最近使用
	_记录最近(条目.类名)

	# 选中新节点
	var selection := EditorInterface.get_selection()
	selection.clear()
	selection.add_node(child)

	hide()

func _获取父节点() -> Node:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return null
	var 选中 := EditorInterface.get_selection().get_selected_nodes()
	if 选中.size() > 0:
		return 选中[0]
	return scene_root

# ============================================================
# 收藏
# ============================================================
func _收藏切换() -> void:
	var 类名 := 获取选中类名()
	if 类名.is_empty():
		return
	if 类名 in 收藏列表:
		收藏列表.erase(类名)
		收藏按钮.set_pressed(false)
	else:
		收藏列表.append(类名)
		收藏按钮.set_pressed(true)
	_保存收藏()
	更新收藏树()

func 更新收藏树() -> void:
	收藏树.clear()
	var 根 := 收藏树.create_item()
	for 类名 in 收藏列表:
		var item := 收藏树.create_item(根)
		item.set_text(0, 节点数据库.翻译表.get(类名, 类名))
		item.set_icon(0, 节点数据库.获取图标(类名))
		item.set_metadata(0, 类名)

func _收藏选中() -> void:
	var item := 收藏树.get_selected()
	if item == null:
		return
	搜索框.text = item.get_metadata(0)
	更新过滤按钮状态()
	更新搜索()

func _收藏激活() -> void:
	_收藏选中()
	_确认创建()

# ============================================================
# 最近使用
# ============================================================
func _记录最近(类名: String) -> void:
	最近使用列表.erase(类名)
	最近使用列表.push_front(类名)
	最近使用列表 = 最近使用列表.slice(0, 15)
	_保存最近()
	更新最近列表()

func 更新最近列表() -> void:
	最近列表.clear()
	for 类名 in 最近使用列表:
		var idx := 最近列表.add_item(节点数据库.翻译表.get(类名, 类名), 节点数据库.获取图标(类名))
		最近列表.set_item_metadata(idx, 类名)

func _最近选中(_idx: int) -> void:
	var 类名 := String(最近列表.get_item_metadata(_idx))
	if 类名.is_empty():
		return
	搜索框.text = 类名
	更新过滤按钮状态()
	更新搜索()

func _最近激活(_idx: int) -> void:
	_最近选中(_idx)
	_确认创建()

# ============================================================
# 类型过滤
# ============================================================
func _过滤切换(id: int) -> void:
	var popup := 过滤按钮.get_popup()
	popup.toggle_item_checked(id)
	类型过滤[id] = popup.is_item_checked(id)
	_保存过滤()
	更新搜索()

func 更新过滤按钮状态() -> void:
	var popup := 过滤按钮.get_popup()
	popup.set_item_checked(过滤内置, 类型过滤[过滤内置])
	popup.set_item_checked(过滤自定义, 类型过滤[过滤自定义])
	popup.set_item_checked(过滤编辑器, 类型过滤[过滤编辑器])
	var 有变化: bool = (not 类型过滤[过滤内置] or not 类型过滤[过滤自定义] or 类型过滤[过滤编辑器])
	重置过滤按钮.visible = 有变化
	过滤按钮.disabled = not 搜索框.text.strip_edges().is_empty()

func _重置过滤() -> void:
	类型过滤[过滤内置] = true
	类型过滤[过滤自定义] = true
	类型过滤[过滤编辑器] = false
	_保存过滤()
	更新过滤按钮状态()
	更新搜索()

# ============================================================
# 持久化（支持 全局 / 仅当前项目）
# ============================================================
func _当前范围() -> String:
	var settings := EditorInterface.get_editor_settings()
	if settings.has_setting("中文节点选择器/保存范围"):
		return settings.get_setting("中文节点选择器/保存范围")
	return "global"

func _保存数据(键: String, 数据: Variant) -> void:
	var settings := EditorInterface.get_editor_settings()
	if _当前范围() == "global":
		settings.set_setting("中文节点选择器/%s" % 键, 数据)
	else:
		settings.set_project_metadata("中文节点选择器", 键, 数据)

func _读取数据(键: String, 默认: Variant) -> Variant:
	var settings := EditorInterface.get_editor_settings()
	if _当前范围() == "global":
		if settings.has_setting("中文节点选择器/%s" % 键):
			return settings.get_setting("中文节点选择器/%s" % 键)
		return 默认
	return settings.get_project_metadata("中文节点选择器", 键, 默认)

func _保存收藏() -> void:
	_保存数据(收藏树设置键, 收藏列表)

func 加载收藏() -> void:
	var 数据 = _读取数据(收藏树设置键, [])
	收藏列表 = []
	for 类名 in 数据:
		收藏列表.append(String(类名))

func _保存最近() -> void:
	_保存数据(最近设置键, 最近使用列表)

func 加载最近() -> void:
	var 数据 = _读取数据(最近设置键, [])
	最近使用列表 = []
	for 类名 in 数据:
		最近使用列表.append(String(类名))

func _保存过滤() -> void:
	_保存数据(过滤设置键, 类型过滤)

func 加载过滤() -> void:
	var 数据 = _读取数据(过滤设置键, {})
	if 数据 is Dictionary:
		for 键 in 数据:
			类型过滤[int(键)] = bool(数据[键])

# ============================================================
# 设置入口 / 捐赠
# ============================================================
func _打开设置() -> void:
	if 设置对话框实例 == null or not is_instance_valid(设置对话框实例):
		设置对话框实例 = 设置对话框.new()
		get_parent().add_child(设置对话框实例)
		设置对话框实例.设置已更改.connect(_刷新显示)
	# 已打开则置顶，否则弹出
	if 设置对话框实例.visible:
		设置对话框实例.grab_focus()
	else:
		设置对话框实例.打开()

func _刷新显示() -> void:
	节点数据库.重新加载自定义翻译()
	全部类型 = 节点数据库.扫描类型(基础类型)
	if visible:
		更新搜索()
		更新收藏树()
		更新最近列表()

