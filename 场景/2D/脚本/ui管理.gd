extends Node
#class_name UI管理
@export var 当前UI场景:PackedScene=null
@export var 启用当前UI场景ui:bool=true
var 当前UI实例: Node = null
var 正在切换 := false

signal 当前UI切换时(旧的UI文件路径:String,新的UI文件路径:String)
signal UI切换后

func _ready() -> void:
	if 启用当前UI场景ui==true and 当前UI场景!=null:
		切换UI(当前UI场景.resource_path)
	#resource_path=获取路径

func 切换UI(新的UI文件路径:String):
	if ResourceLoader.exists(新的UI文件路径, "PackedScene")==false:#检查这个类型文件是否存在 
		print("errrrrrrrrrrrrrrrro,场景不存在,或者是这个场景不合法!!!!!!!!! ")
		return
	if 当前UI场景!=null:
		当前UI切换时.emit(当前UI场景.resource_path,新的UI文件路径)
	
	ResourceLoader.load_threaded_request(新的UI文件路径)
	while true:
		var 状态 = ResourceLoader.load_threaded_get_status(新的UI文件路径)
		if 状态 == ResourceLoader.THREAD_LOAD_LOADED:#如果状态是 LOADED =加载成了
			var 新UI文件 = ResourceLoader.load_threaded_get(新的UI文件路径)#从后台线程把已经加载完的资源转移到主线程
			for 从第几次开始 in get_children():#get_children()=子节点数量 
				remove_child(从第几次开始)#禁用掉某个节点 
				从第几次开始.queue_free()#queue_free()=安全删除节点 
			var 新UI=新UI文件.instantiate()
			self.add_child(新UI)#添加到当前的场景 
			当前UI场景=新UI文件
			当前UI实例=新UI
			UI切换后.emit()
			
			return
		elif 状态 == ResourceLoader.THREAD_LOAD_FAILED:
			print("加载失败")
			return
		elif 状态 == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:#资源被损坏了打不开 或者是类型对不上 
			print("无效资源: %s" % 新的UI文件路径)
			#push_error("无效资源: %s" % 新的UI文件路径)
			return
		await get_tree().process_frame  # 每帧检查一次，不阻塞
