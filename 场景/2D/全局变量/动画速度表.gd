extends RefCounted
class_name 动画速度表
## 速度 + 渐变时长配置
## 全部通过类名访问：动画速度表.获取倍率("玩家", "移动")

#=============================== 速度配置 ===============================
static var 速度配置: Dictionary = {
	"默认": {
		"站立": 1.0, "移动": 1.0, "跳跃_起跳": 1.0,
		"半空中": 1.0, "落地": 1.0, "行走": 1.0,
	},
	"玩家": {
		"站立": 0.5, "移动": 1.2, "跳跃_起跳": 1.5,
		"半空中": 1.0, "落地": 1.0, "行走": 1.0,
	},
	"敌人A": {
		"站立": 1.0, "移动": 2.0, "跳跃_起跳": 1.8,
	},
}

static var 默认配置名: String = "默认"
static var 默认倍率: float = 1.0

#=============================== 渐变时长配置 ===============================
## 结构：配置名 → 目标动画 → 来源动画 → 秒
## - 来源写 "默认" 表示"任何来源→该目标"
## - 不写来源（只有目标动画）不合法，必须至少一个 "默认" 或明确来源
static var 渐变时长: Dictionary = {
	"默认": {
		"站立":     {"默认": 0.15},              # 任何 → 站立 = 0.15
		"移动":     {"默认": 0.10},              # 任何 → 移动 = 0.10
		"跳跃_起跳": {"默认": 0.05},              # 任何 → 跳跃 = 0.05
		"半空中":   {"默认": 0.08},
		"落地":     {"默认": 0.12},
		"行走":     {"默认": 0.10},
	},
	"玩家": {
		# 精确指定"从 X → 到 Y"（会覆盖默认）
		"站立": {
			"移动":     0.15,   # 移动 → 站立（刹车感）
			"跳跃_起跳": 0.1,   # 跳跃 → 站立（落地缓冲）
			"默认":     0.15,
		},
		"移动": {
			"站立": 0.10,       # 站立 → 移动（起步利落）
			"默认": 0.10,
		},
		"跳跃_起跳": {"默认": 0.1},
	},
	"敌人A": {
		"站立": {"默认": 0.15},
		"移动": {"默认": 0.12},
	},
}

## 表里全都没配时，最终兜底的渐变时长（秒）
static var 默认渐变时长: float = 0.10

#=============================== 速度查询 ===============================
static func 获取倍率(配置名: String, 动画名: String) -> float:
	var 表: Dictionary = 速度配置.get(配置名, {})
	if 表.is_empty() and 配置名 != 默认配置名:
		表 = 速度配置.get(默认配置名, {})
	if 表.has(动画名):
		var v = 表[动画名]
		if v is float or v is int:
			return float(v)
	if 表.has("默认"):
		var d = 表["默认"]
		if d is float or d is int:
			return float(d)
	return 默认倍率

static func 设置倍率(配置名: String, 动画名: String, 倍率: float) -> void:
	if not 速度配置.has(配置名):
		速度配置[配置名] = {}
	速度配置[配置名][动画名] = 倍率

static func 移除倍率(配置名: String, 动画名: String) -> void:
	if 速度配置.has(配置名):
		速度配置[配置名].erase(动画名)

static func 获取配置(配置名: String) -> Dictionary:
	return 速度配置.get(配置名, {}).duplicate()

static func 获取所有配置名() -> Array:
	return 速度配置.keys()

static func 是否有配置(配置名: String) -> bool:
	return 速度配置.has(配置名)

static func 创建配置(新配置名: String, 复制自: String = 默认配置名) -> void:
	if 速度配置.has(新配置名):
		return
	if 速度配置.has(复制自):
		速度配置[新配置名] = 速度配置[复制自].duplicate(true)
	else:
		速度配置[新配置名] = {}

static func 删除配置(配置名: String) -> bool:
	if 配置名 == 默认配置名:
		push_warning("[动画速度表] 不能删除默认配置")
		return false
	return 速度配置.erase(配置名)

#=============================== 渐变查询 ===============================
## 查"从 来源 → 到 目标"的渐变秒数
## 优先级：本配置精确 > 本配置"默认" > 默认配置精确 > 默认配置"默认" > 全局默认
static func 获取渐变时长(配置名: String, 来源: String, 目标: String) -> float:
	var r := _查单配置(配置名, 来源, 目标)
	if r >= 0.0:
		return r
	if 配置名 != 默认配置名:
		r = _查单配置(默认配置名, 来源, 目标)
		if r >= 0.0:
			return r
	return 默认渐变时长

static func _查单配置(配置名: String, 来源: String, 目标: String) -> float:
	if not 渐变时长.has(配置名):
		return -1.0
	var 目标表 = 渐变时长[配置名].get(目标, {})
	if 目标表.is_empty():
		return -1.0
	# 精确：从 来源 → 到 目标
	if 来源 != "" and 目标表.has(来源):
		var v = 目标表[来源]
		if v is float or v is int:
			return float(v)
	# 兜底：默认 → 到 目标
	if 目标表.has("默认"):
		var d = 目标表["默认"]
		if d is float or d is int:
			return float(d)
	return -1.0

## 设置某配置下"从 来源 → 到 目标"的时长
## 来源填 "默认" 表示"任何来源→目标"
static func 设置渐变时长(配置名: String, 来源: String, 目标: String, 秒数: float) -> void:
	if not 渐变时长.has(配置名):
		渐变时长[配置名] = {}
	if not 渐变时长[配置名].has(目标):
		渐变时长[配置名][目标] = {}
	渐变时长[配置名][目标][来源] = 秒数

static func 移除渐变时长(配置名: String, 来源: String, 目标: String) -> void:
	if 渐变时长.has(配置名) and 渐变时长[配置名].has(目标):
		渐变时长[配置名][目标].erase(来源)
