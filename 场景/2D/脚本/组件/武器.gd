extends Node
class_name 武器

## 武器名称
@export var 武器名称: String = ""
## 基础伤害
@export var 伤害: int = 10

signal 攻击时(伤害值: int)

## 打一次，把伤害发出去
func 攻击() -> void:
	攻击时.emit(伤害)
