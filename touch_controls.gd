extends CanvasLayer

## 触屏操作（P2b）：左下虚拟摇杆 + 右下神通按钮。纯代码构建，不占美术素材。
##
## 只在**真的有触摸**时启用（移动端 / Web 移动端 / 系统报告有触摸屏），
## 桌面键鼠下整个节点自毁，不抢输入、不挡视线。
## 桌面调试与截图可以强制开启：命令行加 @@--touch@@，或设环境变量 @@MS_TOUCH=1@@。
##
## 对外接口：player.gd 通过 "touch_input" 组读 @@direction@@（0~1 的移动向量）；
## 神通按钮直接调 @@player.cast_skill(i)@@。

const STICK_MARGIN := 200.0       # 摇杆中心距左下角
const STICK_RING_RADIUS := 96.0   # 底圈半径（描边圆环，比纯光晕清晰）
const STICK_KNOB_RADIUS := 34.0
const STICK_MAX := 96.0           # 摇杆最大位移（像素）
const STICK_GRAB_RADIUS := 165.0  # 按下点离中心多近算"抓到了摇杆"
const STICK_DEAD := 0.18          # 死区
const BTN_RADIUS := 54.0
const BTN_GAP := 10.0
const BTN_MARGIN := 70.0
const BTN_COUNT := 4
const UTIL_RADIUS := 54.0       # 右上功能按钮半径
const UTIL_Y := 100.0           # 距顶部
const UTIL_MARGIN := 84.0       # 距右侧
const UTIL_GAP := 16.0

var direction := Vector2.ZERO     # 归一化 + 死区处理后的移动输入（0~1）

var _enabled := false
var _touch_seen := false          # 见过触摸事件后就不再理会模拟鼠标事件（防重复处理）
var _stick_id := -1               # 正在拖摇杆的手指 id（鼠标用 -2）
var _btn_id := -1
var _base: Line2D
var _knob: Line2D
var _base_pos := Vector2.ZERO
var _buttons: Array = []          # [{index, center, base, icon}]
var _util: Array = []             # [{key, center, ring, label}]
var _player: Node
# 自动跑局机器人（开发用，见 HANDOVER §3）：MS_BOT=1 远离妖、捡法宝、放神通、能升就升，
# 用来采集生存数据回答"15 分钟到底能不能活到"。配合 --headless --fixed-fps 可把
# 15 分钟压缩成几分钟跑完（fixed-fps 让每帧 delta 固定，与真实耗时无关）。
var _bot := false
var _bot_wobble := 0.0
var _bot_ping_next := 30.0
var _bot_done := false


func _ready() -> void:
	layer = 20                    # HUD(10) 之上、弹窗(25/30) 之下
	_enabled = _should_enable()
	if not _enabled:
		queue_free()
		return
	add_to_group("touch_input")
	set_process_input(true)
	_bot = OS.get_environment("MS_BOT") == "1"
	if _bot:
		# 升级三选一 / 结算都会暂停游戏树；机器人必须照常运行才能自己应答弹窗
		process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


## 是否真的有触摸可用（或被人为强制开启）
func _should_enable() -> bool:
	if OS.get_environment("MS_TOUCH") == "1":
		return true
	for arg in OS.get_cmdline_args():
		if arg == "--touch":
			return true
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if OS.get_environment("MS_BOT") == "1":
		return true          # 机器人复用同一条输入注入路径（顺带也测了触屏方向）
	return DisplayServer.is_touchscreen_available()


