extends TextureButton
class_name 跳跃按钮

## 键盘跳跃键（留空 = 不监听键盘）
@export var 键盘跳跃动作: StringName = &""##这两种满足其一的条件就可以 但第一个这个属性的 优先级最高 
@export var 跳跃按键: Key = KEY_SPACE

var 键盘上一帧按下: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE

func _process(_delta) -> void:
	var 现在按下 := Input.is_action_pressed(键盘跳跃动作)
	if 键盘跳跃动作==&"":
		现在按下=Input.is_physical_key_pressed(跳跃按键)
	
	#if 键盘跳跃动作 == &"":
		#return
	
	if 现在按下 == 键盘上一帧按下:
		return
	键盘上一帧按下 = 现在按下
	if 现在按下:
		_尝试跳跃()
	else:
		_尝试取消跳跃()

func _on_button_down() -> void:##当按钮按下时
	_尝试跳跃()

func _on_button_up() -> void:##当按钮抬起时
	_尝试取消跳跃()

# ★ 独立函数：拿到"本地玩家"的移动组件（找不到返回 null）
func _取本地移动组件() -> 移动组件:
	if 玩家当前角色 == null or 玩家当前角色.玩家角色.size() <= 0:
		return null
	var 玩家 = 玩家当前角色.玩家角色[0]
	if 玩家 == null or not is_instance_valid(玩家):
		return null
	var 组件 = 玩家.get_node_or_null("移动组件")
	return 组件 as 移动组件

func _尝试跳跃() -> void:
	var 组件 = _取本地移动组件()
	if 组件 != null:
		组件.开始跳跃()

func _尝试取消跳跃() -> void:
	var 组件 = _取本地移动组件()
	if 组件 != null:
		组件.取消跳跃()
