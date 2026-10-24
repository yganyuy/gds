@tool
class_name 自动_多边形
extends Polygon2D

func _ready() -> void:
	if not is_inside_tree():
		return

	# 1. 向上查找父级精灵节点并继承纹理
	var sprite := _find_parent_sprite(self)
	if sprite and sprite.texture != null:
		texture = sprite.texture
		print("[自动_多边形] 已继承纹理: ", sprite.name)
	else:
		push_warning("[自动_多边形] 未找到带纹理的精灵父级: ", name)

	# 2. 查找与精灵节点同级的骨架节点
	var skeleton_node := _find_sibling_skeleton(sprite)
	if skeleton_node:
		# 注意：Polygon2D 自带的 skeleton 属性是 NodePath 类型
		skeleton = get_path_to(skeleton_node)
		print("[自动_多边形] 已绑定骨架: ", skeleton_node.name)
		# 3. 同步骨骼路径到多边形
		_sync_bones_from_skeleton(skeleton_node)
	else:
		push_warning("[自动_多边形] 未找到同级骨架节点: ", name)

	# 4. 完成设置后自动移除自身脚本
	set_script(null)
	print("[自动_多边形] 设置完成，脚本已自动卸载: ", name)

# 向上递归查找 Sprite2D 父级
func _find_parent_sprite(node: Node) -> Sprite2D:
	var current := node.get_parent()
	while current:
		if current is Sprite2D:
			return current
		current = current.get_parent()
	return null

# 在精灵节点的同级中查找 Skeleton2D
func _find_sibling_skeleton(sprite: Sprite2D) -> Skeleton2D:
	if not sprite:
		return null
	for sibling in sprite.get_parent().get_children():
		if sibling is Skeleton2D:
			return sibling
	return null

# 按骨架中的 Bone2D 列表，同步到多边形的 bone_paths
func _sync_bones_from_skeleton(skeleton_node: Skeleton2D) -> void:
	clear_bones()
	var vcount := polygon.size()
	var weight_arr := PackedFloat32Array()
	if vcount > 0:
		weight_arr.resize(vcount)  # 权重全为 0，待手动微调

	for child in skeleton_node.get_children():
		if child is Bone2D:
			add_bone(get_path_to(child), weight_arr)

	print("[自动_多边形] 已同步骨骼路径，数量: ", get_bone_count())