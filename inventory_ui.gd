extends CanvasLayer

## 乾坤袋（P6）：按 B 开关，暂停游戏。纯代码构建面板，避免往场景塞几十个节点。
##
## 布局：
##   左  = 法宝 4 格（点击选中）
##   中  = 选中法宝的技能列表（点击设为"本场激活技能"，需消耗神通残卷）
##         + 升级信息与 [升级] 按钮
##   右  = 当前技能配装 1/2/3/4 + 材料 + 灵力
##
## 图标缺失时用文字占位，等美术出图自动替换。

const W := 1360.0
const H := 700.0
const SLOT := 120.0

var _player: Node
var _selected := ""      # 当前选中的法宝 id
var _root: Control
var _weapon_boxes: Array = []
var _skill_rows: Array = []
var _upgrade_btn: Button
var _upgrade_info: Label
var _mat_label: Label
var _slot_label: Label
var _mana_label: Label


func _ready() -> void:
	layer = 25   # HUD(10) 之上、弹窗(30) 之下
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	_player = get_node_or_null("/root/Game/Player")


func _unhandled_input(event: InputEvent) -> void:
	# Esc 关闭（开着的时候；否则交给暂停菜单）
	if event.is_action_pressed("ui_cancel"):
		if visible:
			toggle()
		return
	if not event.is_action_pressed("inventory"):
		return
	# 升级/结算界面开着时不响应，避免状态叠加
	var lv: Node = get_node_or_null("/root/Game/LevelUpUI")
	var go: Node = get_node_or_null("/root/Game/GameOver")
	var vi: Node = get_node_or_null("/root/Game/VictoryUI")
	if lv != null and lv.visible:
		return
	if go != null and go.visible:
		return
	if vi != null and vi.visible:
		return
	toggle()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_refresh()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var panel := Panel.new()
	panel.size = Vector2(W, H)
	panel.position = Vector2((1920 - W) / 2.0, (1080 - H) / 2.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.11, 0.96)
	sb.border_color = Color(0.35, 0.8, 0.9, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	_title(panel, "乾 坤 袋", Vector2(28, 14))
	# 触屏没有 Esc：必须有可点的关闭按钮（否则手机上打开乾坤袋就卡死在暂停里）
	_hint(panel, "B / Esc 也可关闭", Vector2(W - 350, 34))
	_button(panel, "关闭", Vector2(W - 132, 18), Vector2(108, 48), toggle)

	# ---- 左：法宝 4 格 ----
	_label(panel, "法宝", Vector2(28, 70), 30)
	for i in Weapons.MAX_SLOTS:
		_weapon_boxes.append(_make_weapon_box(panel, i, Vector2(28 + i * (SLOT + 12), 112)))

	# ---- 中：选中法宝的技能 + 升级 ----
	_label(panel, "神通（每夜 1 门 · 改换耗残卷）", Vector2(560, 70), 26)
	for i in 4:
		_skill_rows.append(_make_skill_row(panel, i, Vector2(560, 112 + i * 52)))
	_upgrade_info = _label(panel, "", Vector2(560, 360), 24)
	_upgrade_btn = _button(panel, "升阶", Vector2(560, 410), Vector2(180, 54), _on_upgrade)

	# ---- 右：配装 / 材料 / 灵力 ----
	_label(panel, "本命神通", Vector2(960, 70), 30)
	_slot_label = _label(panel, "", Vector2(960, 112), 26)
	_label(panel, "炼材", Vector2(960, 430), 30)
	_mat_label = _label(panel, "", Vector2(960, 474), 24)
	_mana_label = _label(panel, "", Vector2(960, 610), 26)


func _title(p: Control, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	p.add_child(l)


func _label(p: Control, text: String, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	p.add_child(l)
	return l


func _hint(p: Control, text: String, pos: Vector2) -> void:
	var l := _label(p, text, pos, 22)
	l.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))


func _button(p: Control, text: String, pos: Vector2, size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.pressed.connect(cb)
	p.add_child(b)
	return b


func _make_weapon_box(p: Control, i: int, pos: Vector2) -> Dictionary:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(SLOT, SLOT + 34)
	b.pressed.connect(_on_weapon_clicked.bind(i))
	p.add_child(b)
	var icon := TextureRect.new()
	icon.position = Vector2(10, 6)
	icon.size = Vector2(SLOT - 20, SLOT - 20)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.add_child(icon)
	var nm := Label.new()
	nm.position = Vector2(0, SLOT - 12)
	nm.size = Vector2(SLOT, 44)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 18)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	return {"btn": b, "icon": icon, "name": nm}


func _make_skill_row(p: Control, i: int, pos: Vector2) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(360, 44)
	b.pressed.connect(_on_skill_clicked.bind(i))
	p.add_child(b)
	return b


func _refresh() -> void:
	if _player == null:
		return
	# 法宝格
	for i in _weapon_boxes.size():
		var box: Dictionary = _weapon_boxes[i]
		if i < _player.weapons.size():
			var w: Dictionary = _player.weapons[i]
			var def: Dictionary = Weapons.get_def(w["id"])
			var icon_path: String = def.get("icon", "")
			box["icon"].texture = load(icon_path) if (icon_path != "" and ResourceLoader.exists(icon_path)) else null
			box["name"].text = "%s %d 阶" % [def.get("name", w["id"]), w["level"]]
			box["btn"].modulate = Color(1, 1, 1, 1)
			if _selected == "":
				_selected = w["id"]
		else:
			box["icon"].texture = null
			box["name"].text = "空"
			box["btn"].modulate = Color(1, 1, 1, 0.4)
	# 选中法宝的技能
	var w2: Dictionary = _player.get_weapon(_selected)
	var def2: Dictionary = Weapons.get_def(_selected)
	# 可换范围 = 自带技能 + 已满足条件的融合神通（与 player.set_active_skill 同一份判定）
	var skills: Array = Skills.available_for(_player, _selected)
	for i in _skill_rows.size():
		var row: Button = _skill_rows[i]
		if i < skills.size():
			var sid: String = skills[i]
			var sdef: Dictionary = Skills.get_def(sid)
			var mark := "●" if w2.get("active_skill", "") == sid else "○"
			var tag := "〔融合〕" if Skills.is_fusion(sid) else ""
			var need := "" if mark == "●" else "  （改换需神通残卷 x1，现有 %d）" % _player.skill_books
			row.text = "%s %s%s%s" % [mark, tag, sdef.get("name", sid), need]
			row.disabled = false
		else:
			row.text = "—"
			row.disabled = true
	# 升级信息
	if w2.is_empty():
		_upgrade_info.text = "未选中法宝"
		_upgrade_btn.disabled = true
	else:
		var mat: String = def2.get("upgrade_material", "scrap")
		var cost := Weapons.upgrade_cost(def2, int(w2["level"]))
		var need_kills := int(def2.get("kills_per_level", 100)) * int(w2["level"])
		var maxed: bool = int(w2["level"]) >= int(def2.get("max_level", 5))
		if maxed:
			_upgrade_info.text = "已至五阶"
		else:
			_upgrade_info.text = "升阶需：%s x%d（现有 %d）  剑饮妖血 %d/%d" % [
				Weapons.material_name(mat), cost, _player.material_count(mat),
				int(w2["kills"]), need_kills,
			]
		_upgrade_btn.disabled = not _player.can_upgrade_weapon(_selected)
	# 配装
	var lines := []
	for i in _player.skill_slots.size():
		var sid2: String = _player.skill_slots[i]
		var nm2: String = Skills.get_def(sid2).get("name", "—") if sid2 != "" else "—"
		lines.append("  [%d]  %s" % [i + 1, nm2])
	_slot_label.text = "\n".join(lines)
	# 材料
	var mlines := []
	for mid in Weapons.MATERIALS.keys():
		mlines.append("  %s x%d" % [Weapons.material_name(mid), _player.material_count(mid)])
	mlines.append("  神通残卷 x%d" % _player.skill_books)
	_mat_label.text = "\n".join(mlines)
	_mana_label.text = "灵力  %d / %d" % [int(_player.mana), int(_player.mana_max)]


func _on_weapon_clicked(i: int) -> void:
	if _player == null or i >= _player.weapons.size():
		return
	_selected = _player.weapons[i]["id"]
	_refresh()


func _on_skill_clicked(i: int) -> void:
	if _player == null or _selected == "":
		return
	var skills: Array = Skills.available_for(_player, _selected)
	if i >= skills.size():
		return
	var w: Dictionary = _player.get_weapon(_selected)
	var is_current: bool = w.get("active_skill", "") == skills[i]
	# 首次选择不消耗；切换消耗一本神通残卷
	var ok: bool = _player.set_active_skill(_selected, skills[i], not is_current)
	if not ok:
		Audio.play("res://sounds/hurt.wav", false, 0.8, 0.2)
	_refresh()


## ---------- 替换面板（法宝位满时，从掉落物调用） ----------

var _pending_id := ""
var _pending_drop: Node = null
var _replace_root: Control


## 弹替换面板：列出当前 4 把法宝 + 放弃选项
func ask_replace(new_id: String, drop_node: Node) -> void:
	_pending_id = new_id
	_pending_drop = drop_node
	_close_replace()
	_replace_root = Control.new()
	_replace_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_replace_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_replace_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replace_root.add_child(dim)

	var panel := Panel.new()
	panel.size = Vector2(620, 520)
	panel.position = Vector2((1920 - 620) / 2.0, (1080 - 520) / 2.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.12, 0.98)
	sb.border_color = Color(0.4, 0.85, 0.95, 0.9)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	_replace_root.add_child(panel)

	var new_def: Dictionary = Weapons.get_def(new_id)
	var t := _label(panel, "法宝已满，要替换吗？", Vector2(28, 18), 34)
	t.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_label(panel, "新：%s" % new_def.get("name", new_id), Vector2(28, 70), 26)

	var y := 118.0
	for i in _player.weapons.size():
		var w: Dictionary = _player.weapons[i]
		var def: Dictionary = Weapons.get_def(w["id"])
		var b := _button(panel, "替换 → %s %d 阶" % [def.get("name", w["id"]), w["level"]], Vector2(28, y), Vector2(400, 52), _on_replace_pick.bind(i))
		b.add_theme_font_size_override("font_size", 24)
		y += 62.0
	var give := _button(panel, "放弃（留在地上）", Vector2(28, y + 10), Vector2(400, 52), _on_replace_cancel)
	give.add_theme_font_size_override("font_size", 24)

	# 替换面板也暂停游戏
	get_tree().paused = true
	visible = true


func _close_replace() -> void:
	if _replace_root != null and is_instance_valid(_replace_root):
		_replace_root.queue_free()
	_replace_root = null
	_pending_id = ""
	_pending_drop = null
	# ⚠️ ask_replace 开过暂停，这里必须解除——否则玩家点完「替换/放弃」
	# 游戏就永远停在暂停里（法宝位满 + 第 5 把才可达，2026-09-24 机器人跑局才发现）
	get_tree().paused = false
	visible = false
	_pending_id = ""
	_pending_drop = null
	# ⚠️ ask_replace 开过暂停，这里必须解除——否则玩家点完「替换/放弃」
	# 游戏就永远停在暂停里（法宝位满 + 第 5 把才可达，2026-09-24 机器人跑局才发现）
	get_tree().paused = false
	visible = false


func _on_replace_pick(index: int) -> void:
	if _player == null or index >= _player.weapons.size():
		return
	var old_id: String = _player.weapons[index]["id"]
	_player.drop_weapon(old_id)
	var ok: bool = _player.add_weapon(_pending_id)
	Audio.play("res://sounds/pickup.wav", false, 1.4, 0.4)
	if ok and _pending_drop != null and is_instance_valid(_pending_drop):
		# 把换下来的法宝掉在原地，形成循环
		var back: Node = load("res://weapon_drop.tscn").instantiate()
		get_node("/root/Game").add_child(back)
		back.global_position = _pending_drop.global_position + Vector2(70, 0)
		back.setup(old_id)
		_pending_drop.queue_free()
	_close_replace()
	_pending_drop = null
	_refresh()


func _on_replace_cancel() -> void:
	_close_replace()
	if _pending_drop != null and is_instance_valid(_pending_drop) and _pending_drop.has_method("cancel_replace"):
		_pending_drop.cancel_replace()
	_pending_drop = null


func _on_upgrade() -> void:
	if _player == null or _selected == "":
		return
	_player.upgrade_weapon(_selected)
	_refresh()