func _build() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	_base_pos = Vector2(STICK_MARGIN, size.y - STICK_MARGIN)
	_make_glow(2.9, Color(0.4, 0.9, 1.0, 0.16), _base_pos)
	_base = _make_ring(STICK_RING_RADIUS, 8.0, Color(0.45, 0.95, 1.0, 0.5), _base_pos)
	_make_glow(1.1, Color(0.7, 0.98, 1.0, 0.30), _base_pos)
	_knob = _make_ring(STICK_KNOB_RADIUS, 9.0, Color(0.85, 0.99, 1.0, 0.8), _base_pos)
	for i in BTN_COUNT:
		var step: float = BTN_RADIUS * 2.0 + BTN_GAP
		var center := Vector2(
			size.x - BTN_MARGIN - BTN_RADIUS - float(BTN_COUNT - 1 - i) * step,
			size.y - BTN_MARGIN - BTN_RADIUS)
		var base := _make_ring(BTN_RADIUS - 6.0, 7.0, Color(0.45, 0.9, 1.0, 0.5), center)
		_make_glow(1.6, Color(0.35, 0.8, 0.95, 0.18), center)
		var icon := Sprite2D.new()
		icon.position = center
		icon.scale = Vector2.ONE * 0.62
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(icon)
		_buttons.append({"index": i, "center": center, "base": base, "icon": icon})
	# 右上功能按钮：手机上没有 F / B / Esc，必须给可点入口
	var util_defs := [
		{"key": "pickup", "text": "拾取"},
		{"key": "bag", "text": "乾坤袋"},
		{"key": "pause", "text": "暂停"},
	]
	for i in util_defs.size():
		var ucenter := Vector2(
			size.x - UTIL_MARGIN - UTIL_RADIUS - float(util_defs.size() - 1 - i) * (UTIL_RADIUS * 2.0 + UTIL_GAP),
			UTIL_Y)
		var ring := _make_ring(UTIL_RADIUS - 8.0, 6.0, Color(0.55, 0.85, 0.95, 0.34), ucenter)
		var lab := Label.new()
		lab.text = String(util_defs[i]["text"])
		lab.position = ucenter - Vector2(56, 15)
		lab.size = Vector2(112, 30)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 24)
		lab.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.9))
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lab.add_theme_constant_override("outline_size", 6)
		add_child(lab)
		_util.append({"key": String(util_defs[i]["key"]), "center": ucenter, "ring": ring, "label": lab})


func _make_glow(s: float, col: Color, pos: Vector2) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/fx/glow_64.png")
	spr.scale = Vector2.ONE * s
	spr.modulate = col
	spr.position = pos
	add_child(spr)
	return spr


## 描边圆环：比纯光晕清晰得多（深色地板上也一眼看得见）
func _make_ring(radius: float, width: float, col: Color, pos: Vector2) -> Line2D:
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in 49:
		var a: float = TAU * float(i) / 48.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	ring.points = pts
	ring.width = width
	ring.default_color = col
	ring.antialiased = false
	ring.position = pos
	add_child(ring)
	return ring


