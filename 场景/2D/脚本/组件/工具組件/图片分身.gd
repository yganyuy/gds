@tool
extends Node2D

@export_range(0.01, 100, 0.01) var 横向份数: float = 1.0:
	set(值):
		横向份数 = maxf(0.01, 值)
		更新平铺区域()

@export_range(0.01, 100, 0.01) var 纵向份数: float = 1.0:
	set(值):
		纵向份数 = maxf(0.01, 值)
		更新平铺区域()

@export var 图片节点: Sprite2D:
	set(值):
		图片节点 = 值
		更新平铺区域()

@export var 碰撞形状: CollisionShape2D

# Godot 4.4+ 原生按钮；如果报 Callable 为 Nil，换成下面的布尔触发器
@export_tool_button("同步碰撞尺寸", "CollisionShape2D") var 同步碰撞按钮 = 同步碰撞尺寸
# 备用方案（4.3 及以下，或按钮 Bug 时使用）：
# @export var 同步碰撞: bool = false:
# 	set(值):
# 		if 值:
# 			同步碰撞尺寸()
# 			同步碰撞 = false

var _上次纹理: Texture2D
var _上次居中: bool

func _ready() -> void:
	更新平铺区域()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if 图片节点 == null:
		return
	if 图片节点.texture != _上次纹理 or 图片节点.centered != _上次居中:
		_上次纹理 = 图片节点.texture
		_上次居中 = 图片节点.centered
		更新平铺区域()

func 计算总尺寸() -> Vector2:
	if 图片节点 == null or 图片节点.texture == null:
		return Vector2.ZERO
	return 图片节点.texture.get_size() * Vector2(横向份数, 纵向份数)

func 更新平铺区域() -> void:
	if 图片节点 == null or 图片节点.texture == null:
		return
	图片节点.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	图片节点.region_enabled = true
	图片节点.region_rect = Rect2(Vector2.ZERO, 计算总尺寸())

func 同步碰撞尺寸() -> void:
	if 碰撞形状 == null:
		return
	var 总尺寸 := 计算总尺寸()
	if 总尺寸 == Vector2.ZERO:
		return

	# ★ 关键一步：不管当前 shape 是否被共享，先复制一份独立的
	if 碰撞形状.shape == null:
		碰撞形状.shape = RectangleShape2D.new()
	else:
		碰撞形状.shape = 碰撞形状.shape.duplicate() as RectangleShape2D

	# 标记为场景局部，子场景实例化时也自动独立
	碰撞形状.shape.resource_local_to_scene = true

	if not (碰撞形状.shape is RectangleShape2D):
		push_warning("碰撞形状不是 RectangleShape2D，无法自动同步尺寸")
		return
	碰撞形状.shape.size = 总尺寸

	# 位置对齐（只有碰撞形状是图片节点或其兄弟节点时才动）
	var 偏移: Vector2 = Vector2.ZERO
	if 图片节点 != null and not 图片节点.centered:
		偏移 = 总尺寸 / 2.0

	if 碰撞形状.get_parent() == 图片节点:
		碰撞形状.position = 偏移
	elif 图片节点 != null and 碰撞形状.get_parent() == 图片节点.get_parent():
		碰撞形状.position = 图片节点.position + 偏移
