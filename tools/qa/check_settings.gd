extends SceneTree

## 设置菜单（P7）+ 身份选择器 的结构/持久化回归：
##   1) 主菜单里有 SettingsUI 层，含 3 个滑杆（抖动/音乐/音效）
##   2) 拖动滑杆会写入存档并实时生效（Audio.music_volume / VFX.shake_scale）
##   3) 身份选择器有 3 张卡，点击会写入存档
## 结束时还原测试前的设置值。
## 用法：--headless --script res://tools/qa/check_settings.gd，末行 SETTINGS PASS / FAIL
## ⚠️ --script 模式下编译期看不到自动加载名（Audio/VFX），所以测试里用节点路径取。

var _f := 0
var _menu: Node
var _fails: Array = []
var _orig := {}


func _initialize() -> void:
	for k in ["shake", "music", "sfx"]:
		_orig[k] = SaveGame.get_setting(k, null)
	_orig["character"] = SaveGame.get_character()
	change_scene_to_file("res://main_menu.tscn")


func _fail(m: String) -> void:
	_fails.append(m)


func root_audio() -> Node:
	return root.get_node("Audio")


func root_vfx() -> Node:
	return root.get_node("VFX")


func _find_sliders(node: Node, out: Array) -> void:
	for c in node.get_children():
		if c is HSlider:
			out.append(c)
		_find_sliders(c, out)


## 真实鼠标点击（走输入管线）——用于验证没有控件吞掉点击。
## 注意：parse_input_event 要到下一帧才被派发，所以点击和断言必须分帧做。
var _clicked_id := ""


func _click_card(index: int) -> void:
	var card: Button = _menu._char_cards[index]["card"]
	var center: Vector2 = card.global_position + card.size / 2.0
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = center
		ev.global_position = center
		Input.parse_input_event(ev)


