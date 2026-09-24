extends SceneTree

## 触屏操作（P2b）的回归测试：本机没有触摸屏，靠 MS_TOUCH=1 强制开启触屏层。
##
## 注意：headless 的 --script 模式下 **合成 InputEvent 投递不可靠**（实测 flush 后仍时有时无），
## 而且 CharacterBody2D 在这里也不会真的位移。所以这里直接驱动触屏层的方法
## （_press / _drag / _release 就是 _input 的分发目标），验证的是"触屏逻辑 + 与玩家的接线"；
## "角色真的被摇杆推着走"由 tools/qa/touch_probe 在真实运行里验证（见 LOOPS.md）。
##
## 用法：MS_TOUCH=1 --headless --script res://tools/qa/check_touch.gd，末行 TOUCH PASS / FAIL

var _f := 0
var _game: Node
var _player: Node
var _touch: Node
var _fails: Array = []
var _mana0 := 0.0
var _stage := 0


func _initialize() -> void:
	change_scene_to_file("res://survivors_game.tscn")


func _fail(msg: String) -> void:
	_fails.append(msg)


func _process(_delta: float) -> bool:
	_f += 1
	if _game == null:
		_game = root.get_node_or_null("Game")
		if _game == null:
			if _f > 120:
				print("TOUCH FAIL: 等不到 /root/Game")
				return true
			return false
		_setup()
		_stage = 1
		return false

	match _stage:
		1:
			if _f >= 4:
				_check_drag()
				_touch._release(0)
				_stage = 2
		2:
			if _f >= 8:
				_check_release()
				_check_button()
				_report()
				return true
	return false


func _setup() -> void:
	_player = _game.get_node_or_null("Player")
	if _player == null:
		_fail("找不到 Player")
		return
	var sel = _game.get_node_or_null("StartSelectUI")
	if sel != null and sel.has_method("_choose"):
		sel._choose("shuriken")
	_player.max_health = 1000000
	_player.health = 1000000
	_player.mana = _player.mana_max
	_player._skill_cd.clear()

	var nodes: Array = get_nodes_in_group("touch_input")
	if nodes.is_empty():
		_fail("MS_TOUCH=1 时触屏层没有创建")
		return
	_touch = nodes[0]
	if _player._touch_dir() != Vector2.ZERO:
		_fail("还没碰摇杆，方向就不是零")
	# 抓摇杆 -> 往右拖到底
	_touch._press(0, _touch._base_pos + Vector2(6, 0))
	_touch._drag(0, _touch._base_pos + Vector2(400, 0))
	_mana0 = _player.mana


func _check_drag() -> void:
	var d: Vector2 = _player._touch_dir()
	if d.x < 0.9 or absf(d.y) > 0.15:
		_fail("摇杆拖到最右后方向不对：%s" % str(d))
	# 半程应该是模拟量（不是只有 0/1）
	_touch._drag(0, _touch._base_pos + Vector2(48, 0))
	var half: Vector2 = _player._touch_dir()
	if half.x < 0.35 or half.x > 0.65:
		_fail("摇杆半程应该是模拟量，实际 %s" % str(half))
	# 死区内应该归零
	_touch._drag(0, _touch._base_pos + Vector2(6, 0))
	if _player._touch_dir() != Vector2.ZERO:
		_fail("死区内没有归零：%s" % str(_player._touch_dir()))
	# 拖回最右，方便下一步验证松手
	_touch._drag(0, _touch._base_pos + Vector2(400, 0))


func _check_release() -> void:
	if _player._touch_dir() != Vector2.ZERO:
		_fail("松手后方向没有归零：%s" % str(_player._touch_dir()))


func _check_button() -> void:
	var id: String = str(_player.skill_slots[0])
	if id == "":
		_fail("技能槽 1 是空的，没法测神通按钮")
		return
	_touch._press(1, _touch._buttons[0]["center"])
	if _player.mana >= _mana0:
		_fail("点神通按钮没有消耗灵力（%.1f -> %.1f）" % [_mana0, _player.mana])
	if _player.get_skill_cooldown(id) <= 0.0:
		_fail("点神通按钮没有进入冷却")
	var bar = _game.get_node_or_null("HUD/SkillBar")
	if bar == null:
		_fail("找不到 HUD/SkillBar")
	elif bar._slots[0]["key"].visible:
		_fail("触屏时按键提示（1/2/3/4）应该隐藏")


func _report() -> void:
	if _fails.is_empty():
		print("TOUCH PASS")
	else:
		for m in _fails:
			print("TOUCH FAIL: ", m)
		print("TOUCH FAIL")
