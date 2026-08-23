extends Node
class_name 联机创建器#在全局变量中的名称叫做 Rpc联机方法

@export var duan_kou_hao: int = 7788
@export var ip: String = "127.0.0.1"

var shi_fou_chuang_jian_le: bool = false
var shi_fou_jia_ru_fang_jian_le: bool = false
var wang_luo: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

signal 连接断了
signal 连接不上
signal 连上了(peer_id: int)
signal 有人退
signal 有人进来(peer_id: int)
signal 创建了房间

func xiu_gai_ip(xin_ip:String=ip):
	if xin_ip==null or xin_ip=="" or xin_ip.contains(" "):
		return
	print("正在修改目标IP")
	ip=xin_ip

func Chuang_jian_fang_jian():
	
	var cuo_wu =wang_luo.create_server(duan_kou_hao)##设置为服务端
	if cuo_wu != OK:
		print("创建失败[",cuo_wu,"]")
		if cuo_wu==20:
			duan_kou_hao=randi_range(1024, 65535)#随机端口号然后重试
			print("你这个端口号已经被占用了,我帮你重新修改了端口号",duan_kou_hao,"\n","正在重试创建")
			Chuang_jian_fang_jian()
		return
	
	# 设置为服务端
	multiplayer.multiplayer_peer = wang_luo
	
	# 监听
	multiplayer.peer_connected.connect(you_ren_jin_lai)
	multiplayer.peer_disconnected.connect(you_ren_tui)
	chuang_jian_hao_le()

func Jia_ru_fang_jian():
	var cuo_wu = wang_luo.create_client(ip, duan_kou_hao)## 设置为客户端
	if cuo_wu != OK:
		lian_bu_shang(cuo_wu)
		Guan_bi_wang_luo()
		print("让我关闭一下当前已经创建的服务器,也有可能是你的端口号和目标的端口号不一样")
		return
	multiplayer.multiplayer_peer = wang_luo
	# 监听
	multiplayer.connected_to_server.connect(lian_shang_le)
	multiplayer.connection_failed.connect(lian_jie_shi_bai)
	multiplayer.server_disconnected.connect(lian_jie_duan_le)

func Guan_bi_wang_luo():
	if wang_luo != null:
		wang_luo.close()
		wang_luo = ENetMultiplayerPeer.new()
	multiplayer.multiplayer_peer = null
	shi_fou_chuang_jian_le = false
	shi_fou_jia_ru_fang_jian_le = false
	print("网络已关闭,如果想加入某人房间的话记得保证端口号还有IP地址相同")

func lian_bu_shang(cuo_wu):
	print("加入房间失败，错误码：", cuo_wu)
	连接不上.emit()

func chuang_jian_hao_le():
	print("房主id",multiplayer.get_unique_id())
	shi_fou_chuang_jian_le = true
	创建了房间.emit()
	print("创建了房间，端口：", duan_kou_hao)

func lian_jie_duan_le():
	连接断了.emit()
	print("连接断了")

func lian_jie_shi_bai():
	连接不上.emit()
	print("连接失败")

func lian_shang_le():
	shi_fou_jia_ru_fang_jian_le=true
	连上了.emit(multiplayer.get_unique_id())
	print("客户id",multiplayer.get_unique_id())
	print("连上了")

func you_ren_tui(peer_id: int):
	有人退.emit(peer_id)
	print("有人退了，ID：", peer_id)

func you_ren_jin_lai(peer_id: int):
	有人进来.emit(peer_id)
	print("有人进来了，ID：", peer_id)
