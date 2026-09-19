@tool
extends RefCounted
## 节点数据库
## 负责扫描 ClassDB 中的节点类型，并提供 中文名 / 中文描述 的翻译。

const 官方描述 := preload("res://addons/ChineseNodeSelector/data/official_descriptions.gd")

# ============================================================
# 类型来源
# ============================================================
const 来源内置: int = 0
const 来源自定义: int = 1
const 来源编辑器: int = 2

# ============================================================
# 翻译表：类名 → 中文显示名
# 注意：必须是 static var（非 const）。const 会被引用脚本在编译期
# 固化成快照，改表后未重新编译的脚本（如设置对话框）会读到旧值。
# static var 在运行时读取，脚本热重载后所有引用方自动拿到最新翻译。
# 此表为只读数据，运行期请勿修改。
# ============================================================
static var 翻译表 := {
	# ---- 核心 / 通用 ----
	"Node": "节点",
	"CanvasItem": "画布项",
	"CanvasLayer": "画布层",
	"CanvasModulate": "画布调色",
	"SubViewport": "子视口",
	"Viewport": "视口",
	"WorldEnvironment": "世界环境",
	"AnimationPlayer": "动画播放器",
	"AnimationTree": "动画树",
	"AnimationGraph": "动画图",
	"AnimationMixer": "动画混合器",
	"AudioListener2D": "音频监听2D",
	"AudioListener3D": "音频监听3D",
	"AudioStreamPlayer": "音频播放器",
	"AudioStreamPlayer2D": "音频播放器2D",
	"AudioStreamPlayer3D": "音频播放器3D",
	"Timer": "计时器",
	"HTTPRequest": "HTTP请求",
	"MultiplayerSpawner": "多人游戏生成器",
	"MultiplayerSynchronizer": "多人游戏同步器",
	"ResourcePreloader": "资源预加载器",
	"SceneTree": "场景树",
	"MovieWriter": "电影输出",
	"EditorNode": "编辑器节点",
	"EditorPlugin": "编辑器插件",

	# ---- 2D 节点 ----
	"Node2D": "2D节点",
	"Sprite2D": "精灵",
	"AnimatedSprite2D": "动画精灵",
	"SpriteBase2D": "精灵基类",
	"CollisionObject2D": "碰撞对象2D",
	"PhysicsBody2D": "物理体2D",
	"CharacterBody2D": "角色体2D",
	"StaticBody2D": "静态体2D",
	"AnimatableBody2D": "可动体2D",
	"RigidBody2D": "刚体2D",
	"Area2D": "区域2D",
	"Camera2D": "相机2D",
	"TileMap": "瓦片地图",
	"TileMapLayer": "瓦片地图层",
	"Polygon2D": "多边形2D",
	"Line2D": "线条2D",
	"Path2D": "路径2D",
	"PathFollow2D": "路径跟随2D",
	"Marker2D": "标记2D",
	"RemoteTransform2D": "远程变换2D",
	"VisibleOnScreenNotifier2D": "屏幕可见通知2D",
	"VisibleOnScreenEnabler2D": "屏幕可见启用2D",
	"Light2D": "光照2D",
	"PointLight2D": "点光2D",
	"DirectionalLight2D": "方向光2D",
	"Parallax2D": "视差2D",
	"ParallaxBackground": "视差背景",
	"ParallaxLayer": "视差层",
	"GPUParticles2D": "GPU粒子2D",
	"CPUParticles2D": "CPU粒子2D",
	"CollisionShape2D": "碰撞形状2D",
	"CollisionPolygon2D": "碰撞多边形2D",
	"Joint2D": "关节2D",
	"PinJoint2D": "销关节2D",
	"GrooveJoint2D": "槽关节2D",
	"DampedSpringJoint2D": "阻尼弹簧关节2D",
	"MeshInstance2D": "网格实例2D",
	"TouchScreenButton": "触屏按钮",
	"NavigationRegion2D": "导航区域2D",
	"NavigationAgent2D": "导航代理2D",
	"NavigationObstacle2D": "导航障碍2D",
	"NavigationLink2D": "导航链接2D",

	# ---- 3D 节点 ----
	"Node3D": "3D节点",
	"MeshInstance3D": "网格实例3D",
	"MultiMeshInstance3D": "多网格实例3D",
	"Sprite3D": "精灵3D",
	"SpriteBase3D": "精灵基类3D",
	"AnimatedSprite3D": "动画精灵3D",
	"Label3D": "标签3D",
	"CollisionObject3D": "碰撞对象3D",
	"PhysicsBody3D": "物理体3D",
	"CharacterBody3D": "角色体3D",
	"StaticBody3D": "静态体3D",
	"AnimatableBody3D": "可动体3D",
	"RigidBody3D": "刚体3D",
	"Area3D": "区域3D",
	"Camera3D": "相机3D",
	"Light3D": "光照3D",
	"DirectionalLight3D": "方向光3D",
	"OmniLight3D": "全向光3D",
	"SpotLight3D": "聚光3D",
	"CollisionShape3D": "碰撞形状3D",
	"CollisionPolygon3D": "碰撞多边形3D",
	"GPUParticles3D": "GPU粒子3D",
	"GPUParticlesAttractor3D": "GPU粒子吸引器3D",
	"GPUParticlesCollision3D": "GPU粒子碰撞3D",
	"CPUParticles3D": "CPU粒子3D",
	"Marker3D": "标记3D",
	"Path3D": "路径3D",
	"PathFollow3D": "路径跟随3D",
	"NavigationRegion3D": "导航区域3D",
	"NavigationAgent3D": "导航代理3D",
	"NavigationObstacle3D": "导航障碍3D",
	"NavigationLink3D": "导航链接3D",
	"Skeleton3D": "骨骼3D",
	"SkeletonModifier3D": "骨骼修改器3D",
	"ChainIK3D": "链IK3D",
	"IKModifier3D": "IK修改器3D",
	"IterateIK3D": "迭代IK3D",
	"PhysicalBone3D": "物理骨骼3D",
	"BoneAttachment3D": "骨骼挂点3D",
	"RemoteTransform3D": "远程变换3D",
	"SpringArm3D": "弹簧臂3D",
	"VehicleWheel3D": "车辆车轮3D",
	"VisibleOnScreenNotifier3D": "屏幕可见通知3D",
	"VisibleOnScreenEnabler3D": "屏幕可见启用3D",
	"RayCast3D": "射线检测3D",
	"ShapeCast3D": "形状投射3D",
	"Decal": "贴花",
	"CSGShape3D": "CSG形状3D",
	"CSGPrimitive3D": "CSG基元3D",
	"CSGBox3D": "CSG方块3D",
	"CSGSphere3D": "CSG球体3D",
	"CSGCylinder3D": "CSG圆柱3D",
	"CSGPolygon3D": "CSG多边形3D",
	"CSGCombiner3D": "CSG组合器3D",
	"CSGMesh3D": "CSG网格3D",
	"Joint3D": "关节3D",
	"HingeJoint3D": "铰链关节3D",
	"PinJoint3D": "销关节3D",
	"ConeTwistJoint3D": "锥形扭动关节3D",
	"SliderJoint3D": "滑块关节3D",
	"Generic6DOFJoint3D": "六自由度关节3D",
	"XROrigin3D": "XR原点3D",
	"XRCamera3D": "XR相机3D",
	"XRController3D": "XR控制器3D",
	"OpenXRCompositionLayer": "OpenXR合成层",
	"XRAnchor3D": "XR锚点3D",
	"XRHandTracker": "XR手部追踪",
	"XRBodyTracker": "XR身体追踪",
	"XRFaceTracker": "XR面部追踪",
	"XROcclusionMesh": "XR遮挡网格",
	"VoxelGI": "体素全局光照",
	"VolumetricFog": "体积雾",
	"FogVolume": "雾体积",

	# ---- UI / Control ----
	"Control": "控件",
	"Separator": "分隔符",
	"BaseButton": "基础按钮",
	"Button": "按钮",
	"Label": "标签",
	"RichTextLabel": "富文本标签",
	"LineEdit": "单行文本输入",
	"TextEdit": "多行文本输入",
	"CodeEdit": "代码编辑器",
	"SpinBox": "数值微调框",
	"ProgressBar": "进度条",
	"Range": "范围",
	"HSlider": "水平滑块",
	"VSlider": "垂直滑块",
	"HScrollBar": "水平滚动条",
	"VScrollBar": "垂直滚动条",
	"ScrollBar": "滚动条",
	"Slider": "滑块",
	"CheckButton": "勾选按钮",
	"CheckBox": "复选框",
	"OptionButton": "下拉选项按钮",
	"ColorPickerButton": "颜色选择按钮",
	"ColorPicker": "颜色选择器",
	"MenuButton": "菜单按钮",
	"MenuBar": "菜单栏",
	"PopupMenu": "弹出菜单",
	"PopupPanel": "弹出面板",
	"PopupPanelContainer": "弹出面板容器",
	"Panel": "面板",
	"PanelContainer": "面板容器",
	"ColorRect": "颜色矩形",
	"TextureRect": "纹理矩形",
	"TextureButton": "纹理按钮",
	"NinePatchRect": "九宫格矩形",
	"VBoxContainer": "垂直盒子容器",
	"HBoxContainer": "水平盒子容器",
	"BoxContainer": "盒子容器",
	"GridContainer": "网格容器",
	"CenterContainer": "居中容器",
	"MarginContainer": "边距容器",
	"AspectRatioContainer": "宽高比容器",
	"Container": "容器",
	"ScrollContainer": "滚动容器",
	"SplitContainer": "分割容器",
	"HSplitContainer": "水平分割容器",
	"VSplitContainer": "垂直分割容器",
	"SubViewportContainer": "子视口容器",
	"TabContainer": "标签容器",
	"Tabs": "标签栏",
	"TabBar": "标签条",
	"ItemList": "项目列表",
	"Tree": "树",
	"GraphEdit": "图形编辑器",
	"GraphNode": "图形节点",
	"GraphFrame": "图形框",
	"FlowContainer": "流式容器",
	"HFlowContainer": "水平流式容器",
	"VFlowContainer": "垂直流式容器",
	"VideoStreamPlayer": "视频播放器",
	"FileDialog": "文件对话框",
	"AcceptDialog": "确认对话框",
	"ConfirmationDialog": "确认对话框",
	"Window": "窗口",
	"AimModifier3D": "瞄准修改器3D",
	"AreaLight3D": "面光源3D",
	"BackBufferCopy": "后台缓冲复制",
	"Bone2D": "骨骼2D",
	"BoneConstraint3D": "骨骼约束3D",
	"BoneTwistDisperser3D": "骨骼扭转分散器3D",
	"CCDIK3D": "CCDIK3D",
	"CSGTorus3D": "CSG圆环3D",
	"CanvasGroup": "画布分组",
	"ConvertTransformModifier3D": "转换变换修改器3D",
	"CopyTransformModifier3D": "复制变换修改器3D",
	"FABRIK3D": "FABRIK3D",
	"FoldableContainer": "可折叠容器",
	"GPUParticlesAttractorBox3D": "GPU粒子盒形吸引器3D",
	"GPUParticlesAttractorSphere3D": "GPU粒子球形吸引器3D",
	"GPUParticlesAttractorVectorField3D": "GPU粒子矢量场吸引器3D",
	"GPUParticlesCollisionBox3D": "GPU粒子盒形碰撞3D",
	"GPUParticlesCollisionHeightField3D": "GPU粒子高度图碰撞3D",
	"GPUParticlesCollisionSDF3D": "GPU粒子SDF碰撞3D",
	"GPUParticlesCollisionSphere3D": "GPU粒子球形碰撞3D",
	"GeometryInstance3D": "几何体实例3D",
	"GraphElement": "图表元素",
	"GridMap": "网格地图",
	"HSeparator": "水平分隔符",
	"ImporterMeshInstance3D": "导入器网格实例3D",
	"JacobianIK3D": "雅可比IK3D",
	"LightOccluder2D": "遮光器2D",
	"LightmapGI": "光照贴图GI",
	"LightmapProbe": "光照贴图探针",
	"LimitAngularVelocityModifier3D": "限制角速度修改器3D",
	"LinkButton": "链接按钮",
	"LookAtModifier3D": "注视修改器3D",
	"ModifierBoneTarget3D": "修改器骨骼目标3D",
	"MultiMeshInstance2D": "多网格实例2D",
	"OccluderInstance3D": "遮挡器实例3D",
	"OpenXRCompositionLayerCylinder": "OpenXR圆柱体合成层",
	"OpenXRCompositionLayerEquirect": "OpenXR等距柱状合成层",
	"OpenXRCompositionLayerQuad": "OpenXR四边形合成层",
	"OpenXRHand": "OpenXR手部",
	"OpenXRRenderModel": "OpenXR渲染模型",
	"OpenXRRenderModelManager": "OpenXR渲染模型管理器",
	"OpenXRVisibilityMask": "OpenXR可见性遮罩",
	"PhysicalBone2D": "物理骨骼2D",
	"PhysicalBoneSimulator3D": "物理骨骼模拟器3D",
	"Popup": "弹出窗口",
	"RayCast2D": "射线投射2D",
	"ReferenceRect": "参考矩形",
	"ReflectionProbe": "反射探针",
	"RetargetModifier3D": "重定向修改器3D",
	"RootMotionView": "根运动视图",
	"ShaderGlobalsOverride": "着色器全局变量覆盖",
	"ShapeCast2D": "形状投射2D",
	"Skeleton2D": "骨架2D",
	"SkeletonIK3D": "骨架IK3D",
	"SoftBody3D": "柔体3D",
	"SplineIK3D": "样条IK3D",
	"SpringBoneCollision3D": "弹簧骨骼碰撞3D",
	"SpringBoneCollisionCapsule3D": "弹簧骨骼胶囊体碰撞3D",
	"SpringBoneCollisionPlane3D": "弹簧骨骼平面碰撞3D",
	"SpringBoneCollisionSphere3D": "弹簧骨骼球形碰撞3D",
	"SpringBoneSimulator3D": "弹簧骨骼模拟器3D",
	"StatusIndicator": "状态指示器",
	"TextureProgressBar": "纹理进度条",
	"TwoBoneIK3D": "双骨骼IK3D",
	"VSeparator": "垂直分隔符",
	"VehicleBody3D": "车辆刚体3D",
	"VirtualJoystick": "虚拟摇杆",
	"VisualInstance3D": "可视实例3D",
	"XRHandModifier3D": "XR手部修改器3D",
	"XRNode3D": "XR节点3D",
	"XRBodyModifier3D": "XR身体修改器3D",
	"XRFaceModifier3D": "XR面部修改器3D",
	"TooltipPanel": "提示面板",
}

