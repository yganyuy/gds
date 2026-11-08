extends AnimationPlayer
class_name 玩家动画播放器
## 动画播放器封装
## - 配置名 决定用哪份速度表 / 渐变时长表
## - 混合秒数可覆盖，-1 表示查表
## - 同动画不重播
## - 信号：动画开始 / 动画播放完毕

signal 动画开始(动画名: String)
signal 动画播放完毕(动画名: String)

@export var 配置名: String = "默认"
@export var 调试: bool = true
@export_range(0.01, 10.0, 0.05) var 默认速度倍率: float = 1.0

var 当前速度倍率: float = 1.0

#=============================== 生命周期 ===============================
func _ready() -> void:
	if not animation_finished.is_connected(_内部_动画结束):
		animation_finished.connect(_内部_动画结束)
	if 配置名 == "":
		配置名 = 动画速度表.默认配置名
	if not 动画速度表.是否有配置(配置名):
		push_warning("[玩家动画播放器] 速度配置里没有 '%s'，自动从默认复制" % 配置名)
		动画速度表.创建配置(配置名)

#=============================== 对外接口 ===============================
## 播放动画
## 循环播放       : 意图提示；实际循环由资源 loop_mode 决定
## 覆盖倍率       : > 0 强制本次倍率；0 查速度表
## 覆盖混合秒数   : -1 = 查渐变表；0 = 硬切；> 0 = 用该秒数
func 播放动画(播放的动画名称: String, 循环播放: bool = true,
		覆盖倍率: float = 0.0, 覆盖混合秒数: float = -1.0) -> bool:
	if not has_animation(播放的动画名称):
		push_warning("[玩家动画播放器] 找不到动画: " + 播放的动画名称)
		return false

	var 目标倍率: float = 覆盖倍率 if 覆盖倍率 > 0.0 else _解析倍率(播放的动画名称)

	if current_animation == 播放的动画名称 and is_playing():
		_应用倍率(目标倍率)
		if 调试:
			print("[动画] 同动画倍率更新: ", 播放的动画名称, " → ", 目标倍率)
		return true

	# 来源必须在 play 之前记录
	var 来源: String = current_animation if is_playing() else ""

	# 混合秒数解析（动画时间维度）
	var 混合: float = 覆盖混合秒数
	if 混合 < 0.0:
		混合 = 动画速度表.获取渐变时长(配置名, 来源, 播放的动画名称)

	# ★ 关键补偿：混合时长会被 speed_scale 缩放，
	# 除以目标倍率让混合按"真实墙钟时间"生效，观感一致
	var 真实混合: float = 混合 / maxf(目标倍率, 0.01) if 混合 > 0.0 else 0.0

	_应用倍率(目标倍率)
	if 真实混合 > 0.0:
		play(播放的动画名称, 真实混合)
	else:
		play(播放的动画名称)

	if 调试:
		print("[动画] ", 来源 if 来源 != "" else "(空)", " → ", 播放的动画名称,
			" | 配置=", 配置名,
			" 倍率=", 目标倍率,
			" speed_scale实际=", speed_scale,
			" 混合(动画时间)=", 混合,
			" 混合(真实时间)=", 真实混合)

	动画开始.emit(播放的动画名称)
	return true
func 停止播放() -> void:
	if is_playing():
		stop()

func 正在播放(动画名: String = "") -> bool:
	if 动画名 == "":
		return is_playing()
	return current_animation == 动画名 and is_playing()

func 切换配置(新配置名: String) -> void:
	配置名 = 新配置名
	if not 动画速度表.是否有配置(配置名):
		动画速度表.创建配置(配置名)
	if current_animation != "" and is_playing():
		_应用倍率(_解析倍率(current_animation))

func 设置动画倍率(动画名: String, 倍率: float) -> void:
	动画速度表.设置倍率(配置名, 动画名, 倍率)
	if current_animation == 动画名 and is_playing():
		_应用倍率(倍率)

func 移除动画倍率(动画名: String) -> void:
	动画速度表.移除倍率(配置名, 动画名)
	if current_animation == 动画名 and is_playing():
		_应用倍率(_解析倍率(动画名))

#=============================== 内部 ===============================
func _解析倍率(动画名: String) -> float:
	var 倍率 := 动画速度表.获取倍率(配置名, 动画名)
	return 倍率 if 倍率 > 0.0 else 默认速度倍率

func _应用倍率(倍率: float) -> void:
	if 倍率 <= 0.0:
		倍率 = 0.01
	当前速度倍率 = 倍率
	speed_scale = 倍率
	if 调试:
		print("[动画] speed_scale 设为 ", speed_scale, " (由 ", 倍率, " 传入)")

func _内部_动画结束(动画名: String) -> void:
	动画播放完毕.emit(动画名)
