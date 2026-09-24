extends SceneTree

## 精确斩妖归属（P6）的回归测试：
##   1) take_damage 带 source → 只有那把法宝 +1 斩妖数
##   2) take_damage 不带 source（来源不明）→ 所有携带法宝各 +1（兜底，宁可多记不可漏记）
## 用法：--headless --script res://tools/qa/check_kill_credit.gd，输出末行 KILLCHECK PASS / FAIL

var _f := 0
var _game: Node
var _player: Node
var _ok := true


func _initialize() -> void:
	change_scene_to_file("res://survivors_game.tscn")


func _fail(msg: String) -> void:
	_ok = false
	print("KILLCHECK FAIL: ", msg)


func _process(_delta: float) -> bool:
	_f += 1
	if _game == null:
		_game = root.get_node_or_null("Game")
		if _game == null:
			if _f > 120:
				print("KILLCHECK FAIL: 等不到 /root/Game")
				return true
			return false
		_run()
		return true
	return false


func _run() -> void:
	_player = _game.get_node_or_null("Player")
	if _player == null:
		print("KILLCHECK FAIL: 找不到 Player")
		return
	var spawn_timer = _game.get_node_or_null("Timer")
	if spawn_timer != null and spawn_timer is Timer:
		spawn_timer.stop()          # 停掉刷怪，避免干扰计数
	_game._boss_timer = 9999.0
	var sel = _game.get_node_or_null("StartSelectUI")
	if sel != null and sel.has_method("_choose"):
		sel._choose("shuriken")     # 关掉开局选择界面并解除暂停
	_player.add_weapon("aura")

	var s0: int = int(_player.get_weapon("shuriken")["kills"])
	var a0: int = int(_player.get_weapon("aura")["kills"])
	_kill_one("aura")
	if int(_player.get_weapon("aura")["kills"]) != a0 + 1:
		_fail("带来源的斩妖没有记给 aura")
	if int(_player.get_weapon("shuriken")["kills"]) != s0:
		_fail("带来源的斩妖被错误地同时记给了 shuriken")

	s0 = int(_player.get_weapon("shuriken")["kills"])
	a0 = int(_player.get_weapon("aura")["kills"])
	_kill_one("")
	if int(_player.get_weapon("shuriken")["kills"]) != s0 + 1:
		_fail("来源不明时 shuriken 没有兜底 +1")
	if int(_player.get_weapon("aura")["kills"]) != a0 + 1:
		_fail("来源不明时 aura 没有兜底 +1")

	if _ok:
		print("KILLCHECK PASS")
	else:
		print("KILLCHECK FAIL")


func _kill_one(source: String) -> void:
	var mob = load("res://mob.tscn").instantiate()
	_game.add_child(mob)
	mob.setup(Balance.pick_variant(Balance.WAVES[0]))
	mob.died.connect(_game._on_mob_died)
	mob.take_damage(99999, Vector2.ZERO, source)