# ============================================================
# 描述表：类名 → 中文描述
# ============================================================
const 描述表 := {
	"Node": "所有场景节点的基类，可包含子节点。",
	"Node2D": "所有 2D 场景节点的基类，包含位置、旋转、缩放等变换属性。",
	"Node3D": "所有 3D 场景节点的基类，包含三维变换属性。",
	"Control": "所有 UI 控件的基类，负责布局、事件和绘制。",
	"CanvasItem": "可绘制到画布上的节点的基类。",
	"CanvasLayer": "将子节点渲染到独立的画布层，用于 UI 分层。",
	"SubViewport": "独立的子视口，可单独渲染 2D/3D 内容。",
	"Sprite2D": "显示 2D 精灵纹理，支持动画帧、翻转、材质和着色器。",
	"AnimatedSprite2D": "播放 SpriteFrames 动画的 2D 精灵节点。",
	"CharacterBody2D": "2D 角色控制体，通过 move_and_slide 等实现受控移动。",
	"StaticBody2D": "静态碰撞体 2D，用于不可移动的障碍物等。",
	"RigidBody2D": "2D 刚体，受物理引擎影响自动模拟运动和碰撞。",
	"Area2D": "2D 区域检测，检测进入/离开的物体。",
	"Camera2D": "2D 相机，控制视口的可见区域，支持平滑跟随。",
	"TileMapLayer": "瓦片地图层，绘制瓦片集实现关卡地图。",
	"TileMap": "传统瓦片地图节点（新版建议使用 TileMapLayer）。",
	"Polygon2D": "绘制填充或描边多边形。",
	"Line2D": "绘制一条宽度可变的线段。",
	"Path2D": "定义 2D 曲线路径。",
	"PathFollow2D": "沿 Path2D 路径移动子节点。",
	"Marker2D": "2D 标记点，用于定位参考位置。",
	"GPUParticles2D": "GPU 加速的 2D 粒子系统，可创建火焰、烟雾等特效。",
	"CPUParticles2D": "CPU 计算的 2D 粒子系统。",
	"CollisionShape2D": "为 2D 物理体定义碰撞形状。",
	"CollisionPolygon2D": "用多边形定义 2D 碰撞形状。",
	"Parallax2D": "2D 视差效果节点，让图层以不同速度滚动。",
	"ParallaxBackground": "2D 视差背景容器。",
	"ParallaxLayer": "视差背景中的单个图层。",
	"Light2D": "2D 光照基类。",
	"PointLight2D": "点光源 2D，从中心向四周照射。",
	"DirectionalLight2D": "方向光 2D，平行照射。",
	"NavigationRegion2D": "2D 导航区域，定义可寻路区域。",
	"NavigationAgent2D": "2D 导航代理，驱动节点沿路径移动。",

	"MeshInstance3D": "渲染 3D 网格的实例节点。",
	"MultiMeshInstance3D": "批量渲染大量相同的网格实例。",
	"Sprite3D": "在 3D 空间中显示 2D 精灵纹理。",
	"Label3D": "在 3D 空间中显示文本标签。",
	"CharacterBody3D": "3D 角色控制体。",
	"StaticBody3D": "静态碰撞体 3D。",
	"RigidBody3D": "3D 刚体，受物理引擎模拟。",
	"Area3D": "3D 区域检测。",
	"Camera3D": "3D 相机，定义 3D 场景的视角。",
	"DirectionalLight3D": "方向光 3D，模拟太阳光等平行光源。",
	"OmniLight3D": "全向光 3D，向四周均匀照射。",
	"SpotLight3D": "聚光 3D，圆锥形照射范围。",
	"CollisionShape3D": "为 3D 物理体定义碰撞形状。",
	"CollisionPolygon3D": "用多边形定义 3D 碰撞形状。",
	"GPUParticles3D": "GPU 加速的 3D 粒子系统。",
	"CPUParticles3D": "CPU 计算的 3D 粒子系统。",
	"Marker3D": "3D 标记点。",
	"Path3D": "定义 3D 曲线路径。",
	"PathFollow3D": "沿 Path3D 路径移动子节点。",
	"NavigationRegion3D": "3D 导航区域。",
	"NavigationAgent3D": "3D 导航代理。",
	"Skeleton3D": "3D 骨骼，用于角色蒙皮动画。",
	"PhysicalBone3D": "物理模拟的骨骼节点。",
	"RayCast3D": "3D 射线检测，检测射线穿过的物体。",
	"ShapeCast3D": "3D 形状投射，检测形状扫过的物体。",
	"SpringArm3D": "弹簧臂 3D，用于相机防穿透碰撞。",
	"VehicleWheel3D": "车辆车轮 3D。",
	"Decal": "贴花 3D，将纹理投影到表面。",
	"CSGBox3D": "CSG 方块，用于布尔建模。",
	"CSGSphere3D": "CSG 球体。",
	"CSGCylinder3D": "CSG 圆柱。",
	"WorldEnvironment": "世界环境，配置天空、光照、雾等全局渲染。",
	"VoxelGI": "体素全局光照。",
	"VolumetricFog": "体积雾效果。",

	"Button": "可点击的按钮控件。",
	"BaseButton": "所有按钮控件的基类。",
	"Label": "显示纯文本的标签。",
	"RichTextLabel": "支持富文本（颜色、链接、图片等）的文本标签。",
	"LineEdit": "单行文本输入框。",
	"TextEdit": "多行文本编辑器。",
	"CodeEdit": "带代码高亮的文本编辑器。",
	"SpinBox": "数值微调框，可点击箭头或输入数值。",
	"ProgressBar": "进度条。",
	"HSlider": "水平滑块。",
	"VSlider": "垂直滑块。",
	"CheckButton": "开关按钮。",
	"CheckBox": "复选框。",
	"OptionButton": "下拉选项按钮。",
	"ColorPickerButton": "点击弹出颜色选择器的按钮。",
	"MenuButton": "点击弹出菜单的按钮。",
	"PopupMenu": "弹出式菜单。",
	"Panel": "通用面板容器。",
	"PanelContainer": "带样式的容器。",
	"ColorRect": "纯色矩形。",
	"TextureRect": "显示纹理的矩形。",
	"TextureButton": "用纹理作为外观的按钮。",
	"NinePatchRect": "九宫格纹理矩形，拉伸时保持边角不变形。",
	"VBoxContainer": "垂直排列子控件的容器。",
	"HBoxContainer": "水平排列子控件的容器。",
	"GridContainer": "网格排列子控件的容器。",
	"CenterContainer": "子控件居中显示的容器。",
	"MarginContainer": "子控件带边距的容器。",
	"ScrollContainer": "可滚动的容器。",
	"HSplitContainer": "水平分割条，可拖动调整左右大小。",
	"VSplitContainer": "垂直分割条，可拖动调整上下大小。",
	"SubViewportContainer": "显示子视口内容的容器。",
	"TabContainer": "标签页容器。",
	"ItemList": "项目列表控件。",
	"Tree": "树形列表控件。",
	"GraphEdit": "可视化图形编辑器框架。",
	"FileDialog": "文件选择对话框。",
	"ConfirmationDialog": "带确认/取消按钮的对话框。",
	"AcceptDialog": "带确定按钮的对话框。",
	"Window": "独立窗口。",
	"Timer": "定时器，用于延时或定时触发事件。",
	"AnimationPlayer": "播放动画资源的播放器。",
	"AnimationTree": "动画树，用于混合多个动画。",
	"AudioStreamPlayer": "播放音频流。",
	"AudioStreamPlayer2D": "播放 2D 空间音频。",
	"AudioStreamPlayer3D": "播放 3D 空间音频。",
	"AudioListener2D": "2D 音频监听器，决定音频收听位置。",
	"AudioListener3D": "3D 音频监听器。",
	"HTTPRequest": "发起 HTTP 请求并获取响应。",
	"MultiplayerSpawner": "多人游戏中自动生成/删除节点的管理器。",
	"MultiplayerSynchronizer": "多人游戏中同步节点属性。",
	"ResourcePreloader": "预加载资源，运行时按名称获取。",
}

