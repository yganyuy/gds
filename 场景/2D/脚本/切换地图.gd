extends Node
class_name 切换地图

@export var 目标地图:Array[PackedScene]
@export_enum("随机的图", "仅第一个", "指定一个") var 方式: int = 0
@export var 指定目标地图中的x个:int=1
@export var 初始化随机地图:bool=true
var 当前缓存的地图:PackedScene=null


func _ready() -> void:
	if 初始化随机地图==true:
		获取地图()

func 获取地图() -> void:
	if 目标地图.size()<=0:
		print("地图数组可能是空的")
		return
	if 方式==0:
		当前缓存的地图=目标地图.pick_random()
	elif 方式==1:
		当前缓存的地图=目标地图[0]
	elif 方式==2 and 指定目标地图中的x个-1<目标地图.size() and 指定目标地图中的x个>=1:
		当前缓存的地图=目标地图[指定目标地图中的x个-1]
	else:
		print("引用了一个不存在的地图场景")

func 直接切换地图(): 
	if 当前缓存的地图==null:
		print("你引用了一个滚木")
		return
	get_tree().change_scene_to_packed(当前缓存的地图)

func 加载场景(路径: String) -> void:
	if ResourceLoader.exists(路径, "PackedScene")==false:#检查这个类型文件是否存在 
		print("errrrrrrrrrrrrrrrro,场景不存在,或者是这个场景不合法!!!!!!!!! ")
		return
	ResourceLoader.load_threaded_request(路径)#创建了一个后台进程
	while true:
		var 状态 = ResourceLoader.load_threaded_get_status(路径)#查询加载进度
		if 状态 == ResourceLoader.THREAD_LOAD_LOADED:#如果状态是 LOADED =加载成了
			var 打包场景 = ResourceLoader.load_threaded_get(路径)#从后台线程把已经加载完的资源转移到主线程
			get_tree().change_scene_to_packed(打包场景)#get_tree()=拿到场景树,change_scene_to_packed() 用打包场景切换当前场景
			return
		elif 状态 == ResourceLoader.THREAD_LOAD_FAILED:
			print("加载失败")
			return
		elif 状态 == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:#资源被损坏了打不开 或者是类型对不上 
			push_error("无效资源: %s" % 路径)
			return
		await get_tree().process_frame  # 每帧检查一次，不阻塞