func _process(_delta: float) -> bool:
	_f += 1
	if _f == 4:
		# 先真实点一张"当前没选中"的卡（用户反馈"人物无法切换"的回归）
		var menu0 = root.get_node_or_null("MainMenu")
		if menu0 != null:
			var cur: String = SaveGame.get_character()
			var idx := 0
			for i in menu0._char_cards.size():
				if str(menu0._char_cards[i]["id"]) != cur:
					idx = i
					break
			_clicked_id = str(menu0._char_cards[idx]["id"])
			_menu = menu0
			_click_card(idx)
	if _f < 8:
		return false
	_menu = root.get_node_or_null("MainMenu")
	if _menu == null:
		print("SETTINGS FAIL: 找不到主菜单")
		return true

	var layer = _menu.get_node_or_null("SettingsUI")
	if layer == null:
		print("SETTINGS FAIL: 主菜单里找不到 SettingsUI 层")
		return true
	var sliders: Array = []
	_find_sliders(layer, sliders)
	if sliders.size() != 3:
		print("SETTINGS FAIL: 滑杆数量 %d != 3" % sliders.size())
		return true
	if _menu._char_cards.size() != 3:
		print("SETTINGS FAIL: 身份选择卡数量 %d != 3" % _menu._char_cards.size())
	# 选卡头像（从用户交付的方向表抽出的正面格）
	for c in _menu._char_cards:
		var has_pic := false
		for ch in (c["card"] as Button).get_children():
			if ch is TextureRect and (ch as TextureRect).texture != null:
				has_pic = true
		if not has_pic:
			_fail("身份卡 %s 没有头像" % str(c["id"]))

	# 卡片排版（2026-09-24 用户截图反馈"界面糅杂"）：元素不得重叠、不得超出卡片
	for c in _menu._char_cards:
		var card: Button = c["card"]
		var nm: Label = c["nm"]
		var ds: Label = c["ds"]
		var card_rect := Rect2(Vector2.ZERO, card.size)
		var r_nm := Rect2(nm.position, nm.size)
		var r_ds := Rect2(ds.position, ds.size)
		if not card_rect.encloses(r_nm):
			_fail("身份卡 %s 的名字超出卡片 %s" % [str(c["id"]), str(r_nm)])
		if not card_rect.encloses(r_ds):
			_fail("身份卡 %s 的描述超出卡片 %s" % [str(c["id"]), str(r_ds)])
		if r_nm.intersects(r_ds):
			_fail("身份卡 %s 的名字与描述重叠" % str(c["id"]))
		if r_ds.position.y < card.size.y * 0.4:
			_fail("身份卡 %s 的描述位置过高（y=%.0f）" % [str(c["id"]), r_ds.position.y])
		for ch in card.get_children():
			if ch is TextureRect and (ch as TextureRect).texture != null:
				var r_pic := Rect2((ch as TextureRect).position, (ch as TextureRect).size)
				if r_pic.intersects(r_ds):
					_fail("身份卡 %s 的描述压在头像上 %s" % [str(c["id"]), str(r_ds)])
				if r_pic.intersects(r_nm):
					_fail("身份卡 %s 的名字压在头像上 %s" % [str(c["id"]), str(r_nm)])
	if _menu._char_caption == null:
		_fail("找不到身份选择标题")
	else:
		var cap_bottom: float = _menu._char_caption.position.y + _menu._char_caption.size.y
		var first_card: Button = _menu._char_cards[0]["card"]
		if cap_bottom > first_card.position.y:
			_fail("「选择身份」标题压住卡片（标题底 %.0f > 卡片顶 %.0f）" % [
				cap_bottom, first_card.position.y])
		var rec: Label = _menu.get_node_or_null("%RecordsLabel")
		if rec != null:
			var rec_bottom: float = rec.position.y + rec.size.y
			if rec_bottom > _menu._char_caption.position.y:
				_fail("「最高纪录」压住「选择身份」（纪录底 %.0f > 标题顶 %.0f）" % [
					rec_bottom, _menu._char_caption.position.y])

	# 老存档迁移：早期版本把抖动/音量存成整数百分比（50 = 50%），读出来必须换算成 0~1
	var legacy := SaveGame.load_records()
	legacy["settings"] = {"shake": 50, "music": 30, "sfx": 25}
	SaveGame._write(legacy)
	var migrated: Dictionary = SaveGame.load_records()["settings"]
	if absf(float(migrated.get("shake", -1.0)) - 0.5) > 0.01:
		_fail("老存档迁移失败：shake = %s（应为 0.5）" % str(migrated.get("shake")))
	if absf(float(migrated.get("music", -1.0)) - 0.3) > 0.01:
		_fail("老存档迁移失败：music = %s（应为 0.3）" % str(migrated.get("music")))

	# 抖动：写存档 + 实时改 VFX.shake_scale
	# ⚠️ 赋一个与当前值相同的值不会触发 value_changed——所以先确保目标值与现值不同
	var shake_target := 0.7 if absf(sliders[0].value - 0.7) > 0.01 else 0.4
	sliders[0].value = shake_target
	if absf(float(SaveGame.get_setting("shake", -1.0)) - shake_target) > 0.01:
		_fail("抖动设置没有写入存档")
	if absf(float(root_vfx().shake_scale) - shake_target) > 0.01:
		_fail("抖动强度没有实时生效（%.2f）" % root_vfx().shake_scale)

	# 音乐：写存档 + 实时生效
	var music_target := 0.35 if absf(sliders[1].value - 0.35) > 0.01 else 0.6
	sliders[1].value = music_target
	if absf(float(SaveGame.get_setting("music", -1.0)) - music_target) > 0.01:
		_fail("音乐音量没有写入存档")
	if absf(float(root_audio().music_volume) - music_target) > 0.01:
		_fail("音乐音量没有实时生效")

	# 音效：写存档 + 实时生效
	sliders[2].value = 0.25
	if absf(float(root_audio().sfx_volume) - 0.25) > 0.01:
		_fail("音效音量没有实时生效")

	# 真实鼠标点击是否切换了角色（分帧：点击在第 4 帧派发，这里已是第 8 帧）
	# ⚠️ headless 模式**不派发**模拟鼠标事件（Input.parse_input_event 被丢弃），
	#    所以这条断言只能在带窗口跑时生效；判据是 headless 跑的，这里会自动跳过。
	if _clicked_id != "" and not DisplayServer.get_name() == "headless":
		if SaveGame.get_character() != _clicked_id:
			_fail("真实点击身份卡没有切换（点的是 %s，存档是 %s）" % [
				_clicked_id, SaveGame.get_character()])

	# 身份选择：直接调用处理函数也应写入存档
	_menu._on_character_clicked("fu_xiu")
	if SaveGame.get_character() != "fu_xiu":
		_fail("点击身份卡没有写入存档")

	# 还原测试前的设置
	for k in _orig.keys():
		if _orig[k] != null:
			SaveGame.set_setting(k, _orig[k])
	SaveGame.set_character(_orig["character"])

	if _fails.is_empty():
		print("SETTINGS PASS")
	else:
		for m in _fails:
			print("SETTINGS FAIL: ", m)
		print("SETTINGS FAIL")
	return true