# ============================================================
# 黑名单：不可用于创建节点的类型
# ============================================================
const 黑名单 := [
	"MissingNode",
	"MissingResource",
	"MissingTexture",
	"MissingFont",
	"MissingAudioStream",
	# qr 库自身类，非场景节点
	"QrCode",
	"Utils",
	"ReedSolomonGenerator",
]

# ============================================================
# 自定义翻译（用户在设置里修改的映射）
# ============================================================
static var 自定义翻译缓存: Dictionary = {}

# 获取显示名：自定义翻译 > 内置翻译 > 英文原名
static func 获取显示名(类名: String) -> String:
	if 自定义翻译缓存.has(类名):
		return String(自定义翻译缓存[类名])
	return 翻译表.get(类名, 类名)

# 从 EditorSettings 重新加载自定义翻译缓存
static func 重新加载自定义翻译() -> void:
	自定义翻译缓存 = {}
	if not Engine.is_editor_hint():
		return
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return
	var 范围: String = "global"
	if settings.has_setting("中文节点选择器/保存范围"):
		范围 = settings.get_setting("中文节点选择器/保存范围")
	if 范围 == "global":
		if settings.has_setting("中文节点选择器/自定义翻译"):
			var 数据 = settings.get_setting("中文节点选择器/自定义翻译")
			if 数据 is Dictionary:
				自定义翻译缓存 = 数据
	else:
		var 数据 = settings.get_project_metadata("中文节点选择器", "自定义翻译", {})
		if 数据 is Dictionary:
			自定义翻译缓存 = 数据

