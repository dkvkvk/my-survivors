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
	_setup_video_background()
	_setup_background_motion()
	_setup_talismans()
	_setup_character_picker()
	_setup_settings_button()
	_setup_achievements_button()
	_setup_settings_panel()

	var records := SaveGame.load_records()
	%RecordsLabel.text = "最高纪录　守夜 %d:%02d　·　斩妖 %d　·　修为 %d　·　灵石 %d（万宝楼可花）" % [
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
var _char_caption: Label = null


## 视频背景（P7）：桌面版播放 menu_loop.ogv（用户 AI 生成、CI 转码 OGV）；
## Web 版跳过（视频不进 Web 包，保留代码动效，省 1.7MB 首载）。
var _video_bg: VideoStreamPlayer = null


func _setup_video_background() -> void:
	if OS.has_feature("web"):
		return
	var path := "res://menu_loop.ogv"
	if not ResourceLoader.exists(path):
		return
	var stream: VideoStreamTheora = load(path)
	if stream == null:
		return
	_video_bg = VideoStreamPlayer.new()
	_video_bg.stream = stream
	_video_bg.loop = true
	_video_bg.autoplay = true
	_video_bg.expand = true
	_video_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_video_bg)
	move_child(_video_bg, 1)   # Background 之后、Dim 之前（Dim 压暗保证文字可读）


func _setup_character_picker() -> void:
	var cur: String = SaveGame.get_character()
	var defs: Array = Characters.LIST
	var total: float = defs.size() * CHAR_CARD_W + (defs.size() - 1) * CHAR_GAP

	var cap := Label.new()
	cap.set_anchors_preset(Control.PRESET_CENTER)
	cap.offset_left = -500
	cap.offset_top = -96
	cap.offset_right = 500
	cap.offset_bottom = -32
	cap.text = "— 选 择 身 份 —"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM   # 文字贴矩形底边，避免最小高度把它顶出去
	cap.add_theme_font_size_override("font_size", 28)
	# 上一行「最高纪录/灵石」是两行文字，会略微溢出它自己的矩形——把字号和矩形收紧，
	# 否则它会压住下面这行「选择身份」（2026-09-24 用户截图反馈的糅杂之一）
	var rec := get_node_or_null("%RecordsLabel")
	if rec != null:
		rec.offset_top = -150
		rec.offset_bottom = -106
		rec.add_theme_font_size_override("font_size", 30)
	cap.add_theme_color_override("font_color", Color(0.75, 0.88, 0.82))
	cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	cap.add_theme_constant_override("outline_size", 8)
	add_child(cap)
	_char_caption = cap

	for i in defs.size():
		var def: Dictionary = defs[i]
		var id: String = str(def["id"])
		var x0: float = -total / 2.0 + float(i) * (CHAR_CARD_W + CHAR_GAP)
		var card := Button.new()
		card.set_anchors_preset(Control.PRESET_CENTER)
		card.offset_left = x0
		card.offset_top = -24
		card.offset_right = x0 + CHAR_CARD_W
		card.offset_bottom = -24 + CHAR_CARD_H
		card.text = ""
		card.pressed.connect(_on_character_clicked.bind(id))
		add_child(card)
		# 头像：从用户交付的方向表里抽出的"正面那一格"（守山人用主角表 col0 row0）
		var ppath := "res://assets/ui/portrait_%s.png" % id
		if ResourceLoader.exists(ppath):
			var pic := TextureRect.new()
			pic.position = Vector2(10, 16)
			pic.size = Vector2(50, 50)
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			# ⚠️ 不设 expand_mode 的话，TextureRect 的最小尺寸 = 贴图尺寸（96x96），
			# 我设的 50x50 会被顶大，头像就压到右边的名字和描述上（2026-09-24 截图发现）
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pic.texture = load(ppath)
			card.add_child(pic)
		var nm := Label.new()
		nm.set_anchors_preset(Control.PRESET_FULL_RECT)
		nm.offset_left = 70
		nm.offset_top = 10
		nm.offset_right = -10
		nm.offset_bottom = -64
		nm.text = str(def["name"])
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.add_theme_font_size_override("font_size", 34)
		nm.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)
		var ds := Label.new()
		ds.set_anchors_preset(Control.PRESET_FULL_RECT)
		# ⚠️ FULL_RECT 锚点下 offset_top 是"从卡片顶边向下"的位移，
		# 写成负值 = 把整块文字推到卡片外面（会压住标题和上一行）——这正是糅杂的根因。
		ds.offset_top = 56
		ds.offset_bottom = -6
		ds.offset_left = 66   # 让开左边的头像栏（头像占 10..60），否则文字会压在人物身上
		ds.offset_right = -10
		ds.text = str(def["desc"])
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ds.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		ds.clip_text = true
		ds.add_theme_font_size_override("font_size", 17)
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



## ---------- 设置（P7）：抖动强度 / 音乐 / 音效，写入存档 ----------

var _settings_panel: Control = null


func _setup_settings_button() -> void:
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.offset_left = -420
	b.offset_top = 360
	b.offset_right = -180
	b.offset_bottom = 440
	b.text = "设 置"
	b.add_theme_font_size_override("font_size", 40)
	b.pressed.connect(_open_settings)
	add_child(b)


