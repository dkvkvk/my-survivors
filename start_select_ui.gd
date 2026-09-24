extends CanvasLayer

## 开局选法宝（P6）：进战斗时弹出 4 张卡并暂停游戏，选完才正式开打。
## 法宝种类（6 种）多于法宝位（4 位）之后，本命飞剑固定占一张、其余随机抽 3 张，
## 这样"这一局能拿到哪几件"才有意义（全部列出也会超出面板宽度）。
## 本命飞剑是**固定基础法宝**（没有它就没有自动攻击，开局会没法玩），
## 所以选本命飞剑 = 起手直接给到 Balance.START_WEAPON_LEVEL；选其它 = 追加装备（法宝位与技能槽各 +1）。
## 纯代码构建界面，和 inventory_ui / skill_bar 一致。

const PANEL_W := 1580.0
const PANEL_H := 648.0
const CARD_W := 356.0
const CARD_H := 456.0
const CARD_GAP := 22.0
const CARD_COUNT := 4

var _player: Node
var _root: Control
var _built := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## 打开界面并暂停游戏（game.gd 在 _ready 里 call_deferred 调用）
func open(p_player: Node) -> void:
	_player = p_player
	if not _built:
		_build()
		_built = true
	visible = true
	get_tree().paused = true


func _choose(id: String) -> void:
	if _player != null:
		_player.apply_start_weapon(id)
	visible = false
	get_tree().paused = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var panel := Panel.new()
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.position = Vector2((1920.0 - PANEL_W) / 2.0, (1080.0 - PANEL_H) / 2.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.11, 0.97)
	sb.border_color = Color(0.35, 0.8, 0.9, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "择 一 件 起 手 法 宝"
	title.position = Vector2(44, 22)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	panel.add_child(title)

	var sub := Label.new()
	sub.text = "本命飞剑是固定本命法宝（神念御剑，自动杀敌）；选它则起手直达 %d 阶，选其它则随身佩戴" % Balance.START_WEAPON_LEVEL
	sub.position = Vector2(46, 96)
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.62, 0.78, 0.88))
	panel.add_child(sub)

	var total: float = float(CARD_COUNT) * CARD_W + float(CARD_COUNT - 1) * CARD_GAP
	var x0: float = (PANEL_W - total) / 2.0
	var picks: Array = _pick_cards()
	for i in picks.size():
		_card(panel, picks[i], Vector2(x0 + float(i) * (CARD_W + CARD_GAP), 148.0))


## 抽 4 张：本命飞剑固定一张（没有它就没有自动攻击），其余从剩下的法宝里随机取
func _pick_cards() -> Array:
	var base: Dictionary = {}
	var pool: Array = []
	for def in Weapons.LIST:
		if str(def.get("id", "")) == "shuriken":
			base = def
		else:
			pool.append(def)
	pool.shuffle()
	var out: Array = []
	if not base.is_empty():
		out.append(base)
	for i in mini(CARD_COUNT - 1, pool.size()):
		out.append(pool[i])
	return out


func _card(p: Control, def: Dictionary, pos: Vector2) -> void:
	var id: String = str(def.get("id", ""))
	var btn := Button.new()
	btn.position = pos
	btn.size = Vector2(CARD_W, CARD_H)
	btn.text = ""
	btn.pressed.connect(_choose.bind(id))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.11, 0.15, 0.95)
	normal.border_color = Color(0.3, 0.62, 0.7, 0.7)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	var hot := StyleBoxFlat.new()
	hot.bg_color = Color(0.10, 0.17, 0.22, 0.98)
	hot.border_color = Color(0.45, 0.95, 1.0, 1.0)
	hot.set_border_width_all(4)
	hot.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hot)
	btn.add_theme_stylebox_override("pressed", hot)
	btn.add_theme_stylebox_override("focus", normal)
	p.add_child(btn)

	var icon := TextureRect.new()
	icon.position = Vector2((CARD_W - 132.0) / 2.0, 30)
	icon.size = Vector2(132, 132)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ip: String = str(def.get("icon", ""))
	if ip != "" and ResourceLoader.exists(ip):
		icon.texture = load(ip)
	btn.add_child(icon)

	_text(btn, str(def.get("name", id)), Vector2(0, 176), Vector2(CARD_W, 56), 42, Color(1, 0.92, 0.6))
	_text(btn, str(def.get("desc", "")), Vector2(22, 244), Vector2(CARD_W - 44.0, 96), 26, Color(0.8, 0.92, 1.0))
	var extra := ""
	if id == "shuriken":
		extra = "已自带 → 起手直达 %d 阶" % Balance.START_WEAPON_LEVEL
	else:
		extra = "随身佩戴：法宝位 +1、神通槽 +1"
	_text(btn, extra, Vector2(22, 348), Vector2(CARD_W - 44.0, 92), 24, Color(0.55, 1.0, 0.85))


func _text(p: Control, s: String, pos: Vector2, size: Vector2, font_size: int, col: Color) -> void:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.size = size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	p.add_child(l)
