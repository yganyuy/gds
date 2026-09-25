extends Node
class_name 查找节点

static func 查找节点(节点: Node, 目标名称: String) -> Node:
	if 节点 == null:
		return null

	var 脚本 = 节点.get_script()
	if 脚本:
		var 脚本文件名 = 脚本.resource_path.get_file().get_basename()
		if 脚本文件名 == 目标名称:
			return 节点

		# 如果是要找 class_name
		if 脚本.get_global_name() == 目标名称:
			return 节点

	for 子节点 in 节点.get_children():
		var 结果 = 查找节点(子节点, 目标名称)
		if 结果:
			return 结果

	return null