# ============================================================
# 类型条目
# ============================================================
class 节点条目:
	var 类名: String = ""
	var 显示名: String = ""
	var 描述: String = ""
	var 父类: String = ""
	var 图标: Texture2D = null
	var 来源: int = 来源内置        # 内置 / 自定义 / 编辑器
	var 脚本路径: String = ""       # 自定义脚本类路径
	var 可实例化: bool = true
	var 继承深度: int = 0
	var 是否实验性: bool = false
	var 是否弃用: bool = false

# 官方标记为"实验性"的节点类（来自 Godot 4.7 文档）
const 实验性类 := {
	"NavigationAgent2D": true,
	"NavigationAgent3D": true,
	"NavigationLink2D": true,
	"NavigationLink3D": true,
	"NavigationObstacle2D": true,
	"NavigationObstacle3D": true,
	"NavigationRegion2D": true,
	"NavigationRegion3D": true,
	"XRBodyModifier3D": true,
	"XRBodyTracker": true,
	"XRFaceModifier3D": true,
	"XRFaceTracker": true,
}

# 官方标记为"弃用"的节点类（来自 Godot 4.7 文档）
const 弃用类 := {
	"ParallaxBackground": true,
	"ParallaxLayer": true,
	"TileMap": true,
}

# ============================================================
# 扫描所有类型
# ============================================================
static func 扫描类型(基础类型: String = "Node") -> Array[节点条目]:
	var 结果: Array[节点条目] = []
	var 已见 := {}

	# 1. 内置类型：先收可直接实例化的类
	var 可实例化列表: Array[节点条目] = []
	for 类名 in ClassDB.get_class_list():
		if 已见.has(类名) or 黑名单.has(类名):
			continue
		if not ClassDB.class_exists(类名):
			continue
		if not ClassDB.is_parent_class(类名, 基础类型):
			continue
		if not ClassDB.can_instantiate(类名):
			continue
		var 条目 := 构建内置条目(类名, 基础类型, true)
		结果.append(条目)
		可实例化列表.append(条目)
		已见[类名] = true

	# 2. 补抽象祖先分类（复刻原版 CreateDialog：可实例化类的抽象父类
	#    以分类节点显示，可搜索、可翻译、可映射，但不可实例化）
	for 条目 in 可实例化列表:
		var 父 := ClassDB.get_parent_class(条目.类名)
		while not 父.is_empty() and 父 != 基础类型 and 父 != "Object" and ClassDB.class_exists(父):
			if ClassDB.can_instantiate(父):
				break  # 遇到可实例化祖先即停（它已被第 1 步收录）
			if not 已见.has(父) and not 黑名单.has(父):
				var 父条目 := 构建内置条目(父, 基础类型, false)
				if 父条目 != null:
					结果.append(父条目)
					已见[父] = true
			父 = ClassDB.get_parent_class(父)

	# 2. 全局脚本类（自定义类型）
	var 全局类列表 = ProjectSettings.get_global_class_list()
	for 全局 in 全局类列表:
		var 类名: String = 全局.get("class", "")
		if 类名.is_empty() or 已见.has(类名):
			continue
		if 黑名单.has(类名):
			continue
		var 脚本路径: String = 全局.get("path", "")
		var 基类: String = 全局.get("base", "")
		if not 继承于(基类, 基础类型):
			continue
		var 条目 := 节点条目.new()
		条目.类名 = 类名
		条目.显示名 = 获取显示名(类名)
		条目.描述 = 获取描述(类名)
		条目.父类 = 基类
		条目.来源 = 来源自定义
		条目.脚本路径 = 脚本路径
		条目.图标 = 获取图标(类名)
		条目.可实例化 = not _脚本是否抽象(脚本路径)
		结果.append(条目)
		已见[类名] = true

	return 结果

