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


func _process(_delta: float) -> bool:
	_f += 1
	if _f < 5:
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

	# 抖动：写存档 + 实时改 VFX.shake_scale
	sliders[0].value = 0.5
	if absf(float(SaveGame.get_setting("shake", -1.0)) - 0.5) > 0.01:
		_fail("抖动设置没有写入存档")
	if absf(float(root_vfx().shake_scale) - 0.5) > 0.01:
		_fail("抖动强度没有实时生效（%.2f）" % root_vfx().shake_scale)

	# 音乐：写存档 + 实时生效
	sliders[1].value = 0.3
	if absf(float(SaveGame.get_setting("music", -1.0)) - 0.3) > 0.01:
		_fail("音乐音量没有写入存档")
	if absf(float(root_audio().music_volume) - 0.3) > 0.01:
		_fail("音乐音量没有实时生效")

	# 音效：写存档 + 实时生效
	sliders[2].value = 0.25
	if absf(float(root_audio().sfx_volume) - 0.25) > 0.01:
		_fail("音效音量没有实时生效")

	# 身份选择：点第 2 张卡（符修）应写入存档
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
