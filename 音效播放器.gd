extends Node
class_name 音频播放器
@export var 同时播放音效上限:int=10
@export var 音效文件:Array[AudioStream]=[]
@export_enum("随机", "固定查找", "仅第一个") var 类型 :String="随机"
@export var 第x个 :int=1
@export var 音量:float=100
@export var 音调:float=1.0
@export var 音频生成到节点:Node=null

var 正在播放音效数 :int =0
var 当前设置的音频:AudioStream=null
var 音频表文件总数:int=1
var 生成的音频:AudioStreamPlayer

#信号
signal 当播放开始时
signal 当播放结束时
signal 当删除播放时
#换算
func 百分比转分贝(百分比: float) -> float:
	# 100% = 原始音量 (0 dB)
	# 50%  = 一半音量 (-6 dB)
	# 0%   = 静音 (-60 dB)
	if 百分比 <= 0:
		return -60.0
	elif 百分比 >= 100:
		return 0.0
	else:
		# 对数映射：50% → -6dB，100% → 0dB
		return (百分比 / 100.0 - 1.0) * 12.0  # 12 是斜率

func 播放音效():
	#获取音效
	音频表文件总数=音效文件.size()
	if 音频生成到节点==null:
		音频生成到节点=self##self=自身
	if not 音效文件.is_empty() and 正在播放音效数<=同时播放音效上限:
		#is_empty()=是空组吗？
		match 类型:
			"随机":
				var 随机的第x个=randi_range(0,音频表文件总数-1)
				当前设置的音频=音效文件[随机的第x个]
			"固定查找":
				当前设置的音频=音效文件[第x个-1]
			"仅第一个":
				当前设置的音频=音效文件[0]
		#创建音效
		var 音播=AudioStreamPlayer.new()
		音播.stream=当前设置的音频
		音播.volume_db=百分比转分贝(音量)
		音播.pitch_scale=音调
		正在播放音效数+=1
		音频生成到节点.add_child(音播)
		生成的音频=音播
		音播.play()
		当播放开始时.emit()
		#监听是否播完音效
		音播.finished.connect(停止当前音效)
		#.bind()上面这个括号里可以加入此函数来传数据

func 停止当前音效():
	if 生成的音频==null or 正在播放音效数<=0:
		return
	当播放结束时.emit()
	生成的音频.free.call_deferred()
	#call_deferred=延迟一帧执行... 目的：保证它已经初始化了，防崩用
	正在播放音效数-=1
	#free()=删除
	#queue_free()=执行完删除
	当删除播放时.emit()
	
