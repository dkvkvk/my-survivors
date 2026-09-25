extends SceneTree

## 全神通施放回归（P7：每把法宝 2 个神通 + 2 个融合神通）
##   1) 法宝表里每个"可换神通"都能设为激活并施放，不报错
##   2) 新神通要真的产生对应状态（疾奔计时 / 外放剑刃 / 火域 / 蓄雷 / 穿透梭 / 引爆）
##   3) 融合神通只在"两把法宝都在场"时可选，否则 set_active_skill 必须拒绝
## 用法：--headless --script res://tools/qa/check_skills.gd，末行 SKILLS PASS / FAIL

const PASS_A := ["shuriken", "orbit_blade", "aura", "chain_lightning"]
const PASS_B := ["shuriken", "boomerang", "mine", "chain_lightning"]

var _f := 0
var _game: Node
var _player: Node
var _fails: Array = []
var _stage := 0
var _casted := 0


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
				print("SKILLS FAIL: 等不到 /root/Game")
				return true
			return false
		_player = _game.get_node_or_null("Player")
		var sel = _game.get_node_or_null("StartSelectUI")
		if sel != null and sel.has_method("_choose"):
			sel._choose("shuriken")
		_player.max_health = 1000000.0
		_player.health = 1000000.0
		_stage = 1
		return false
	match _stage:
		1:
			_run_pass(PASS_A)
			_stage = 2
		2:
			_run_pass(PASS_B)
			_check_fusion_gating()
			_report()
			return true
	return false


func _run_pass(ids: Array) -> void:
	for w in _player.weapons.duplicate():
		_player.drop_weapon(str(w["id"]))
	for id in ids:
		if not _player.add_weapon(id):
			_fail("装不上法宝 " + id)
	for id in ids:
		for sid in Skills.available_for(_player, id):
			_cast_one(id, String(sid))


## 把某件法宝的激活技能设为 sid，然后施放，返回是否真的放了
func _cast_one(weapon_id: String, sid: String) -> void:
	if not _player.set_active_skill(weapon_id, sid, false):
		_fail("%s 无法激活自带神通 %s" % [weapon_id, sid])
		return
	var slot: int = _player.skill_slot_of(sid)
	if slot < 0:
		_fail("%s 激活后找不到技能槽" % sid)
		return
	_player.mana = _player.mana_max
	_player._skill_cd.clear()
	var mana0: float = _player.mana
	_player.cast_skill(slot)
	if _player.mana >= mana0:
		_fail("神通 %s 施放没有消耗灵力" % sid)
		return
	_casted += 1
	# 新神通的状态断言
	match sid:
		"dash_blade":
			if _player._dash_timer <= 0.0:
				_fail("御剑疾影没有进入疾奔状态")
		"ring_release":
			if _player.get_node("OrbitBlades")._flying.is_empty():
				_fail("剑环外放没有飞出剑刃")
		"fire_field":
			if get_nodes_in_group("fire_fields").is_empty():
				_fail("焚地火域没有生成火域")
		"charge_storm":
			if not _player.get_node("ChainLightning").is_overcharged():
				_fail("蓄雷引弧没有进入蓄雷状态")
		"pierce_shuttle":
			if not _has_pierce_shot():
				_fail("穿云巨梭没有掷出穿透飞梭")
		"detonate_all":
			if _player.get_node("Mine")._mines.is_empty():
				_fail("符阵合围既没引爆也没补布符雷")
		"inferno_ring":
			if _player.get_node("OrbitBlades")._flying.is_empty():
				_fail("焚天剑轮没有外放剑刃")


func _has_pierce_shot() -> bool:
	for rec in _player.get_node("Boomerang")._shots:
		if bool(rec.get("pierce", false)):
			return true
	return false


## 融合神通的门槛：缺任一法宝就不该可选、也不该能激活
func _check_fusion_gating() -> void:
	# 此刻持有 shuriken/boomerang/mine/chain_lightning：焚天剑轮需要 orbit_blade + aura
	if "inferno_ring" in Skills.available_for(_player, "orbit_blade"):
		_fail("没带离火法环/周天剑环，焚天剑轮却可选")
	if _player.set_active_skill("orbit_blade", "inferno_ring", false):
		_fail("未满足条件的融合神通竟然激活成功")
	# 惊雷剑引需要 shuriken + chain_lightning，此刻两把都在场
	var avail: Array = Skills.available_for(_player, "shuriken")
	if not ("storm_volley" in avail):
		_fail("两把法宝都在场，惊雷剑引却不可选（available=%s）" % str(avail))
	if not _player.set_active_skill("shuriken", "storm_volley", false):
		_fail("满足条件的融合神通无法激活")


func _report() -> void:
	if _casted < 12:
		_fail("只成功施放了 %d 个神通，覆盖不足（期望 >= 12）" % _casted)
	if _fails.is_empty():
		print("SKILLS PASS casted=%d" % _casted)
	else:
		for m in _fails:
			print("SKILLS FAIL: ", m)
		print("SKILLS FAIL")
