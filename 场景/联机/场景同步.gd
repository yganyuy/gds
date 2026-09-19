extends Node
class_name 场景同步

var _实体功能:生成物体=null
var 父节点:Node=null

#________________________场景初始化同步___________________________
func _ready() -> void:
	if _实体功能==null:
		await get_parent().ready#保持等待直到父物体存在 查找父物体 
		父节点 = get_parent()
		if 父节点 as 生成物体!=null:#确保这个节点是专门针对于生成物体的 
			_实体功能=父节点

# 服务端：发送场景映射给特定客户端（用于初始化同步）
func 发送场景映射给客户端(peer_id: int):
	if _实体功能==null or _实体功能.服务还是客户 != 1:
		return
	var 映射 = _实体功能.物体表.获取所有物体的场景路径映射()
	rpc_id(peer_id, "rpc_接收场景映射", 映射)
	print("[服务端] 已发送场景映射给", peer_id, " 物体数:", 映射.size())

# 客户端：接收场景映射并重建场景
@rpc("any_peer", "call_local", "reliable")
func rpc_接收场景映射(映射: Dictionary):
	if _实体功能.服务还是客户 != 2:
		return
	print("[客户端] 收到场景映射，物体数:", 映射.size())
	# 2. 根据映射重建物体
	for ID in 映射:
		var 数据 = 映射[ID]
		var 路径 = 数据["路径"]
		var pid = 数据["pid"]
		var 场景 = load(路径)
		if 场景 == null:
			continue
		var 生成物 = 场景.instantiate()
		# 设置元数据
		生成物.set_meta("id", ID)
		生成物.set_meta("chang_jing_lu_jing", 路径)
		生成物.set_meta("pid", pid)
		# 挂载同步器
		var 网络状态同步器:同步属性 = null
		if _实体功能.属性同步方式 == 2:
			网络状态同步器 = 同步属性.new()
		if 网络状态同步器 != null:
			生成物.add_child(网络状态同步器)
		get_tree().current_scene.add_child(生成物)
		if _实体功能.物体表 != null:
			_实体功能.物体表.加入物体(生成物, ID)
		_实体功能.生成时.emit(生成物, ID)
		print("[客户端] 场景重建完成，物体数:", 映射.size())
	_实体功能.初始化场景已经同步=true


func 清理本地所有物体():
	var 所有ID = _实体功能.物体表.获取所有ID()
	for ID in 所有ID:
		_实体功能.删除物体(ID)
	print("已清理本地所有物体，数量:", 所有ID.size())

# 客户端：请求场景同步（在连接成功后调用）
func 请求场景同步(id:int):
	_实体功能.类型判断()
	if _实体功能.服务还是客户 == 2:
		rpc_id(1, "rpc_请求场景映射",id)
		print("[客户端] 请求场景同步")

# 服务端：响应客户端的场景同步请求
@rpc("any_peer", "reliable")
func rpc_请求场景映射(id:int):
	#print("我得保证传过来的ID是正确的 ",id)
	if _实体功能.服务还是客户 != 1:
		return
	var 请求者 = id
	发送场景映射给客户端(请求者)
