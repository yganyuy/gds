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

	var 排序后ID: Array = 映射.keys()
	排序后ID.sort_custom(func(a, b):
		var pa: NodePath = 映射[a].get("父节点路径", NodePath(""))
		var pb: NodePath = 映射[b].get("父节点路径", NodePath(""))
		return pa.get_name_count() < pb.get_name_count()
	)

	var 延迟挂载: Array = []
	for ID in 排序后ID:
		if _实体功能.物体表 != null and _实体功能.物体表.查找物体(ID) != null:
			continue

		var 数据 = 映射[ID]
		var 路径 = 数据["路径"]
		var pid = 数据["pid"]
		var 场景 = load(路径)
		if 场景 == null:
			push_warning("[客户端] 加载失败: %s" % 路径)
			continue
		var 生成物 = 场景.instantiate()
		生成物.set_meta("id", ID)
		生成物.set_meta("chang_jing_lu_jing", 路径)
		生成物.set_meta("pid", pid)

		var 网络状态同步器: 同步属性 = null
		if _实体功能.属性同步方式 == 2:
			网络状态同步器 = 同步属性.new()
		if 网络状态同步器 != null and rpc联机方法.wang_luo_id == 1:
			生成物.add_child(网络状态同步器)
			网络状态同步器.name = str(网络状态同步器.name) + str(ID)

		var 父节点路径: NodePath = 数据.get("父节点路径", NodePath(""))
		var 实际父节点: Node = 查找挂载父节点(父节点路径)

		if 父节点路径 != NodePath("") and 实际父节点 == get_tree().current_scene:
			延迟挂载.append({"节点": 生成物, "父": 父节点路径, "id": ID})
			# 先挂到 current_scene，保证 meta 生效、能入物体表
			实际父节点.add_child(生成物)
		else:
			if 实际父节点 == null:
				实际父节点 = get_tree().current_scene
			实际父节点.add_child(生成物)

		生成物.name = str(生成物.name) + str(ID)
		if _实体功能.物体表 != null:
			_实体功能.物体表.加入物体(生成物, ID)
		_实体功能.生成时.emit(生成物, ID)

	# 第二轮重试
	if 延迟挂载.size() > 0:
		print("[客户端] 重试延迟挂载，数量:", 延迟挂载.size())
		for 项 in 延迟挂载:
			var 父 = 查找挂载父节点(项.父)
			if 父 != null and 父 != get_tree().current_scene:
				项.节点.reparent(父)
				print("  重挂成功 ID=%d → %s" % [项.id, str(项.父)])
			else:
				push_warning("  重挂失败 ID=%d 期望父=%s（保持 current_scene 下）" % [项.id, str(项.父)])

	_实体功能.初始化场景已经同步 = true

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

# ★ 独立函数：根据服务端给出的父节点路径查找挂载点，找不到则回退到 current_scene
func 查找挂载父节点(父节点路径: NodePath) -> Node:
	if 父节点路径 != NodePath(""):
		var 找到的节点 = get_node_or_null(父节点路径)
		if 找到的节点 != null:
			return 找到的节点
		push_warning("[客户端] 找不到父节点路径: %s，回退到 current_scene" % str(父节点路径))
	return get_tree().current_scene
