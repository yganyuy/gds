@tool
extends Line2D
class_name 动态尾巴2D


enum {
	上一个点 = 0,
	位置 = 1,
	旋转 = 2,
	角动量 = 3,
}


## 分段数量
@export_range(1, 10) var 分段数量: int = 5 :set = _设置分段数量
## 每段长度
@export var 段长度: float = 30.0
## 弯曲程度（弧度，-90°到90°）
@export_range(-1.57, 1.57) var 弯曲度: float = 0.0
## 尾部弯曲递增指数（越往后越弯）
@export_range(-3.0, 3.0) var 弯曲指数: float = 0.0
## 每段最大角度（实际计算值）
@export_range(0.0, 180.0, 0.01, "radians") var 最大角度: float = TAU / 2
## 超过最大角度后，回正速度（弧度/秒）
@export_range(0, 6.28) var 回正速度: float = 0.0
## 尾巴硬度（越大越僵硬）
@export var 硬度: float = 20.0
## 尾部硬度递减（越往后越软）
@export var 硬度衰减: float = 0.0
## 硬度衰减指数
@export var 硬度衰减指数: float = 1.0
## 重力加速度（像素/秒²）
@export var 重力 := Vector2(0, 0)
## 阻尼系数（减慢摆动速度）
@export var 阻尼: float = 5.0
## 每段最大角速度（弧度/秒）
@export var 最大角动量: float = 25.13
## 曲线细分平滑度（值越大越平滑，不要设为1）
@export_range(0, 10) var 细分: int = 2
## 在起点前增加一个额外段，防止断开
@export var 额外起始段 := false
## 额外起始段的长度
@export var 额外起始段长度: float = 10.0
## 是否对额外起始段进行细分
@export var 细分额外起始段 := true
## 仅当节点和所有父级可见时才处理
@export var 仅可见时处理 := true


var 物理点: Array


func _ready():
	重置()


func _physics_process(delta):
	if 仅可见时处理 and not is_visible_in_tree():
		return
	for i in range(物理点.size()):
		if i == 0:
			_处理根节点(物理点[i], delta)
		else:
			_处理节点(物理点[i], delta, i)
	_更新线条()


## 删除所有现有物理点，并添加指定数量的新点
func 重置(点数量: int = 分段数量 + 1) -> void:
	物理点 = []
	var 起始位置 := get_global_position()
	var 当前位置 := 起始位置
	var 偏移向量 := Vector2(_获取真实段长度(), 0).rotated(get_global_rotation())
	for i in range(点数量):
		偏移向量 = 偏移向量.rotated(_获取真实弯曲度())
		当前位置 += 偏移向量
		var 新点 := [
			null,
			当前位置,
			偏移向量.angle(),
			0.0,
		]
		if i != 0:
			新点[上一个点] = 物理点[-1]
		物理点.append(新点)


## 返回尾巴所有点的全局位置
func 获取全局点位置() -> PackedVector2Array:
	var 输出 := PackedVector2Array()
	for 点 in 物理点:
		输出.append(点[位置])
	return 输出


func _处理节点(点: Array, delta: float, 索引: int):
	# 计算期望方向和旋转
	var 方向: Vector2 = 点[上一个点][位置].direction_to(点[位置])
	var 点旋转: float = 方向.angle()
	var 理想旋转: float = 点[上一个点][旋转] + _获取真实弯曲度() * pow(float(索引), 弯曲指数)
	理想旋转 = fmod(理想旋转, TAU)
	var 旋转差值: float = _角度差值(理想旋转, 点旋转)
	
	# 计算硬度、重力和阻尼力
	var 实际硬度 = (硬度 - pow(float(索引), 硬度衰减指数) * 硬度衰减)
	实际硬度 = max(0, 实际硬度)
	var 力: float = _带符号开方(旋转差值) * 实际硬度
	力 += 重力.length() * cos(点旋转 - 重力.angle() + TAU / 4)
	if sign(力) != sign(点[角动量]):
		力 *= 阻尼
	
	# 用力更新角动量
	点[角动量] += 力 * delta
	点[角动量] = clamp(点[角动量], -最大角动量, 最大角动量)
	点旋转 += 点[角动量] * delta
	
	# 限制角度，如果超过最大角度则施加回正速度
	if abs(旋转差值) > 最大角度:
		点旋转 += 旋转差值 - abs(最大角度) * sign(旋转差值)
		if sign(点[角动量]) != sign(旋转差值) or abs(点[角动量]) < 回正速度:
			点[角动量] = 回正速度 * sign(旋转差值)
	
	# 写回计算结果
	点[旋转] = 点旋转
	点[位置] = 点[上一个点][位置] + Vector2(_获取真实段长度(), 0).rotated(点旋转)


func _处理根节点(点: Array, delta: float):
	点[位置] = get_global_position()
	点[旋转] = get_global_rotation()


func _更新线条():
	var 新线条点 := PackedVector2Array()
	if 额外起始段 and 细分额外起始段:
		新线条点.append(Vector2(-额外起始段长度, 0))
	for 点 in 物理点:
		新线条点.append(to_local(点[位置]))
	新线条点 = _贝塞尔插值(新线条点, 细分)
	if 额外起始段 and not 细分额外起始段:
		新线条点.insert(0, Vector2(-额外起始段长度, 0))
	points = 新线条点


func _贝塞尔插值(线条: PackedVector2Array, 细分: int) -> PackedVector2Array:
	if 细分 < 1: return 线条
	if 线条.size() < 3: return 线条
	var 输出 := PackedVector2Array()
	for i in range(线条.size() - 1):
		var a: Vector2
		var b: Vector2
		var c: Vector2
		var 实际细分: int
		a = 线条[i]
		b = 线条[i + 1]
		var c索引 := i + 2
		if c索引 > 线条.size() - 1:
			var 前一个 := 线条[i - 1]
			var 角度 := _角度差值((b - a).angle(), (a - 前一个).angle())
			c = b + (b - a).rotated(角度)
			实际细分 = (细分) / 2 + 1
		else:
			c = 线条[c索引]
			实际细分 = 细分
		var 真实a = lerp(a, b, 0.5) if i != 0 else a
		var 真实c = lerp(b, c, 0.5)
		for o in range(实际细分):
			var t: float = 1.0 / 细分 * o
			var ab: Vector2 = lerp(真实a, b, t)
			var bc: Vector2 = lerp(b, 真实c, t)
			输出.append(lerp(ab, bc, t))
	return 输出


func _角度差值(角度a: float, 角度b: float) -> float:
	var 差值 := 角度a - 角度b
	if abs(差值) > TAU / 2.0:
		差值 -= TAU * sign(差值)
	return 差值


func _带符号开方(值: float) -> float:
	return sqrt(abs(值)) * sign(值)


func _获取真实段长度() -> float:
	return 段长度 * get_global_scale().x


func _获取真实弯曲度() -> float:
	var 全局变换 = get_global_transform()
	var 行列式 = 全局变换.x.x * 全局变换.y.y - 全局变换.x.y * 全局变换.y.x
	return 弯曲度 * sign(行列式)


func _设置分段数量(值: float):
	分段数量 = 值
	重置()
