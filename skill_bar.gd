extends Control

## 技能槽 HUD（P6）：4 个槽位（键位 1/2/3/4），代码构建，避免往场景里塞一堆节点。
## 每个槽显示：技能图标 / 冷却遮罩（从上往下扫）/ 按键提示 / 蓝不够时变暗。
## 图标缺失时用代码画的占位（色块 + 键位数字），等美术出图后自动替换。

const SLOT_COUNT := 4
const SLOT_SIZE := 84.0
const SLOT_GAP := 14.0
const KEY_LABELS := ["1", "2", "3", "4"]

var _slots: Array = []          # 每项：{"panel":Panel, "icon":TextureRect, "cd":ColorRect, "key":Label, "name":Label}
var _was_cooling := {}          # 技能 id -> 上一帧是否在冷却（用来捕捉"冷却刚结束"）
var _player: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var total := SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
	var start_x := -total / 2.0
	for i in SLOT_COUNT:
		_slots.append(_make_slot(i, start_x + i * (SLOT_SIZE + SLOT_GAP)))
	_player = get_node_or_null("/root/Game/Player")


func _make_slot(i: int, x: float) -> Dictionary:
	var panel := Panel.new()
	panel.position = Vector2(x, 0)
	panel.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.12, 0.78)
	sb.border_color = Color(0.35, 0.75, 0.85, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var icon := TextureRect.new()
	icon.position = Vector2(8, 8)
	icon.size = Vector2(SLOT_SIZE - 16, SLOT_SIZE - 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(icon)

	# 冷却遮罩：从上往下退，直观表示还剩多久
	var cd := ColorRect.new()
	cd.color = Color(0, 0, 0, 0.62)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.position = Vector2(2, 2)
	cd.size = Vector2(SLOT_SIZE - 4, 0)
	panel.add_child(cd)

	var key := Label.new()
	key.text = KEY_LABELS[i]
	key.position = Vector2(6, 2)
	key.add_theme_font_size_override("font_size", 22)
	key.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	key.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	key.add_theme_constant_override("outline_size", 6)
	panel.add_child(key)

	var nm := Label.new()
	nm.position = Vector2(-8, SLOT_SIZE + 2)
	nm.size = Vector2(SLOT_SIZE + 16, 26)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	nm.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	nm.add_theme_constant_override("outline_size", 6)
	panel.add_child(nm)

	return {"panel": panel, "icon": icon, "cd": cd, "key": key, "name": nm}


func _process(_delta: float) -> void:
	if _player == null:
		return
	var slots: Array = _player.skill_slots
	for i in SLOT_COUNT:
		var s: Dictionary = _slots[i]
		var id: String = slots[i] if i < slots.size() else ""
		if id == "":
			s["icon"].texture = null
			s["name"].text = "—"
			s["cd"].size.y = 0
			s["panel"].modulate = Color(1, 1, 1, 0.45)
			continue
		var def: Dictionary = Skills.get_def(id)
		if def.is_empty():
			continue
		var icon_path: String = def.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			if s["icon"].texture == null:
				s["icon"].texture = load(icon_path)
		else:
			s["icon"].texture = null
		s["name"].text = def.get("name", "")
		# 冷却遮罩高度 = 剩余比例
		var left: float = _player.get_skill_cooldown(id)
		var cd_total: float = float(def.get("cd", 1.0))
		var ratio: float = clampf(left / cd_total, 0.0, 1.0)
		s["cd"].size.y = (SLOT_SIZE - 4) * ratio
		# 冷却刚结束：技能栏闪一下，提示"可以再放了"
		if _was_cooling.get(id, false) and left <= 0.0:
			Juice.pop(s["panel"], 1.22, 0.22)
			VFX.shockwave(_player.global_position, 90.0, VFX.C_CYAN, 0.25, 4.0)
		_was_cooling[id] = left > 0.0
		# 蓝不够时整体变暗
		var enough: bool = _player.mana >= float(def.get("mana", 0.0))
		s["panel"].modulate = Color(1, 1, 1, 1.0) if enough else Color(0.55, 0.6, 0.75, 0.85)