# ============================================================
# 获取描述：简要描述（加粗）+ 完整描述
# 中文优先：官方中文 > 内置中文简介 > 官方英文
# ============================================================
static func 获取描述(类名: String) -> String:
	var brief := 官方描述.中文简介.get(类名, 描述表.get(类名, 官方描述.英文简介.get(类名, "")))
	var full := 官方描述.中文描述.get(类名, 描述表.get(类名, 官方描述.英文描述.get(类名, "")))
	var 结果 := ""
	if not brief.is_empty():
		结果 += "[b]%s[/b]\n" % brief
	if not full.is_empty():
		结果 += full
	return 结果

# ============================================================
# 构建一个内置类型条目，不符合条件返回 null
# ============================================================
static func 构建内置条目(类名: String, 基础类型: String, 可实例化: bool = true) -> 节点条目:
	if 黑名单.has(类名):
		return null
	if not ClassDB.class_exists(类名):
		return null
	if not ClassDB.is_parent_class(类名, 基础类型):
		return null

	var 条目 := 节点条目.new()
	条目.类名 = 类名
	条目.显示名 = 获取显示名(类名)
	条目.描述 = 获取描述(类名)
	条目.父类 = ClassDB.get_parent_class(类名)
	条目.来源 = 判断来源(类名)
	条目.图标 = 获取图标(类名)
	条目.可实例化 = 可实例化
	条目.继承深度 = 继承深度(类名, 基础类型)
	条目.是否实验性 = 实验性类.has(类名)
	条目.是否弃用 = 弃用类.has(类名)
	return 条目

