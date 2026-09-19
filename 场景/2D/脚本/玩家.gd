extends CharacterBody2D


@export var 移动速度 = 300.0
@export var 跳跃高度 = -400.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("w") and is_on_floor():
		velocity.y = 跳跃高度

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("a", "d")
	if direction:
		velocity.x = direction * 移动速度
	else:
		velocity.x = move_toward(velocity.x, 0, 移动速度)
	move_and_slide()
