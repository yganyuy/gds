@tool
extends Window
## 支持作者弹窗

const QrCode := preload("res://addons/ChineseNodeSelector/qr/qr_code.gd")  # QR 库：github.com/Greaby/godot-qrcode-generator（MIT）

# 内部参数，请勿改动。
const _参 := "ZNodeSelector_2026_加密混淆"
const _微信 := "2d361f5e4a7c035e0353113d4b1b775e774439ccf194a712285c093d3a32073d2c371f24147664710612c593b4b56f3b0025162b52162f082c0747080156557466eeb781a33176255614"
const _支付宝 := "323a1b1416694a4314115a0e1e3642514b183ccfabd8a031365e51566a5c0a0e06195c1d2a41065f5f3bc9f1c6"

func _还原(码: String) -> String:
	var b: PackedByteArray = 码.hex_decode()
	for i in range(b.size()):
		b[i] = b[i] ^ _参.unicode_at(i % _参.length())
	return b.get_string_from_utf8()

var 微信按钮: Button
var 支付宝按钮: Button
var 二维码显示: TextureRect
var 状态标签: Label
var 当前来源 := "微信"

# 高 DPI：窗口尺寸随编辑器缩放（Editor Scale）放大，否则显示不全
func _编辑器缩放() -> float:
	if not Engine.is_editor_hint():
		return 1.0
	return EditorInterface.get_editor_scale()

func _init() -> void:
	title = "关于作者"
	size = Vector2i(360, 500) * _编辑器缩放()
	min_size = Vector2i(340, 460) * _编辑器缩放()
	exclusive = false
	close_requested.connect(hide)
	_build_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var 标题 := Label.new()
	标题.text = "感谢使用「中文节点选择器」"
	标题.set_theme_type_variation("HeaderLarge")
	标题.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(标题)

	var 副标题 := Label.new()
	副标题.text = "本插件完全免费。\n如果你愿意，可以自愿扫码表达支持，\n这完全出于自愿，不影响插件的任何功能。"
	副标题.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	副标题.modulate.a = 0.7
	root.add_child(副标题)

	root.add_child(HSeparator.new())

	# 微信 / 支付宝切换按钮
	var 按钮行 := HBoxContainer.new()
	按钮行.add_theme_constant_override("separation", 8)
	按钮行.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	root.add_child(按钮行)

	微信按钮 = Button.new()
	微信按钮.text = "微信"
	微信按钮.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	微信按钮.set_toggle_mode(true)
	微信按钮.pressed.connect(func(): _显示二维码("微信"))
	按钮行.add_child(微信按钮)

	支付宝按钮 = Button.new()
	支付宝按钮.text = "支付宝"
	支付宝按钮.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	支付宝按钮.set_toggle_mode(true)
	支付宝按钮.pressed.connect(func(): _显示二维码("支付宝"))
	按钮行.add_child(支付宝按钮)

	# 二维码显示区
	二维码显示 = TextureRect.new()
	二维码显示.set_custom_minimum_size(Vector2(260, 260) * _编辑器缩放())
	二维码显示.set_expand_mode(TextureRect.EXPAND_IGNORE_SIZE)
	二维码显示.set_stretch_mode(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	二维码显示.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	二维码显示.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	root.add_child(二维码显示)

	状态标签 = Label.new()
	状态标签.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	状态标签.modulate.a = 0.6
	root.add_child(状态标签)

	var 提示 := Label.new()
	提示.text = "二维码由 QR-Code-generator 生成 · MIT License\ngithub.com/Greaby/godot-qrcode-generator"
	提示.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	提示.modulate.a = 0.5
	root.add_child(提示)

func 打开() -> void:
	popup_centered()
	_显示二维码(当前来源)

func _显示二维码(来源: String) -> void:
	当前来源 = 来源
	微信按钮.set_pressed_no_signal(来源 == "微信")
	支付宝按钮.set_pressed_no_signal(来源 == "支付宝")

	var 链接 := _还原(_微信) if 来源 == "微信" else _还原(_支付宝)
	状态标签.text = "正在生成…"
	二维码显示.texture = null

	var qr := QrCode.new()
	var 矩阵: Array = qr.get_data(链接)
	if 矩阵 != null and 矩阵.size() > 0:
		# 自己按整数像素放大渲染，保证每个模块方正清晰
		二维码显示.texture = ImageTexture.create_from_image(_渲染二维码(矩阵, int(260 * _编辑器缩放())))
		状态标签.text = ""
	else:
		状态标签.text = "生成失败"

# 把模块矩阵渲染为高清 Image（每模块整数像素 + 4 模块白边）
func _渲染二维码(矩阵: Array, 目标像素: int) -> Image:
	var 模块数 := 矩阵.size()
	var 边距 := 4
	var 总模块 := 模块数 + 边距 * 2
	var 模块像素 := maxi(1, 目标像素 / 总模块)
	var 实际 := 总模块 * 模块像素
	var img := Image.create(实际, 实际, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in range(模块数):
		for x in range(模块数):
			if 矩阵[y][x]:
				var px := (x + 边距) * 模块像素
				var py := (y + 边距) * 模块像素
				for dy in range(模块像素):
					for dx in range(模块像素):
						img.set_pixel(px + dx, py + dy, Color.BLACK)
	return img
