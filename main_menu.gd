extends CanvasLayer

## 主菜单（U5）：项目主场景。开始游戏切换到战斗场景，
## 最高纪录从 SaveGame 读取（user://records.json）。
##
## 动效（P5）：原本想用循环视频，但 Godot 4 只支持 Ogg Theora（.ogv），
## 标准版放不了 MP4，本机也没有 ffmpeg 转码。所以改用**代码驱动**：
##   1) 背景极缓慢视差漂移（先放大 1.08 再平移，不会露边）
##   2) 符纸飘落（符纸贴图代码绘制，不占素材）
##   3) 霓虹呼吸式明暗脉动
## 好处：原生 + Web 都能跑、任何分辨率都清晰、循环天然无缝、几乎不占体积。

const BG_OVERSCAN := 1.08      # 背景放大倍数，给漂移留余量
const DRIFT_X := 26.0          # 水平漂移幅度（像素）
const DRIFT_Y := 12.0          # 垂直漂移幅度
const DRIFT_SPEED_X := 0.11    # 角速度（越小越慢）
const DRIFT_SPEED_Y := 0.07
const PULSE_SPEED := 0.6       # 灵光脉动速度
const PULSE_DEPTH := 0.08      # 脉动幅度

var _bg: TextureRect
var _bg_base := Vector2.ZERO
var _t := 0.0


func _ready():
	Audio.play_music("res://sounds/bgm_menu.wav")
	_setup_background_motion()
	_setup_talismans()
	_setup_character_picker()

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
	# 测试钩子（HANDOVER §3）：MS_AUTOSTART=1 直接进战斗，省去手点菜单（探针/压测用）
	if OS.get_environment("MS_AUTOSTART") == "1":
		_on_start_button_pressed()


## 背景：放大一点并以中心为轴，之后做正弦漂移就不会露出边缘
func _setup_background_motion() -> void:
	_bg = $Background
	_bg.pivot_offset = _bg.size / 2.0
	_bg.scale = Vector2(BG_OVERSCAN, BG_OVERSCAN)
	_bg_base = _bg.position


## 符纸飘落：符纸贴图代码绘制（5x8 的黄纸 + 一点朱砂符印），不需要美术素材。
## 世界观：山风卷着镇魔幡的符纸飘过山门。
func _setup_talismans() -> void:
	var papers := CPUParticles2D.new()
	papers.name = "Talismans"
	papers.texture = _make_talisman_texture()
	papers.position = Vector2(960, -60)
	papers.amount = 28
	papers.lifetime = 13.0
	papers.preprocess = 13.0
	papers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	papers.emission_rect_extents = Vector2(1120, 40)
	papers.direction = Vector2(0, 1)
	papers.spread = 22.0
	papers.gravity = Vector2(16, 30)
	papers.initial_velocity_min = 20.0
	papers.initial_velocity_max = 44.0
	papers.angular_velocity_min = -70.0
	papers.angular_velocity_max = 70.0
	papers.scale_amount_min = 2.0
	papers.scale_amount_max = 3.6
	papers.color = Color(1.0, 0.97, 0.88, 0.92)
	add_child(papers)

