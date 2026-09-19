extends Node
class_name 生成物体#在全局变量中它的名称叫 实体功能

var 是联机么:bool=false
@export var 网络管理器:联机创建器=null##null=单机 反之
#@warning_ignore("shadowed_global_identifier")
@export var 场景同步器:场景同步=null
@export var 物体表:物体表=null##每个生成的物体就在其中,方便联机调用
@export var 属性同步需要调用的节点:属性同步的依赖=null
@export var 属性同步方式:int=2#1=用官方的属性同步,2=用我自制的RPC属性同步器
@export var 自动设置类型:bool=false

var 服务还是客户:int=0##0=单机 1=服务端 2=客户端
var 当前ID:int=0##每生成一个物体自动加一
var 初始化场景已经同步:bool=false##用来防止部分还没有完全生成的物体造成引用空缺 


signal 生成时(生成物,当前ID)

func _ready():
	if get_parent() == get_tree().root:#检查自身是否为自动加载
		print("已自动加载",name)
		if 物体表==null:
			物体表=全局物体表
			print("已自动获取物体表",物体表)
		if 场景同步器==null:
			var ou=场景同步.new()
			self.add_child(ou)#将节点创建到场景中 
			场景同步器=ou
	if 网络管理器==null:
		网络管理器=rpc联机方法
		print("已自动加载",rpc联机方法)
	if 属性同步需要调用的节点==null:
		属性同步需要调用的节点=属性设置需要的依赖
	类型判断()

#______________________核心判断_________________________

func 模式设置():
	if 网络管理器!=null:
		是联机么=true
	else :
		是联机么=false

func 类型判断():
	#判段联机状态
	模式设置()
	if 是联机么==true:
		if 网络管理器.shi_fou_chuang_jian_le==false and 网络管理器.shi_fou_jia_ru_fang_jian_le==false:
			return
	else:return
	
	if 网络管理器.wang_luo.get_unique_id() == 1:
		服务还是客户=1
		#类型="服务端"
	else :服务还是客户=2
		#类型="客户端"

#___________可以调用的主要指令____________________

func 生成物体(生成素材:PackedScene=null,节点:Node2D=null):
	类型判断()
	if 是联机么==true and 服务还是客户!=0:
		#联机生成脚本
		if 服务还是客户==2:
		#类型=="客户端":
			var pid =网络管理器.wang_luo_id
			客户端生成物体(生成素材,节点,pid)  #   传参数
		elif 服务还是客户==1 :
			var pid =网络管理器.wang_luo_id
			服务端生成物体(生成素材,节点,当前ID,pid)
	elif 是联机么==false or 服务还是客户==0:
		var pid =网络管理器.wang_luo_id
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
	if 服务还是客户==1:#服务端
		rpc("rpc同步属性",ID,数据)

func 获取ID(申请物:Node):
	if 服务还是客户==2:
		return
	当前ID+=1
	申请物.set_meta("id",当前ID)
	申请物.set_meta("pid",网络管理器.wang_luo_id)
	if 物体表!=null and 申请物!=null :
		物体表.加入物体(申请物,当前ID)

#_______________________有关于单机的_____________________

func 单机生成(生成素材,节点,ID,pid):
	if 生成素材==null or 节点==null:
		return
		#单机生成脚本
	self.当前ID += 1#设置ID+1
	ID=当前ID#这里是用来刷新ID的
	print("单机生成")
	_生成(生成素材,节点,ID,pid)

func 单机删除(ID):
	if 物体表!=null:
		var 设置物体 = 物体表.查找物体(ID)
		if 设置物体==null:return
		var 物体 = 设置物体.get_ref()
		物体.queue_free()
		print("单机已删id",物体)

#________________________有关于服务器的____________________________

func 服务端生成物体(生成素材,节点,ID,pid):
	类型判断()
	self.当前ID += 1#设置ID+1
	ID=当前ID#这里是用来刷新ID的
	_生成(生成素材,节点,ID,pid)
	rpc同步生成.rpc(生成素材.resource_path, 节点.get_path(),self.当前ID,pid)

func 服务端删除物体(ID):
	类型判断()
	if 服务还是客户!=1:
		return
	if _删除(ID)!=false:
		rpc("rpc同步删除", ID)
		print("服务器已删id",ID)
		return

#________________________有关于客户端的___________________________

