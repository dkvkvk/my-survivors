extends SceneTree

## 法宝替换 / 技能切换回归（2026-10-01，用户实测报过 bug）：
##   1) 切技能：该法宝的 active_skill 与对应技能槽都要变，其它槽不许动
##   2) 换法宝：新法宝必须**顶在被替换的那一格**，其它格的法宝与技能都不许错位
##      （原来 drop + add 会追加到末尾 -> 技能键位整体错位，玩家按键 1 不再是它、原技能像"丢了"）
## 用法：--headless --script res://tools/qa/check_skill_slots.gd，末行 SKILLSLOT PASS / FAIL

var _fails: Array = []
var _f := 0


func _initialize() -> void:
	change_scene_to_file("res://survivors_game.tscn")


func _fail(m: String) -> void:
	_fails.append(m)


func _process(_delta: float) -> bool:
	if _f < 5:
		_f += 1
		return false
	var game = root.get_node_or_null("Game")
	if game == null:
		print("SKILLSLOT FAIL: 等不到 /root/Game")
		return true
	var player = game.get_node_or_null("Player")
	if player == null:
		print("SKILLSLOT FAIL: 找不到 Player")
		return true
	_run(player)
	if _fails.is_empty():
		print("SKILLSLOT PASS")
	else:
		for m in _fails:
			print("SKILLSLOT FAIL: ", m)
		print("SKILLSLOT FAIL")
	return true


func _run(player) -> void:
	player.max_health = 1000000.0
	player.health = 1000000.0
	player.skill_books = 5
	# 重置到固定配装，保证判据不依赖当前身份 / 存档
	for w in player.weapons.duplicate():
		player.drop_weapon(str(w["id"]))
	for id in ["shuriken", "mine", "orbit_blade", "chain_lightning"]:
		player.add_weapon(id)
	if player.skill_slots.size() != 4:
		_fail("技能槽数量不是 4")
		return

	# ---- 判据 1：切技能 ----
	var avail: Array = Skills.available_for(player, "shuriken")
	if avail.size() < 2:
		_fail("本命飞剑可选技能少于 2 个")
		return
	var before: Array = player.skill_slots.duplicate()
	var target: String = str(avail[1])
	var ok: bool = player.set_active_skill("shuriken", target, true)
	if not ok:
		_fail("切技能返回 false（残卷够的情况下不该失败）")
	if str(player.get_weapon("shuriken")["active_skill"]) != target:
		_fail("切技能后法宝的 active_skill 没变")
	if str(player.skill_slots[0]) != target:
		_fail("切技能后技能槽 0 没跟着变")
	for i in range(1, 4):
		if str(player.skill_slots[i]) != str(before[i]):
			_fail("切技能不该动其它槽（槽 %d 变了）" % i)
	if player.skill_books != 4:
		_fail("切技能应该消耗 1 本残卷（现有 %d）" % player.skill_books)

	# ---- 判据 2：原位替换法宝 ----
	var slots_before: Array = player.skill_slots.duplicate()
	var ids_before: Array = []
	for i in range(1, player.weapons.size()):
		ids_before.append(str(player.weapons[i]["id"]))
	var ok2: bool = player.replace_weapon_at(0, "boomerang")
	if not ok2:
		_fail("原位替换返回 false")
	if str(player.weapons[0]["id"]) != "boomerang":
		_fail("新法宝没顶到 0 号位（是不是又追加到末尾了）")
	for i in range(1, player.weapons.size()):
		if str(player.weapons[i]["id"]) != str(ids_before[i - 1]):
			_fail("%d 号位法宝被挪动了（应为 %s，实际 %s）" % [i, ids_before[i - 1], str(player.weapons[i]["id"])])
	for i in range(1, 4):
		if str(player.skill_slots[i]) != str(slots_before[i]):
			_fail("替换后技能槽 %d 错位了（应为 %s，实际 %s）" % [i, str(slots_before[i]), str(player.skill_slots[i])])
	var expect0: String = str(Weapons.get_def("boomerang").get("skills", [""])[0])
	if str(player.skill_slots[0]) != expect0:
		_fail("0 号槽不是新法宝的首技能（应为 %s）" % expect0)

	# ---- 判据 3：边界 ----
	if player.replace_weapon_at(9, "aura"):
		_fail("越界替换应当失败")
	if player.replace_weapon_at(0, "boomerang"):
		_fail("换成已拥有的法宝应当失败")
