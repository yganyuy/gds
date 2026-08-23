extends Node
class_name 直接生成物体
@export var 工具:生成物体=null
@export var 目标节点:Node2D=null
@export var 素材:PackedScene=null
@export var 开始时生成:bool=true
@export var 偏移=Vector2.ZERO##ZERO=默任
var 模式 : int=1##1=单机  2=联机
var 对应物体ID:int=-1##-1=未进行设置  由于它采用引用的是工具节点 所以对应物体的ID后续修改由工具节点决定  
var 临时偏移:Vector2

func _ready():
	工具=实体功能
	if 开始时生成==true:
		生成()
	工具.生成时.connect(当物体生成时)

@warning_ignore("unused_parameter")
func 当物体生成时(生成物,ID):
	#print("生了",生成物)
	
	var 连机且还是服务端  = 工具.是联机么==true and 工具.服务还是客户==1
	var 不是连机=工具.服务还是客户==0
	
	if 连机且还是服务端  or 不是连机: 
		if 不是连机: 
			模式=1
		else:
			模式=2
		if 生成物 is Node2D==true:            #is=是否存在x组件
			临时偏移.x = randi_range(偏移.x*-1, 偏移.x)    #randi_range=随机函数
			临时偏移.y = randi_range(偏移.y*-1, 偏移.y)
			生成物.position =(临时偏移)
			#print("服务端 设制了",偏移)
		if 模式==2 :
			#print("客户端的信号我传过去了")
			return

func 生成():##他负责调用生成工具的那个节点 
	var 生成素材=素材
	var 节点=目标节点
	if 节点==null:节点=self
	工具.生成物体(生成素材,节点)

func _on_button_button_down() -> void:
	生成()
