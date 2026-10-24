extends Node
class_name 移动组件_2D

## 依赖（Autoload）：
##   rpc联机方法 : wang_luo_id (0=单机 / 1=服务端 / 其他=客户端)
##   服务器调用  : 客户端→服务端 统一调用通道（远程函数调用.gd）
##   物理组件_2D : 速度向量 / 重力 / 物理模式 / 目标节点
##   实体功能    : 物体表 / 查找器
##
## 建议：把 服务器调用.校验权限 设为 true，只有物体 pid 主人才能操作

#=============================== 导出 ===============================
@export var 最小速度: int = 0
@export var 最大速度: int = 300
@export var 加速度: int = 1000
@export var 减速度: int = 1500
@export var 引用的物理组件: 物理组件_2D = null
@export var 跳跃最大高度: float = 100
@export var 跳跃段数: int = 1
@export_range(0.0, 1.0) var 取消跳跃保留比例: float = 0.5

#=============================== 状态 ===============================
var 当前输入方向: Vector2 = Vector2.ZERO
var 正在移动: bool = false
var 当前跳跃段数: int = 0
var 正在跳跃: bool = false
var 父节点: Node = null
var 初始化: bool = false

#=============================== 信号 ===============================
signal 移动开始时(移动状态: bool, 跳跃状态: bool)
signal 移动结束时(移动状态: bool, 跳跃状态: bool)
signal 跳跃开始时(移动状态: bool, 跳跃状态: bool)
signal 跳跃结束时(移动状态: bool, 跳跃状态: bool)

#=============================== 生命周期 ===============================
func _ready() -> void:
	if 父节点 == null:
		父节点 = get_parent()
	if 引用的物理组件 == null:
		print(self, "未手动引用物理组件，已自动创建")
		var 新建 := 物理组件_2D.new()
		新建.目标节点 = 父节点
		add_child(新建)
		引用的物理组件 = 新建
	初始化 = true

func _physics_process(delta: float) -> void:
	if not _可执行():
		return
	_检测落地()
	_更新速度(delta)

func _可执行() -> bool:
	if not 初始化 or 引用的物理组件 == null:
		return false
	return rpc联机方法.wang_luo_id == 0 or rpc联机方法.wang_luo_id == 1

#=============================== 物理更新 ===============================
func _更新速度(delta: float) -> void:
	var 速度 := 引用的物理组件.速度向量
	var 平台 := 引用的物理组件.当前物理模式 == 物理组件_2D.物理模式.平台跳跃

	if 正在移动:
		var 目标 := 当前输入方向 * 最大速度
		var 步长 := 加速度 * delta
		速度.x = move_toward(速度.x, 目标.x, 步长)
		if not 平台:
			速度.y = move_toward(速度.y, 目标.y, 步长)
	else:
		var 步长 := 减速度 * delta
		速度.x = move_toward(速度.x, 0, 步长)
		if abs(速度.x) <= 最小速度: 速度.x = 0
		if not 平台:
			速度.y = move_toward(速度.y, 0, 步长)
			if abs(速度.y) <= 最小速度: 速度.y = 0

	引用的物理组件.速度向量 = 速度

#=============================== 状态 & 信号 ===============================
func _设置移动状态(新状态: bool) -> void:
	if 正在移动 == 新状态:
		return
	正在移动 = 新状态
	if 新状态:
		移动开始时.emit(正在移动, 正在跳跃)
	else:
		移动结束时.emit(正在移动, 正在跳跃)

func _触发跳跃开始() -> void:
	正在跳跃 = true
	跳跃开始时.emit(正在移动, 正在跳跃)

func _触发跳跃结束() -> void:
	if not 正在跳跃:
		return
	正在跳跃 = false
	跳跃结束时.emit(正在移动, 正在跳跃)

#=============================== 本地逻辑 ===============================
func 执行移动(输入向量: Vector2) -> void:
	if 输入向量.length_squared() > 0.000001:
		当前输入方向 = 输入向量.normalized()
		_设置移动状态(true)
	else:
		当前输入方向 = Vector2.ZERO

func _检测落地() -> void:
	var 实体 = 引用的物理组件.目标节点
	if 实体 == null or not (实体 is CharacterBody2D):
		return
	if 实体.is_on_floor() and 引用的物理组件.速度向量.y >= 0:
		当前跳跃段数 = 0
		_触发跳跃结束()

func _计算跳跃初速度() -> float:
	var 重力值: float = 引用的物理组件.重力
	if 重力值 <= 0.0:
		return 0.0
	return -sqrt(2.0 * 重力值 * 跳跃最大高度)

func _执行跳跃() -> void:
	if 当前跳跃段数 >= 跳跃段数:
		return
	当前跳跃段数 += 1
	引用的物理组件.速度向量.y = _计算跳跃初速度()
	_触发跳跃开始()

func _执行取消跳跃() -> void:
	if 正在跳跃 and 引用的物理组件.速度向量.y < 0:
		引用的物理组件.速度向量.y *= 取消跳跃保留比例
	_触发跳跃结束()

#=============================== 网络分发（唯一一处） ===============================
## 单机/服务端：本地直接执行；客户端：走"服务器调用"通道
func _远程执行(方法名: String, 参数: Array) -> void:
	if rpc联机方法.wang_luo_id == 0 or rpc联机方法.wang_luo_id == 1:
		callv(方法名, 参数)
		return
	var id := _取自身id()
	if id == -1:
		return
	远程函数调用.申请调用(id, "移动组件", 方法名, 参数)

func _取自身id() -> int:
	if 父节点 == null:
		return -1
	return 父节点.get_meta("id", -1)

#=============================== 对外接口（4 行搞定） ===============================
func 开始移动(输入向量: Vector2) -> void:
	_远程执行("执行移动", [输入向量])

func 结束移动() -> void:
	_远程执行("_设置移动状态", [false])

func 开始跳跃() -> void:
	_远程执行("_执行跳跃", [])

func 取消跳跃() -> void:
	_远程执行("_执行取消跳跃", [])
