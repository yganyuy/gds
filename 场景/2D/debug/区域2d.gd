extends Area2D
@export var f:Node2D=null


func _ready() -> void:
	pass
func bata(node:Node2D):
	if node!=self :
		f.target_node=node
		