func _setup_settings_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	layer.name = "SettingsUI"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	layer.add_child(root)
	_settings_panel = root

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_top = -260
	panel.offset_right = 420
	panel.offset_bottom = 260
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.11, 0.97)
	sb.border_color = Color(0.35, 0.8, 0.9, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -380
	title.offset_top = -230
	title.offset_right = 380
	title.offset_bottom = -180
	title.text = "设  置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	panel.add_child(title)

	# ⚠️ _slider 的 y 是**相对面板中心**的位移，面板只有 520 高（±260）——
	# 之前传 460/560/660 直接把三个滑杆甩到面板下方 400px 处（截图发现）
	_slider(panel, "抖动强度", -70, float(SaveGame.get_setting("shake", 1.0)),
		func(v: float):
			SaveGame.set_setting("shake", v)
			VFX.set_shake_scale(v))
	_slider(panel, "音乐音量", 30, float(SaveGame.get_setting("music", 1.0)),
		func(v: float):
			SaveGame.set_setting("music", v)
			Audio.music_volume = v
			Audio.apply_volumes())
	_slider(panel, "音效音量", 130, float(SaveGame.get_setting("sfx", 1.0)),
		func(v: float):
			SaveGame.set_setting("sfx", v)
			Audio.sfx_volume = v
			Audio.apply_volumes())

	var close := Button.new()
	close.set_anchors_preset(Control.PRESET_CENTER)
	close.offset_left = -120
	close.offset_top = 170
	close.offset_right = 120
	close.offset_bottom = 236
	close.text = "关 闭"
	close.add_theme_font_size_override("font_size", 34)
	close.pressed.connect(func():
		root.visible = false
		_settings_panel = null
		queue_free()   # 关闭即销毁整层，下次点「设置」重建（读回最新存档值）
	)
	panel.add_child(close)


func _slider(panel: Control, label: String, y: float, value: float, on_change: Callable) -> void:
	var cap := Label.new()
	cap.set_anchors_preset(Control.PRESET_CENTER)
	cap.offset_left = -360
	cap.offset_top = y - 46
	cap.offset_right = 360
	cap.offset_bottom = y - 10
	cap.text = label
	cap.add_theme_font_size_override("font_size", 30)
	panel.add_child(cap)

	var row := HSlider.new()
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.offset_left = -360
	row.offset_top = y
	row.offset_right = 240
	row.offset_bottom = y + 34
	row.min_value = 0.0
	row.max_value = 1.5 if label == "抖动强度" else 1.0
	row.step = 0.05
	row.value = value
	panel.add_child(row)

	var val := Label.new()
	val.set_anchors_preset(Control.PRESET_CENTER)
	val.offset_left = 260
	val.offset_top = y
	val.offset_right = 360
	val.offset_bottom = y + 34
	val.add_theme_font_size_override("font_size", 26)
	panel.add_child(val)

	var refresh := func(v: float) -> void:
		val.text = "%d%%" % int(round(v * 100.0))
	refresh.call(value)
	row.value_changed.connect(func(v: float):
		refresh.call(v)
		on_change.call(v))




## ---------- 成就（P7）：主菜单可查，结算时解锁 ----------

var _ach_panel: Control = null


func _setup_achievements_button() -> void:
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.offset_left = 180
	b.offset_top = 360
	b.offset_right = 420
	b.offset_bottom = 440
	b.text = "成 就"
	b.add_theme_font_size_override("font_size", 40)
	b.pressed.connect(_open_achievements)
	add_child(b)


func _open_achievements() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 44
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	_ach_panel = root

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.84)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -520
	panel.offset_top = -430
	panel.offset_right = 520
	panel.offset_bottom = 430
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.11, 0.97)
	sb.border_color = Color(0.35, 0.8, 0.9, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var records := SaveGame.load_records()
	var stats: Dictionary = SaveGame.get_stats()
	# 回填：老存档里"早就达标但当时还没这个功能"的成就（例如守夜早就超过 10 分钟）
	var unlocked: Array = SaveGame.sync_achievements()

	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -480
	title.offset_top = -408
	title.offset_right = 480
	title.offset_bottom = -352
	title.text = "成 就    %d / %d" % [unlocked.size(), Achievements.LIST.size()]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	panel.add_child(title)

	var y := -360.0
	for a in Achievements.LIST:
		var done: bool = unlocked.has(str(a["id"]))
		var cur := Achievements.progress(stats, records, a)
		var row := Label.new()
		row.set_anchors_preset(Control.PRESET_CENTER)
		row.offset_left = -468
		row.offset_top = y
		row.offset_right = 468
		row.offset_bottom = y + 32
		row.text = "%s  %s          %d / %d" % ["★" if done else "·", str(a["name"]), mini(cur, int(a["target"])), int(a["target"])]
		row.add_theme_font_size_override("font_size", 22)
		row.add_theme_color_override("font_color", Color(1, 0.9, 0.5) if done else Color(0.62, 0.7, 0.78))
		panel.add_child(row)
		var sub := Label.new()
		sub.set_anchors_preset(Control.PRESET_CENTER)
		sub.offset_left = -448
		sub.offset_top = y + 31
		sub.offset_right = 468
		sub.offset_bottom = y + 52
		sub.text = str(a["desc"])
		sub.add_theme_font_size_override("font_size", 15)
		sub.add_theme_color_override("font_color", Color(0.5, 0.6, 0.68))
		panel.add_child(sub)
		y += 54.0

	var close := Button.new()
	close.set_anchors_preset(Control.PRESET_CENTER)
	close.offset_left = -120
	close.offset_top = 352
	close.offset_right = 120
	close.offset_bottom = 392
	close.text = "关 闭"
	close.add_theme_font_size_override("font_size", 34)
	close.pressed.connect(func():
		layer.queue_free()
		_ach_panel = null)
	panel.add_child(close)


func _open_settings() -> void:
	# 重建一层新的面板，保证读到最新存档值
	_setup_settings_panel()
	_settings_panel.visible = true
	Audio.play("res://sounds/pickup.wav", false, 1.2, 0.3)

