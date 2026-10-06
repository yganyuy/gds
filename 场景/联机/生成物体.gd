extends Node
class_name 生成物体

var 是联机么:bool=false
@export var 网络管理器:联机创建器=null
@export var 场景同步器:场景同步=null
@export var 物体表:物体表=null
@export var 属性同步需要调用的节点:属性同步的依赖=null
@export var 属性同步方式:int=2
@export var 自动设置类型:bool=false

var 服务还是客户:int=0
var 当前ID:int=0
var 初始化场景已经同步:bool=false
var 查找器:CXT=CXT.new()

signal 生成时(生成物,当前ID)

func _ready():
	if get_parent() == get_tree().root:
		print("已自动加载",name)
		if 物体表==null:
			物体表=全局物体表
		if 场景同步器==null:
			var ou=场景同步.new()
			self.add_child(ou)
			场景同步器=ou
	if 网络管理器==null:
		网络管理器=rpc联机方法
	if 属性同步需要调用的节点==null:
		属性同步需要调用的节点=属性设置需要的依赖
	类型判断()

func _physics_process(_delta: float) -> void:
	类型判断()

func 类型判断():
	if 网络管理器!=null:
		是联机么=true
	else:
		是联机么=false
	if 是联机么==true:
		if 网络管理器.shi_fou_chuang_jian_le==false and 网络管理器.shi_fou_jia_ru_fang_jian_le==false:
			return
	else:return
	if 网络管理器.wang_luo.get_unique_id() == 1:
		服务还是客户=1
	else:服务还是客户=2

func 生成物体(生成素材:PackedScene=null,节点:Node2D=null):
	类型判断()
	if 是联机么==true and 服务还是客户!=0:
		if 服务还是客户==2:
			var pid =网络管理器.wang_luo_id
			客户端生成物体(生成素材,节点,pid)
		elif 服务还是客户==1:
			var pid =网络管理器.wang_luo_id
			服务端生成物体(生成素材,节点,当前ID,pid)
	elif 是联机么==false or 服务还是客户==0:
		var pid = 0
		单机生成(生成素材,节点,当前ID,pid)

func 删除物体(ID:int):
	类型判断()
	if 服务还是客户==0:
		单机删除(ID)
	elif 服务还是客户==1:
		服务端删除物体(ID)
	elif 服务还是客户==2:
		rpc("rpc请求删除", ID)

func 属性同步(ID:int,数据:Dictionary):
	类型判断()
	if 服务还是客户==1:
		rpc("rpc同步属性",ID,数据)

func 单机生成(生成素材,节点,ID,pid):
	if 生成素材==null or 节点==null: return
	self.当前ID += 1
	ID=当前ID
	_生成(生成素材,节点,ID,pid)

func 单机删除(ID):
	if 物体表!=null:
		var 设置物体 = 物体表.查找物体(ID)
		if 设置物体==null:return
		设置物体.queue_free()

func 服务端生成物体(生成素材,节点,ID,pid):
	类型判断()
	self.当前ID += 1
	ID=当前ID
	_生成(生成素材,节点,ID,pid)
	rpc同步生成.rpc(生成素材.resource_path, 节点.get_path(),self.当前ID,pid)

func 服务端删除物体(ID):
	类型判断()
	if 服务还是客户!=1: return
	if _删除(ID)!=false:
		rpc("rpc同步删除", ID)

func 客户端生成物体(生成素材,节点,pid):
	类型判断()
	if 生成素材==null or 节点==null: return
	rpc请求生成.rpc_id(1, 生成素材.resource_path, 节点.get_path(),pid)

func _同步(id:int,数据:Dictionary)-> bool:
	if 物体表!=null:
		var 设置物体 = 物体表.查找物体(id)
		if 设置物体==null:return false
		属性同步需要调用的节点.进行属性设置同步(设置物体,数据)
		return true
	else:return false

func _删除(id) -> bool:
	if 物体表!=null:
		var 设置物体 = 物体表.查找物体(id)
		if 设置物体==null: return false
		设置物体.queue_free()
		return true
	else:return false

func _生成(生成素材,节点,ID,pid):
	if 生成素材==null or 节点==null: return
	var 生成物=生成素材.instantiate()
	var 网络状态同步器:同步属性=null
	
	生成物.set_meta("id", ID)
	生成物.set_meta("chang_jing_lu_jing", 生成素材.resource_path)
	生成物.set_meta("pid",pid)
	
	if 属性同步方式==2:
		if 生成物.has_node("同步属性"):
			网络状态同步器=生成物.get_node_or_null("同步属性")
		else:
			网络状态同步器=同步属性.new()
			生成物.add_child(网络状态同步器)
			网络状态同步器.name= "网络状态同步器%d" % ID
	生成物.name = str(生成物.name) + str(ID)
	节点.add_child(生成物)
	if 物体表!=null and 生成物!=null:
		物体表.加入物体(生成物,ID)
	生成时.emit(生成物,ID)

# 客户端强制同步服务端ID，避免本地ID错乱
@rpc("any_peer","call_local","reliable")
func rpc同步生成(素材路径: String, 父节点路径: NodePath,ID:int,pid):
	if 服务还是客户 == 1: return
	var 素材 = load(素材路径) as PackedScene
	if 素材 == null: return
	var 父节点 = get_node(父节点路径) as Node2D
	if 父节点 == null: return
	
	# 关键修复：强制更新本地当前ID，防止后续生成冲突
	self.当前ID = max(self.当前ID, ID)
	
	_生成(素材,父节点,ID,pid)

@rpc("any_peer", "reliable")
func rpc请求生成(素材路径: String, 父节点路径: NodePath,pid):
	类型判断()
	if 服务还是客户 == 2: return
	var 素材 = load(素材路径) as PackedScene
	var 父节点 = get_node(父节点路径) as Node2D
	if 素材 == null or 父节点 == null: return
	服务端生成物体(素材, 父节点,当前ID,pid)

@rpc("any_peer", "call_local", "reliable")
func rpc同步删除(ID:int):
	if 服务还是客户 == 1: return
	_删除(ID)

@rpc("any_peer", "reliable")
func rpc请求删除(ID:int):
	类型判断()
	if 服务还是客户 == 2: return
	服务端删除物体(ID)

@rpc("any_peer", "call_local", "reliable")
func rpc同步属性(ID:int,数据:Dictionary):
	_同步(ID,数据)