# ============================================================
# 判断类型来源：内置 / 自定义 / 编辑器
# 注：GDScript 无法访问 ClassDB.get_api_type()，
#     编辑器专属类通过黑名单识别（默认隐藏）。
# ============================================================
const 编辑器类 := {
	"EditorNode": true,
	"EditorPlugin": true,
	"EditorInspector": true,
	"EditorInspectorPlugin": true,
	"ScriptEditor": true,
	"ScriptCreateDialog": true,
	"ScriptTextEditor": true,
	"SceneTreeDock": true,
	"InspectorDock": true,
	"FileSystemDock": true,
	"OutputPanel": true,
	"EditorDebuggerNode": true,
	"EditorFileDialog": true,
	"PropertySelector": true,
	"QuickOpen": true,
	"SceneTreeDialog": true,
	"EditorPath": true,
	"EditorFeatureProfile": true,
	"EditorCommandPalette": true,
	"EditorDock": true,
	"EditorProperty": true,
	"EditorResourcePicker": true,
	"EditorScriptPicker": true,
	"EditorSpinSlider": true,
	"GridMapEditorPlugin": true,
	"OpenXRBindingModifierEditor": true,
	"OpenXRInteractionProfileEditor": true,
}

static func 判断来源(类名: String) -> int:
	if 编辑器类.has(类名):
		return 来源编辑器
	if ClassDB.class_exists(类名):
		return 来源内置
	return 来源自定义

