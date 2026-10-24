extends Node   # ★ 必须是 Node2D，Node 没有 rotation
class_name 武器_2D

@export var 武器名称: String = ""
@export var 伤害: int = 10
@export var 武器本体:Node2D=null

signal 攻击时(伤害值: int)

func _ready() -> void:
	if 武器本体==null:武器本体=self.get_parent()

func 攻击() -> void:
	攻击时.emit(伤害)


## ★ 只由服务端调用（通过 远程函数调用 的 RPC 入口进来）
func 修改角度(_方向: Vector2, 角度: float) -> void:
	武器本体.rotation = 角度
	# 不用手动广播——属性同步会自动把 rotation 发给所有客户端