func _process(_delta: float) -> void:
	if _bot:
		_bot_step(_delta)
	if _knob != null:
		_knob.position = _base_pos + direction * STICK_MAX
	if _player == null:
		_player = get_node_or_null("/root/Game/Player")
		if _player == null:
			return
	# 调试/验证钩子（本机没有触摸屏时用）：MS_TOUCH_PROBE=1
	#   ① 摇杆每 90 帧在"右/左"之间交替（复现左右走路）
	#   ② 每 15 帧打印速度/动画/flip/精灵与相机的 rotation
	# 用途：验证"摇杆真的推得动角色"，以及判断"画面在转"到底是相机还是帧的问题
	#（2026-09-24 就是靠它排除相机旋转、定位到精灵表 col3 帧间朝向不一致）。
	# 见 HANDOVER §3「触屏与移动端验证」。
	if OS.get_environment("MS_TOUCH_PROBE") == "1":
		_player.health = _player.max_health
		var phase: int = int(Engine.get_process_frames() / 90) % 2
		direction = Vector2.RIGHT if phase == 0 else Vector2.LEFT
		if Engine.get_process_frames() % 15 == 0:
			var hero = _player.get_node_or_null("Hero")
			var cam = _player.get_node_or_null("Camera2D")
			var spr = hero._sprite if hero != null else null
			print("PROBE f=%d v=%s anim=%s flip=%s spr_rot=%.4f spr_scale=%s hero_rot=%.4f cam_rot=%.4f" % [
				Engine.get_process_frames(), str(_player.velocity),
				str(spr.animation) if spr != null else "-",
				str(spr.flip_h) if spr != null else "-",
				spr.rotation if spr != null else 0.0,
				str(spr.scale) if spr != null else "-",
				hero.rotation if hero != null else 0.0,
				cam.rotation if cam != null else 0.0])
	var slots: Array = _player.skill_slots
	for b in _buttons:
		var i: int = int(b["index"])
		var icon: Sprite2D = b["icon"]
		var base: Line2D = b["base"]
		var id: String = str(slots[i]) if i < slots.size() else ""
		if id == "":
			icon.texture = null
			icon.modulate = Color(1, 1, 1, 0.0)
			base.default_color = Color(0.5, 0.6, 0.7, 0.18)
			continue
		var def: Dictionary = Skills.get_def(id)
		var path: String = str(def.get("icon", ""))
		if icon.texture == null and path != "" and ResourceLoader.exists(path):
			icon.texture = load(path)
		var ready_to_cast: bool = _player.get_skill_cooldown(id) <= 0.0 \
			and _player.mana >= float(def.get("mana", 0.0))
		icon.modulate = Color(1, 1, 1, 1.0) if ready_to_cast else Color(0.5, 0.55, 0.68, 0.55)
		base.default_color = Color(0.5, 1.0, 1.0, 0.55) if ready_to_cast else Color(0.6, 0.62, 0.72, 0.2)
	# 右上功能按钮：拾取只在"脚下真有法宝"时亮起，免得玩家乱点
	for u in _util:
		var ring: Line2D = u["ring"]
		var lab: Label = u["label"]
		var on: bool = String(u["key"]) != "pickup" or _pickup_available()
		ring.default_color = Color(0.6, 1.0, 1.0, 0.55) if on else Color(0.5, 0.55, 0.65, 0.2)
		lab.modulate.a = 1.0 if on else 0.45


## 机器人一步：躲最近的妖、顺路捡法宝、放神通、材料够就升阶
func _bot_step(delta: float) -> void:
	if _player == null:
		_player = get_node_or_null("/root/Game/Player")
		if _player == null:
			return
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	# 弹窗应答：headless 下没人点按钮，机器人不自己选就会永远卡在暂停里
	var lvl = get_node_or_null("/root/Game/LevelUpUI")
	if lvl != null and lvl.visible:
		lvl._choose(randi() % 3)
		return
	var t: float = float(game.run_time)
	_bot_wobble += delta * 1.7
	var nearest := _nearest_mob()
	if nearest == null:
		direction = Vector2.ZERO
	else:
		var away: Vector2 = (_player.global_position - nearest.global_position).normalized()
		# 加一点左右摆动，避免被妖逼在直线上越跑越窄
		direction = away.rotated(sin(_bot_wobble) * 0.85)
		# 妖贴脸时优先脱身：反向拉满
		if _player.global_position.distance_to(nearest.global_position) < 90.0:
			direction = away
	# 脚下有法宝就过去捡（只在有空位时捡，否则会弹替换面板把局面搞乱）
	if _player.weapon_count() < Weapons.MAX_SLOTS:
		for drop in get_tree().get_nodes_in_group("weapon_drops"):
			if not is_instance_valid(drop):
				continue
			if _player.global_position.distance_to(drop.global_position) < 260.0:
				direction = _player.global_position.direction_to(drop.global_position)
				if drop.has_method("can_touch_pickup") and drop.can_touch_pickup():
					drop.touch_pickup()
				break
	# 神通：蓝够、不在冷却就放
	for i in _player.skill_slots.size():
		var id: String = str(_player.skill_slots[i])
		if id == "":
			continue
		var def: Dictionary = Skills.get_def(id)
		if _player.get_skill_cooldown(id) <= 0.0 and _player.mana >= float(def.get("mana", 0.0)):
			_player.cast_skill(i)
	# 能升就升（模拟玩家会做的事）
	for w in _player.weapons:
		var wid: String = str(w["id"])
		if _player.can_upgrade_weapon(wid):
			_player.upgrade_weapon(wid)
	# 汇报
	if not _bot_done and t >= _bot_ping_next:
		_bot_ping_next += 30.0
		print("BOTPING t=%.0fs lv=%d kills=%d hp=%.0f/%.0f mobs=%d fa=%s" % [
			t, _player.level, int(game.kill_count), _player.health, _player.max_health,
			get_tree().get_nodes_in_group("mobs").size(), _weapons_text()])
	if not _bot_done and (_player.health <= 0.0 or bool(game._run_ended)):
		_bot_finish("win" if bool(game._run_ended) and _player.health > 0.0 else "died", t)