# ============================================================
# 继承链判断：类名是否继承自 祖先
# ============================================================
static func 继承于(类名: String, 祖先: String) -> bool:
	if 类名 == 祖先:
		return true
	if ClassDB.class_exists(类名):
		return ClassDB.is_parent_class(类名, 祖先)
	return false

# ============================================================
# 继承深度（用于排序）
# ============================================================
static func 继承深度(类名: String, 祖先: String) -> int:
	var depth := 0
	var current := 类名
	while current != 祖先 and ClassDB.class_exists(current):
		current = ClassDB.get_parent_class(current)
		depth += 1
	return depth

# ============================================================
# 获取类图标
# ============================================================
static func 获取图标(类名: String) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var theme = EditorInterface.get_editor_theme()
	if theme == null:
		return null
	var 图标名 := 类名
	if not theme.has_icon(图标名, "EditorIcons"):
		图标名 = "Object"
	if theme.has_icon(图标名, "EditorIcons"):
		return theme.get_icon(图标名, "EditorIcons")
	return null

# ============================================================
# 判断脚本是否抽象（用于自定义类）
# ============================================================
static func _脚本是否抽象(脚本路径: String) -> bool:
	if 脚本路径.is_empty() or not ResourceLoader.exists(脚本路径, "Script"):
		return false
	var 脚本: GDScript = ResourceLoader.load(脚本路径, "Script")
	if 脚本 == null:
		return false
	return 脚本.is_abstract()
