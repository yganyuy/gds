extends Label
var 武器槽:Node=null
var 查找器:CXT=CXT.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if 玩家当前角色.玩家角色.size()<=0:return
	if 武器槽==null:武器槽=查找器.FIND(玩家当前角色.玩家角色[0],"武器槽组件",-1,true)
	if 武器槽!=null and 武器槽.当前武器!=null:text=武器槽.当前武器.name
