extends Node
class_name 生命组件

## 生命组件 - 管理实体的生命值和受伤逻辑

# ============ 枚举定义 ============
enum 阵营类型 {
	中立,      # 不会被任何阵营伤害
	友好,      # 友方阵营
	敌对,      # 敌对阵营
	敌对中立,   # 可攻击非中立任何阵营，也会被所有非中立攻击
	玩家,      # 玩家阵营
	敌人,      # 敌人阵营
	NPC,       # NPC阵营
	环境       # 环境物体
}

# ============ 导出属性 ============
@export var 阵营: 阵营类型 = 阵营类型.中立
@export var 最大血量: float = 100.0
@export var 当前血量: float = 100.0
@export var 受击无敌时长: float = 0.5  # 秒
@export var 启用: bool = true
@export var 受击退比例: float = 1.0  # 1.0 = 100%

# ============ 内部变量 ============
var _无敌计时器: float = 0.0
var _是否无敌: bool = false

# ============ 信号定义 ============
signal 受击(伤害: float, 伤害来源: Node, 击退方向: Vector2)
signal 死亡(伤害来源: Node)
signal 血量变化(旧血量: float, 新血量: float, 差值: float)
signal 血量恢复(恢复量: float, 新血量: float)
signal 血量降低(降低量: float, 新血量: float)
signal 无敌开始()
signal 无敌结束()


func _ready():
	# 初始化血量
	当前血量 = clamp(当前血量, 0, 最大血量)


func _process(delta):
	# 更新无敌计时器
	if _是否无敌 and _无敌计时器 > 0:
		_无敌计时器 -= delta
		if _无敌计时器 <= 0:
			_是否无敌 = false
			无敌结束.emit()


# ============ 伤害处理 ============

## 受到伤害
func 受伤害(伤害量: float, 伤害来源: Node = null, 击退方向: Vector2 = Vector2.ZERO) -> bool:
	if not 启用:
		return false
	
	if _是否无敌:
		return false
	
	if 当前血量 <= 0:
		return false
	
	# 应用伤害
	var 旧血量 = 当前血量
	当前血量 = max(0, 当前血量 - 伤害量)
	
	# 触发信号
	var 实际伤害 = 旧血量 - 当前血量
	受击.emit(实际伤害, 伤害来源, 击退方向)
	血量变化.emit(旧血量, 当前血量, -实际伤害)
	血量降低.emit(实际伤害, 当前血量)
	
	# 无敌处理
	if 受击无敌时长 > 0:
		_是否无敌 = true
		_无敌计时器 = 受击无敌时长
		无敌开始.emit()
	
	# 死亡检测
	if 当前血量 <= 0:
		死亡.emit(伤害来源)
		return true
	
	return true


## 恢复血量
func 恢复血量(恢复量: float) -> float:
	if not 启用:
		return 0
	
	if 当前血量 <= 0:
		return 0
	
	var 旧血量 = 当前血量
	var 实际恢复 = min(恢复量, 最大血量 - 当前血量)
	当前血量 += 实际恢复
	
	if 实际恢复 > 0:
		血量变化.emit(旧血量, 当前血量, 实际恢复)
		血量恢复.emit(实际恢复, 当前血量)
	
	return 实际恢复


## 设置血量（直接设置，不触发伤害/恢复信号）
func 设置血量(新血量: float):
	var 旧血量 = 当前血量
	当前血量 = clamp(新血量, 0, 最大血量)
	if 旧血量 != 当前血量:
		血量变化.emit(旧血量, 当前血量, 当前血量 - 旧血量)


# ============ 阵营判定 ============

## 检查是否可以攻击目标
func 可以攻击(目标: Node) -> bool:
	if not 目标:
		return false
	
	# 获取目标的阵营组件
	var 目标生命组件 = _获取生命组件(目标)
	if not 目标生命组件:
		return false
	
	if not 目标生命组件.启用:
		return false
	
	if 目标生命组件.当前血量 <= 0:
		return false
	
	return _阵营可以攻击(阵营, 目标生命组件.阵营)


## 静态阵营判定
static func _阵营可以攻击(攻击者阵营: 阵营类型, 目标阵营: 阵营类型) -> bool:
	# 中立不能被任何阵营攻击
	if 目标阵营 == 阵营类型.中立:
		return false
	
	# 敌对中立：可攻击所有非中立阵营
	if 攻击者阵营 == 阵营类型.敌对中立:
		return 目标阵营 != 阵营类型.中立
	
	# 敌对中立也会被所有非中立攻击
	if 目标阵营 == 阵营类型.敌对中立:
		return 攻击者阵营 != 阵营类型.中立
	
	# 相同阵营不能攻击（除敌对中立外）
	if 攻击者阵营 == 目标阵营:
		return false
	
	# 不同阵营可以攻击
	return true


# ============ 辅助方法 ============

## 获取节点上的生命组件
static func _获取生命组件(节点: Node) -> 生命组件:
	if 节点 is 生命组件:
		return 节点
	
	# 尝试获取子节点中的生命组件
	for 子节点 in 节点.get_children():
		if 子节点 is 生命组件:
			return 子节点
	
	return null


## 获取血量百分比
func 获取血量百分比() -> float:
	return 当前血量 / 最大血量


## 是否存活
func 是否存活() -> bool:
	return 当前血量 > 0


## 重置无敌状态
func 重置无敌():
	_是否无敌 = false
	_无敌计时器 = 0


## 获取无敌状态
func 是否无敌() -> bool:
	return _是否无敌


# ============ 调试方法 ============
func _get_configuration_warnings() -> PackedStringArray:
	var 警告 = PackedStringArray()
	if not get_parent():
		警告.append("生命组件必须作为子节点")
	return 警告