func _make_talisman_texture() -> ImageTexture:
	var img := Image.create(5, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var paper := Color(0.93, 0.88, 0.70, 1.0)
	var edge := Color(0.76, 0.68, 0.46, 1.0)
	var seal := Color(0.71, 0.21, 0.17, 1.0)
	for y in 8:
		for x in 5:
			img.set_pixel(x, y, edge if y >= 7 else paper)
	img.set_pixel(2, 3, seal)
	img.set_pixel(2, 4, seal)
	img.set_pixel(1, 5, seal)
	img.set_pixel(3, 2, seal)
	return ImageTexture.create_from_image(img)
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	if _bg != null:
		# 极缓慢视差漂移：两个不同周期叠加，看不出循环点
		_bg.position = _bg_base + Vector2(
			sin(_t * DRIFT_SPEED_X) * DRIFT_X,
			cos(_t * DRIFT_SPEED_Y) * DRIFT_Y
		)
		# 灵光呼吸
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


## ---------- 身份选择（P7 多角色）----------
## 主菜单直接选身份（3 张卡），选择写入存档；进战斗后由 player._apply_character() 生效。
## 配色是代码调色；想要各自独立的行走表，见 XIANXIA_ART_PROMPTS.md 第八节 B 组提示词。

const CHAR_CARD_W := 320.0
const CHAR_CARD_H := 118.0
const CHAR_GAP := 24.0
var _char_cards: Array = []


func _setup_character_picker() -> void:
	var cur: String = SaveGame.get_character()
	var defs: Array = Characters.LIST
	var total: float = defs.size() * CHAR_CARD_W + (defs.size() - 1) * CHAR_GAP

	var cap := Label.new()
	cap.set_anchors_preset(Control.PRESET_CENTER)
	cap.offset_left = -500
	cap.offset_top = -66
	cap.offset_right = 500
	cap.offset_bottom = -34
	cap.text = "— 选 择 身 份 —"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 30)
	cap.add_theme_color_override("font_color", Color(0.75, 0.88, 0.82))
	cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	cap.add_theme_constant_override("outline_size", 8)
	add_child(cap)

	for i in defs.size():
		var def: Dictionary = defs[i]
		var id: String = str(def["id"])
		var x0: float = -total / 2.0 + float(i) * (CHAR_CARD_W + CHAR_GAP)
		var card := Button.new()
		card.set_anchors_preset(Control.PRESET_CENTER)
		card.offset_left = x0
		card.offset_top = -28
		card.offset_right = x0 + CHAR_CARD_W
		card.offset_bottom = -28 + CHAR_CARD_H
		card.text = ""
		card.pressed.connect(_on_character_clicked.bind(id))
		add_child(card)
		var nm := Label.new()
		nm.set_anchors_preset(Control.PRESET_FULL_RECT)
		nm.offset_top = 12
		nm.offset_bottom = -66
		nm.text = str(def["name"])
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 40)
		nm.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)
		var ds := Label.new()
		ds.set_anchors_preset(Control.PRESET_FULL_RECT)
		ds.offset_top = -60
		ds.offset_bottom = -12
		ds.offset_left = 14
		ds.offset_right = -14
		ds.text = str(def["desc"])
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ds.vertical_alignment = 1
		ds.add_theme_font_size_override("font_size", 18)
		ds.add_theme_color_override("font_color", Color(0.78, 0.9, 0.95))
		ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ds)
		_char_cards.append({"id": id, "card": card, "nm": nm, "ds": ds})
	_refresh_character_picker()


func _on_character_clicked(id: String) -> void:
	SaveGame.set_character(id)
	Audio.play("res://sounds/pickup.wav", false, 1.4, 0.3)
	_refresh_character_picker()


func _refresh_character_picker() -> void:
	var cur: String = SaveGame.get_character()
	for c in _char_cards:
		var sel: bool = str(c["id"]) == cur
		var card: Button = c["card"]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.11, 0.15, 0.9) if sel else Color(0.05, 0.07, 0.1, 0.55)
		sb.border_color = Color(0.45, 0.95, 1.0, 0.95) if sel else Color(0.3, 0.45, 0.55, 0.5)
		sb.set_border_width_all(4 if sel else 2)
		sb.set_corner_radius_all(10)
		card.add_theme_stylebox_override("normal", sb)
		var sbh := StyleBoxFlat.new()
		sbh.bg_color = Color(0.09, 0.14, 0.19, 0.92) if sel else Color(0.07, 0.11, 0.15, 0.7)
		sbh.border_color = Color(0.45, 0.95, 1.0, 1.0) if sel else Color(0.3, 0.45, 0.55, 0.6)
		sbh.set_border_width_all(4 if sel else 2)
		sbh.set_corner_radius_all(10)
		card.add_theme_stylebox_override("hover", sbh)
		card.add_theme_stylebox_override("pressed", sbh)
		card.add_theme_stylebox_override("focus", sb)
		(c["nm"] as Label).add_theme_color_override("font_color",
			Color(1, 0.92, 0.6) if sel else Color(0.75, 0.82, 0.9))
		(c["ds"] as Label).modulate.a = 1.0 if sel else 0.55