# 客户端请求服务端生成
func 客户端生成物体(生成素材,节点,pid):
	类型判断()
	if 生成素材==null or 节点==null:
		return
	# 请求服务端生成
	rpc请求生成.rpc_id(1, 生成素材.resource_path, 节点.get_path(),pid)##.resource_path=x物体的场景路径
	print("请求服务端生成：", 生成素材.resource_path)


#______________________经常复用的代码__________________________
func _同步(id:int,数据:Dictionary)-> bool:
	if 物体表!=null:
		var 设置物体 = 物体表.查找物体(id)
		if 设置物体==null:return false
		var 物体 = 设置物体.get_ref()
		属性同步需要调用的节点.进行属性设置同步(物体,数据)
		return true
	else:return false

func _删除(id) -> bool:
	if 物体表!=null:
		var 设置物体 = 物体表.查找物体(id)
		if 设置物体==null:
			return false
		var 物体 = 设置物体.get_ref()
		物体.queue_free()
		return true
	else:return false

func _生成(生成素材,节点,ID,pid):
	if 生成素材==null or 节点==null:
		return
	var 生成物=生成素材.instantiate()
	var 网络状态同步器:同步属性=null#--------这个是那个属性同步的文件-------------
	
	生成物.set_meta("id", ID)#这里设置了 物体的ID
	生成物.set_meta("chang_jing_lu_jing", 生成素材.resource_path)#这里设置了物体的原素材路径
	生成物.set_meta("pid",pid)#这里设置了它归属于哪个 玩家的ID  用来查找自身的客户端 还是服务端的ID
	
	if 属性同步方式==2:
		if 生成物.has_node("同步属性"):#.has_node=是否存在(名字)为 某 的子节点
			网络状态同步器=生成物.get_node_or_null("同步属性")#.get_node_or_null=获取(名)为 某 的子节点
		else :网络状态同步器=同步属性.new()
		生成物.add_child(网络状态同步器)
	
	节点.add_child(生成物)
	if 物体表!=null and 生成物!=null :
		物体表.加入物体(生成物,ID)
	生成时.emit(生成物,ID)

#__________________________________________rpc物体删除的同步代码__________________________________________________
# 服务端 到 所有客户端：同步
@rpc("any_peer","call_local","reliable")
func rpc同步删除(ID:int):
	# 如果是服务端自己，跳过
	if 服务还是客户 == 1:
		return
	if _删除(ID)==true:
		print("客户端已删id",ID)

# 客户端 到 服务端：请求删除
@rpc("any_peer", "reliable")
func rpc请求删除(ID:int):
	类型判断()
	if 服务还是客户 == 2:
		return
	服务端删除物体(ID)

#_____________________________________________rpc生成同步代码_______________________________________________________

# 服务端 到 所有客户端：同步
@rpc("any_peer", "call_local", "reliable")
func rpc同步生成(素材路径: String, 父节点路径: NodePath,ID:int,pid):
	# 如果是服务端自己，跳过
	if 服务还是客户 == 1:
		return
	#这个是专门针对于客户端同步用的生成代码 
	var 素材 = load(素材路径) as PackedScene
	if 素材 == null:
		print("同步生成失败，无法加载：", 素材路径)
		return
	var 父节点 = get_node(父节点路径) as Node2D
	if 父节点 == null:
		print("同步生成失败，找不到父节点：", 父节点路径)
		return
	
	_生成(素材,父节点,ID,pid)
	
	print("[客户端] 同步生成成功：", 素材路径,"id:",ID)

# 客户端 到 服务端：请求生成
@rpc("any_peer", "reliable")
func rpc请求生成(素材路径: String, 父节点路径: NodePath,pid):
	# 只有服务端执行
	类型判断()
	if 服务还是客户 == 2:
		return
	var 素材 = load(素材路径) as PackedScene
	var 父节点 = get_node(父节点路径) as Node2D
	if 素材 == null or 父节点 == null:
		return
	# 服务端生成并自动同步
	服务端生成物体(素材, 父节点,当前ID,pid)

#__________________________________________rpc属性同步代码_____________________________
# 服务端 到 所有客户端：同步
@rpc("any_peer", "call_local", "reliable")
func rpc同步属性(ID:int,数据:Dictionary):
	_同步(ID,数据)


#不加 "call_local"	只通知别人，自己不执行
#加 "call_local"	通知别人的同时，自己也执行
#@rpc("any_peer", "call_local", "reliable")
 #      ↑            ↑             ↑          这里也可以是"unreliable"	不可靠传输，丢了就丢了，不重传
 #   任何人能调用    自己也执行   丢包了重传直到到达
#@rpc位于要func代码的上面