func _bot_finish(result: String, t: float) -> void:
	if _bot_done:
		return
	_bot_done = true
	var game = get_node_or_null("/root/Game")
	print("BOTSTAT result=%s time=%.0fs level=%d kills=%d boss=%d coins=%d fa=%s" % [
		result, t, _player.level,
		int(game.kill_count) if game != null else 0,
		int(game.boss_kill_count) if game != null else 0,
		int(game.run_coins) if game != null else 0, _weapons_text()])
	get_tree().quit()


func _nearest_mob() -> Node2D:
	var best: Node2D = null
	var best_d := 1e20
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		var d: float = _player.global_position.distance_to(mob.global_position)
		if d < best_d:
			best_d = d
			best = mob
	return best


func _weapons_text() -> String:
	var s := ""
	for w in _player.weapons:
		s += "%s:%d " % [str(w["id"]), int(w["level"])]
	return s.strip_edges()


func _input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch:
		_touch_seen = true
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
		return
	if event is InputEventScreenDrag:
		_touch_seen = true
		_drag(event.index, event.position)
		return
	# 桌面调试用鼠标（触摸设备上 Godot 会把触摸模拟成鼠标，所以要跳过，免得处理两次）
	if _touch_seen:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-2, event.position)
		else:
			_release(-2)
	elif event is InputEventMouseMotion and _stick_id == -2:
		_drag(-2, event.position)


## 功能按钮的实际动作（直接调面板方法，不模拟按键）
func _do_util(key: String) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	match key:
		"pickup":
			for drop in get_tree().get_nodes_in_group("weapon_drops"):
				if drop.has_method("touch_pickup") and drop.touch_pickup():
					return
		"bag":
			var ui = game.get_node_or_null("InventoryUI")
			if ui != null and ui.has_method("toggle"):
				ui.toggle()
		"pause":
			var pu = game.get_node_or_null("PauseUI")
			if pu != null and pu.has_method("pause"):
				pu.pause()


## 拾取按钮只在"脚下真有法宝"时亮起
func _pickup_available() -> bool:
	for drop in get_tree().get_nodes_in_group("weapon_drops"):
		if drop.has_method("can_touch_pickup") and drop.can_touch_pickup():
			return true
	return false


func _press(id: int, pos: Vector2) -> void:
	# 右上功能按钮优先（体积小、位置固定，不会和摇杆抢）
	for u in _util:
		if pos.distance_to(u["center"]) <= UTIL_RADIUS:
			_do_util(String(u["key"]))
			return
	if _stick_id == -1 and pos.distance_to(_base_pos) <= STICK_GRAB_RADIUS:
		_stick_id = id
		_drag(id, pos)
		return
	if _btn_id != -1:
		return
	for b in _buttons:
		if pos.distance_to(b["center"]) <= BTN_RADIUS:
			_btn_id = id
			if _player != null:
				_player.cast_skill(int(b["index"]))
			return


func _drag(id: int, pos: Vector2) -> void:
	if id != _stick_id:
		return
	var v: Vector2 = pos - _base_pos
	if v.length() < STICK_MAX * STICK_DEAD:
		direction = Vector2.ZERO
		return
	direction = v.limit_length(STICK_MAX) / STICK_MAX


func _release(id: int) -> void:
	if id == _stick_id:
		_stick_id = -1
		direction = Vector2.ZERO
	if id == _btn_id:
		_btn_id = -1
