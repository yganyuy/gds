extends PhysicsSpace2D
@export var ii:PackedScene=null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if ii!=null:
		var n = preload("res://场景/2D/角色/玩家.tscn").instantiate()
		self.add_child(n)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
