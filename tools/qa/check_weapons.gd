extends SceneTree

## 全法宝冒烟（P6 新增第 5/6 把法宝后）：
##   1) 6 把法宝都能装上 / 卸下 / 升满进化，跑真实帧不报 SCRIPT ERROR
##   2) 被动真的在产出（回风梭掷出飞梭、地火符阵布下符雷）
##   3) 伤害链路与斩妖归属：直接调命中回调（--script 模式下物理不步进，不能靠 Area 重叠）
## 用法：--headless --script res://tools/qa/check_weapons.gd，末行 WEAPONS PASS / FAIL

const RUN_FRAMES := 420     # 实跑帧数（技能轮放、法宝轮换）
const WAIT_FRAMES := 6      # 延迟伤害结算的等待帧

var _f := 0
var _phase := 0
var _game: Node
var _player: Node
var _fails: Array = []
var _swaps: Array = [
	["orbit_blade", "aura"],          # 卸一把装一把：覆盖全部 6 把法宝
	["aura", "chain_lightning"],
	["mine", "mine"],                 # 重复拾取路径
]
var _swap_at: Array = [120, 240, 340]
var _before_kills := {}
var _max_shots := 0
var _max_mines := 0


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
				print("WEAPONS FAIL: 等不到 /root/Game")
				return true
			return false
		_setup()
		return false

	if _phase == 0:
		_sample_passives()
		if _f % 90 == 0:
			_cast_all()
		for i in _swap_at.size():
			if _f == _swap_at[i]:
				_swap(_swaps[i][0], _swaps[i][1])
		if _f >= RUN_FRAMES:
			_check_passives()
			_hit_test()
			_phase = 1
		return false

	if _phase == 1:
		if _f >= RUN_FRAMES + WAIT_FRAMES:
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
	# 无敌：这是冒烟测试，不该因为被打死而中断
	_player.max_health = 1000000
	_player.health = 1000000
	for id in ["boomerang", "mine", "orbit_blade"]:
		if not _player.add_weapon(id):
			_fail("装不上法宝 " + id)
	_max_all()
	_check_nodes()


## 全部法宝升满 + 进化（覆盖各法宝的 evolve 分支）
func _max_all() -> void:
	for w in _player.weapons:
		w["level"] = 5
		_player._apply_weapon_passive(str(w["id"]))
		_player._evolve_weapon(str(w["id"]))


func _check_nodes() -> void:
	var want := {
		"boomerang": ["Boomerang", "level"],
		"mine": ["Mine", "level"],
		"aura": ["Aura", "level"],
		"chain_lightning": ["ChainLightning", "level"],
		"orbit_blade": ["OrbitBlades", "blade_count"],
	}
	for id in _player.weapons:
		var wid: String = str(id["id"])
		if not want.has(wid):
			continue
		var spec: Array = want[wid]
		var node = _player.get_node_or_null(str(spec[0]))
		if node == null:
			_fail("场景里没有节点 " + str(spec[0]))
			continue
		if int(node.get(str(spec[1]))) != 5:
			_fail("%s 的被动等级没有同步到 5（实际 %s）" % [wid, str(node.get(str(spec[1])))])


func _cast_all() -> void:
	for i in _player.skill_slots.size():
		_player._skill_cd.clear()
		_player.mana = _player.mana_max
		_player.cast_skill(i)


func _swap(drop_id: String, add_id: String) -> void:
	_player.drop_weapon(drop_id)
	if not _player.add_weapon(add_id):
		_fail("轮换时装不上法宝 " + add_id)
	_max_all()


## 被动产出采样：回风梭掷出的飞梭数 / 地火符阵场上的符雷数
func _sample_passives() -> void:
	var boom = _player.get_node_or_null("Boomerang")
	var mine = _player.get_node_or_null("Mine")
	if boom != null:
		_max_shots = maxi(_max_shots, boom._shots.size())
	if mine != null:
		_max_mines = maxi(_max_mines, mine._mines.size())


## 被动产出：回风梭掷过飞梭、地火符阵布过符雷
func _check_passives() -> void:
	var boom = _player.get_node_or_null("Boomerang")
	var mine = _player.get_node_or_null("Mine")
	if boom == null or mine == null:
		_fail("缺 Boomerang / Mine 节点")
		return
	if not _player.has_weapon("boomerang"):
		_fail("回风梭中途丢了")
	if not _player.has_weapon("mine"):
		_fail("地火符阵中途丢了")
	if _max_shots < 1:
		_fail("回风梭全程没有掷出飞梭（被动没跑起来？）")
	if _max_mines < 1:
		_fail("地火符阵全程没有布下符雷（被动没跑起来？）")


## 伤害链路 + 斩妖归属：直接驱动命中回调，绕开"物理不步进"
func _hit_test() -> void:
	var boom = _player.get_node_or_null("Boomerang")
	var mine = _player.get_node_or_null("Mine")
	if boom == null or mine == null:
		return
	var mob := _spawn_dummy(500)
	if mob == null:
		_fail("造不出测试怪")
		return

	# 回风梭：命中扣血；同一枚飞梭对同一只怪只结算一次
	boom._add_shot(Vector2.RIGHT)
	var shot: Dictionary = boom._shots[boom._shots.size() - 1]
	var hp0: int = mob.health
	boom._on_shot_body_entered(mob, shot)
	boom._on_shot_body_entered(mob, shot)
	# 符雷：爆炸扣血
	mine._place(mob.global_position, 0.0)
	var rec: Dictionary = mine._mines[mine._mines.size() - 1]
	rec["arm"] = 0.0
	mine._detonate(rec)

	# 斩妖归属：1 血怪被回风梭打死，只该记给回风梭
	var kill_mob := _spawn_dummy(1)
	kill_mob.died.connect(_game._on_mob_died)
	_before_kills = {
		"boomerang": int(_player.get_weapon("boomerang")["kills"]),
		"mine": int(_player.get_weapon("mine")["kills"]),
	}
	boom._add_shot(Vector2.RIGHT)
	var shot2: Dictionary = boom._shots[boom._shots.size() - 1]
	boom._on_shot_body_entered(kill_mob, shot2)

	# 延迟伤害：等几帧再看结果
	_pending = {"mob": mob, "hp0": hp0}


var _pending := {}


func _spawn_dummy(hp: int) -> Node:
	var mob = load("res://mob.tscn").instantiate()
	_game.add_child(mob)
	mob.setup(Balance.pick_variant(Balance.WAVES[0]))
	mob.health = hp
	mob.can_drop_loot = false
	return mob


func _report() -> void:
	var mob = _pending.get("mob")
	if mob != null and is_instance_valid(mob):
		if mob.health >= int(_pending["hp0"]):
			_fail("回风梭/符雷的伤害没有结算到测试怪身上")
	# 归属：1 血怪死后只该给回风梭记 1 点
	var boom_kills: int = int(_player.get_weapon("boomerang")["kills"])
	var mine_kills: int = int(_player.get_weapon("mine")["kills"])
	if boom_kills <= int(_before_kills.get("boomerang", 0)):
		_fail("回风梭的致命一击没有记到回风梭头上")
	if mine_kills != int(_before_kills.get("mine", 0)):
		_fail("回风梭的致命一击被错误地记到了地火符阵头上")
	print("WEAPONS INFO: 游戏内时长=%.1fs 飞梭峰值=%d 符雷峰值=%d 斩妖=%d" % [
		_game.run_time, _max_shots, _max_mines, _game.kill_count])

	if _fails.is_empty():
		print("WEAPONS PASS")
	else:
		for m in _fails:
			print("WEAPONS FAIL: ", m)
		print("WEAPONS FAIL")
