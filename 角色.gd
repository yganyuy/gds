extends CharacterBody2D

@export var 最大速度: float = 200.0
@export var 加速度: float = 800.0
@export var 摩擦力: float = 600.0
@export var 旋转速度: float = 10.0

var 是否在移动: bool = false
var  oi:int=0

func _enter_tree():
	pass
		#set_multiplayer_authority(int(str(name)))
		#print("我是",(int(str(name))),"=",name)
	#查明ID权限
func _ready():
	await get_tree().create_timer(0.1).timeout##等待x秒 
	#print(get_meta("chang_jing_lu_jing"))
	while true:
		await get_tree().create_timer(0.01).timeout
		o00()

	#await get_tree().create_timer(0.008).timeout##等待x秒 
	#var 我的ID = get_meta("id")
	#print("我的ID是:", 我的ID)
	#
	#if !is_multiplayer_authority():
		##print("神了")
		##print("我不是",(int(str(name))),"!=",name)
		#return
	#var myname=int(name)
	#
	## 检查是否有控制权
	#if myname == multiplayer.get_unique_id():
	##$is_multiplayer_authority():
		## 启用相机
		#print(multiplayer.get_unique_id(),"起用了",myname,"像机")
		#var 相机 = get_node_or_null("Camera2D")
		#if 相机:
			#相机.enabled = true
			#
	#if myname != multiplayer.get_unique_id():
		##print("远程玩家，ID：", name)
		## 禁用相机
		#print(multiplayer.get_unique_id(),"禁用了",myname,"像机")
		#var 相机 = get_node_or_null("Camera2D")
		#if 相机:
			#相机.enabled = false
		#
#
#func _physics_process(delta: float) -> void:
	#var myname=int(name)
	## 只有名称相符才触发
	##if not myname == multiplayer.get_unique_id():
	##is_multiplayer_authority():
		#return
	#
	#var 输入向量 := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var 目标速度 := 输入向量 * 最大速度
	#
	#if 输入向量.length() > 0:
		#velocity = velocity.move_toward(目标速度, 加速度 * delta)
		#var 目标角度 := 输入向量.angle()
		#rotation = lerp_angle(rotation, 目标角度, 旋转速度 * delta)
		#是否在移动 = true
	#else:
		#velocity = velocity.move_toward(Vector2.ZERO, 摩擦力 * delta)
		#是否在移动 = false
	#
	#move_and_slide()
#
#func _on_timer_timeout() -> void:
	#var 父节点 = get_parent()
	#print(name,"父节点是",父节点)
	#if 父节点 != null:
		#position=父节点.position
		#visible=true
		#await get_tree().create_timer(1).timeout#等2秒
		#collision_layer=1#设置碰撞层
func o00():
	if 实体功能.服务还是客户==2:
		return
	oi+=5
	position.x+=5
	if oi>2000:
		删除自身()
func 删除自身():
	实体功能.删除物体(get_meta("id"))#get_meta("id")=我的ID 
	
