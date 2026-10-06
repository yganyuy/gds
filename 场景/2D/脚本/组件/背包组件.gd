extends MaterialContainer
class_name 背包组件


func 拾取(路径: String, 单占: float, 数量: int) -> void:
	if 数量<=0:
		print("Erro : 数量= ",数量)
		return
	self.add_material(路径, 单占, 数量)

func 丢弃物品(位于数组的第几行或者名为什么的物体:Variant,数量:int):
	if 位于数组的第几行或者名为什么的物体 is int:
		if 位于数组的第几行或者名为什么的物体>-1 and 位于数组的第几行或者名为什么的物体<self.items_sync.size():
			self.remove_material(位于数组的第几行或者名为什么的物体,数量)
	if 位于数组的第几行或者名为什么的物体 is String:
		var 查找的物体=self.get_material_quantity(位于数组的第几行或者名为什么的物体)
		if 查找的物体<=0:
			print(self,":",位于数组的第几行或者名为什么的物体,"的数量=",查找的物体)
			return
		else :self.remove_material(位于数组的第几行或者名为什么的物体,数量)
