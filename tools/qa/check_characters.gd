extends SceneTree

## 多角色（P7）回归：
##   1) 每个身份的属性倍率 / 签名法宝 / 配色都要生效
##   2) 存档回读一致；非法 id 自动回退默认身份
## 测法：复用战斗场景里现成的玩家，把面板重置到"商店升级后"的基准再重放身份
##      （避免独立实例化 player.tscn 时 %唯一名 解析不到的问题）
## 结束时会把身份还原成测试前的值。
## 用法：--headless --script res://tools/qa/check_characters.gd，末行 CHARS PASS / FAIL

const CASES := [
	{"id": "shou_shan", "extra": "", "hp_ratio": 1.0, "rate": 1.0, "mana": 1.0},
	{"id": "fu_xiu", "extra": "mine", "hp_ratio": 0.75, "rate": 1.0, "mana": 1.4},
	{"id": "jian_xiu", "extra": "orbit_blade", "hp_ratio": 1.0, "rate": 1.25, "mana": 1.0},
	{"id": "__bogus__", "extra": "", "hp_ratio": 1.0, "rate": 1.0, "mana": 1.0},
]

var _fails: Array = []
var _orig_char := ""
var _f := 0


func _initialize() -> void:
	_orig_char = SaveGame.get_character()
	change_scene_to_file("res://survivors_game.tscn")


func _fail(m: String) -> void:
	_fails.append(m)


func _process(_delta: float) -> bool:
	if _f < 4:
		_f += 1
		return false
	var game = root.get_node_or_null("Game")
	if game == null:
		print("CHARS FAIL: 等不到 /root/Game")
		return true
	var player = game.get_node_or_null("Player")
	if player == null:
		print("CHARS FAIL: 找不到 Player")
		return true
	for case in CASES:
		var id: String = str(case["id"])
		_reset_for(player, id)
		_check(player, id, case, float(Balance.PLAYER_MAX_HEALTH) + Balance.SHOP_HP_PER_LEVEL * SaveGame.get_upgrade_level("hp"))
	SaveGame.set_character(_orig_char)   # 还原用户原来的选择
	if _fails.is_empty():
		print("CHARS PASS")
	else:
		for m in _fails:
			print("CHARS FAIL: ", m)
		print("CHARS FAIL")
	return true


## 把玩家面板重置到"商店升级后"的基准，再套用指定身份
func _reset_for(player, id: String) -> void:
	SaveGame.set_character(id)
	player.weapons = []
	player.add_weapon("shuriken")   # 基础法宝：每个身份都自带（对应 _ready 的行为）
	player.max_health = float(Balance.PLAYER_MAX_HEALTH) + Balance.SHOP_HP_PER_LEVEL * SaveGame.get_upgrade_level("hp")
	player.speed_mult = 1.0 + Balance.SHOP_SPD_PER_LEVEL * SaveGame.get_upgrade_level("spd")
	player.fire_rate_mult = 1.0
	player.mana_max = Balance.MANA_MAX
	player._char = Characters.current_def()
	player._apply_character()


func _check(player, id: String, case: Dictionary, base_hp: float) -> void:
	var def: Dictionary = Characters.get_def(id)
	if id == "__bogus__":
		if String(def["id"]) != Characters.DEFAULT_ID:
			_fail("非法身份没有回退到默认身份")
		return
	var extra: String = str(case["extra"])
	if extra == "":
		if player.weapons.size() != 1 or String(player.weapons[0]["id"]) != "shuriken":
			_fail(id + ": 应该只有本命飞剑一把")
	elif not player.has_weapon(extra):
		_fail(id + ": 签名法宝 " + extra + " 没有自动获得")
	var expect_hp: float = base_hp * float(case["hp_ratio"])
	if absf(float(player.max_health) - expect_hp) > 1.0:
		_fail("%s: 血量不符 期望 %.0f 实际 %.0f" % [id, expect_hp, player.max_health])
	if absf(float(player.fire_rate_mult) - float(case["rate"])) > 0.02:
		_fail("%s: 射速倍率不符 期望 %.2f 实际 %.2f" % [id, float(case["rate"]), player.fire_rate_mult])
	var mana_ratio: float = float(player.mana_max) / float(Balance.MANA_MAX)
	if absf(mana_ratio - float(case["mana"])) > 0.02:
		_fail("%s: 灵力倍率不符 期望 %.2f 实际 %.2f" % [id, mana_ratio])
	var tint: Color = def.get("tint", Color(1, 1, 1))
	if id != "shou_shan" and tint == Color(1, 1, 1):
		_fail(id + ": 配色没有区分")
	if SaveGame.get_character() != id:
		_fail(id + ": 存档回读不一致")
