extends CanvasLayer

## 主菜单（U5）：项目主场景。开始游戏切换到战斗场景，
## 最高纪录从 SaveGame 读取（user://records.json）。
##
## 动效（P5）：原本想用循环视频，但 Godot 4 只支持 Ogg Theora（.ogv），
## 标准版放不了 MP4，本机也没有 ffmpeg 转码。所以改用**代码驱动**：
##   1) 背景极缓慢视差漂移（先放大 1.08 再平移，不会露边）
##   2) 樱花花瓣飘落（花瓣贴图代码绘制，不占素材）
##   3) 霓虹呼吸式明暗脉动
## 好处：原生 + Web 都能跑、任何分辨率都清晰、循环天然无缝、几乎不占体积。

const BG_OVERSCAN := 1.08      # 背景放大倍数，给漂移留余量
const DRIFT_X := 26.0          # 水平漂移幅度（像素）
const DRIFT_Y := 12.0          # 垂直漂移幅度
const DRIFT_SPEED_X := 0.11    # 角速度（越小越慢）
const DRIFT_SPEED_Y := 0.07
const PULSE_SPEED := 0.6       # 霓虹脉动速度
const PULSE_DEPTH := 0.08      # 脉动幅度

var _bg: TextureRect
var _bg_base := Vector2.ZERO
var _t := 0.0


func _ready():
	Audio.play_music("res://sounds/bgm_menu.wav")
	_setup_background_motion()
	_setup_sakura()

	var records := SaveGame.load_records()
	%RecordsLabel.text = "最高纪录　守夜 %d:%02d　斩妖 %d　修为 %d\n灵石 %d（坊市万宝楼可花）" % [
		int(records["best_time"]) / 60,
		int(records["best_time"]) % 60,
		records["best_kills"],
		records["best_level"],
		int(records["coins"]),
	]
	# Web 版跑在浏览器里没有窗口可关，隐藏退出按钮
	if OS.has_feature("web"):
		%QuitButton.hide()


## 背景：放大一点并以中心为轴，之后做正弦漂移就不会露出边缘
func _setup_background_motion() -> void:
	_bg = $Background
	_bg.pivot_offset = _bg.size / 2.0
	_bg.scale = Vector2(BG_OVERSCAN, BG_OVERSCAN)
	_bg_base = _bg.position


## 樱花花瓣：花瓣贴图代码绘制（7x6 的椭圆 + 一点深边），不需要美术素材
func _setup_sakura() -> void:
	var petals := CPUParticles2D.new()
	petals.name = "Sakura"
	petals.texture = _make_petal_texture()
	petals.position = Vector2(960, -60)
	petals.amount = 28
	petals.lifetime = 13.0
	petals.preprocess = 13.0
	petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	petals.emission_rect_extents = Vector2(1120, 40)
	petals.direction = Vector2(0, 1)
	petals.spread = 22.0
	petals.gravity = Vector2(16, 30)          # 轻微斜向飘落
	petals.initial_velocity_min = 20.0
	petals.initial_velocity_max = 44.0
	petals.angular_velocity_min = -70.0       # 边落边转，像真的花瓣
	petals.angular_velocity_max = 70.0
	petals.scale_amount_min = 2.0
	petals.scale_amount_max = 3.6
	petals.color = Color(1.0, 0.80, 0.88, 0.9)
	add_child(petals)


func _make_petal_texture() -> ImageTexture:
	var img := Image.create(7, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := Color(1.0, 0.84, 0.91, 1.0)
	var edge := Color(1.0, 0.62, 0.78, 1.0)
	for y in 6:
		for x in 7:
			var dx := (x - 3.0) / 3.2
			var dy := (y - 2.5) / 2.6
			if dx * dx + dy * dy <= 1.0:
				# 下缘用深一点的粉色，做出花瓣的厚度
				img.set_pixel(x, y, edge if y >= 4 else fill)
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	if _bg != null:
		# 极缓慢视差漂移：两个不同周期叠加，看不出循环点
		_bg.position = _bg_base + Vector2(
			sin(_t * DRIFT_SPEED_X) * DRIFT_X,
			cos(_t * DRIFT_SPEED_Y) * DRIFT_Y
		)
		# 霓虹呼吸
		var pulse: float = 1.0 - PULSE_DEPTH + PULSE_DEPTH * sin(_t * PULSE_SPEED)
		_bg.modulate = Color(pulse, pulse, pulse, 1.0)


func _on_start_button_pressed():
	Audio.play("res://sounds/pickup.wav", false, 1.6, 0.25)
	Fader.fade_to_scene("res://survivors_game.tscn")


func _on_shop_button_pressed():
	Audio.play("res://sounds/pickup.wav", false, 1.6, 0.25)
	Fader.fade_to_scene("res://shop.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
