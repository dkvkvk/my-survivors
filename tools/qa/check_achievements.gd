extends SceneTree

## 成就系统（P7）回归：
##   1) 累计统计（斩妖/局数/通关/妖王/法宝数/品阶/灵石/身份）正确累加并持久化
##   2) 条件达成即解锁、已解锁不重复给
##   3) 主菜单成就页能打开并列出全部条目
## ⚠️ 会临时改写 user://records.json，结束时恢复原内容。
## 用法：--headless --script res://tools/qa/check_achievements.gd，末行 ACHIEVE PASS / FAIL

var _f := 0
var _fails: Array = []
var _backup := {}


func _initialize() -> void:
	_backup = SaveGame.load_records()
	change_scene_to_file("res://main_menu.tscn")


func _fail(m: String) -> void:
	_fails.append(m)


func _process(_delta: float) -> bool:
	_f += 1
	if _f < 5:
		return false
	_run_checks()
	SaveGame._write(_backup)   # 恢复玩家真实存档
	if _fails.is_empty():
		print("ACHIEVE PASS")
	else:
		for m in _fails:
			print("ACHIEVE FAIL: ", m)
		print("ACHIEVE FAIL")
	return true


func _run_checks() -> void:
	# 干净档
	SaveGame._write({
		"best_time": 0.0, "best_kills": 0, "best_level": 1, "coins": 0, "upgrades": {},
		"character": "shou_shan", "settings": {}, "stats": {}, "unlocked": [],
	})
	if not SaveGame.get_unlocked().is_empty():
		_fail("清档后仍有已解锁成就")

	# 第一局：温和数据
	var r1 := SaveGame.submit_run(150, 30.0, 5, 100, {
		"win": false, "boss": 0, "weapons": ["shuriken"], "max_weapon_level": 1,
		"character": "shou_shan"})
	var u1: Array = r1.get("unlocked", [])
	for want in ["first_run", "kills_100"]:
		if not u1.has(want):
			_fail("第一局应解锁 %s（实际 %s）" % [want, str(u1)])
	if u1.has("kills_1000"):
		_fail("累计 150 斩不该解锁千斩")

	# 第二局：爆发数据（一次性够到多项）
	var r2 := SaveGame.submit_run(1000, 700.0, 70, 1200, {
		"win": true, "boss": 3, "weapons": ["a", "b", "c", "d"], "max_weapon_level": 5,
		"character": "fu_xiu"})
	var u2: Array = r2.get("unlocked", [])
	for want in ["kills_1000", "survive_600", "win_1", "boss_3", "full_load",
			"weapon_max", "coins_1000", "level_60", "two_chars"]:
		if not u2.has(want):
			_fail("第二局应解锁 %s（实际 %s）" % [want, str(u2)])
	if u2.has("first_run"):
		_fail("已解锁的成就不该重复给")

	# 持久化与累计
	var unlocked: Array = SaveGame.get_unlocked()
	if unlocked.size() != u1.size() + u2.size():
		_fail("解锁总数不符：%d != %d" % [unlocked.size(), u1.size() + u2.size()])
	var stats: Dictionary = SaveGame.get_stats()
	if int(stats.get("total_kills", 0)) != 1150:
		_fail("累计斩妖不符：%d" % int(stats.get("total_kills", 0)))
	if int(stats.get("runs", 0)) != 2:
		_fail("局数不符：%d" % int(stats.get("runs", 0)))
	if int(stats.get("wins", 0)) != 1:
		_fail("通关数不符：%d" % int(stats.get("wins", 0)))
	if int(stats.get("total_boss", 0)) != 3:
		_fail("妖王累计不符：%d" % int(stats.get("total_boss", 0)))

	# 第三局：不该再解锁
	var r3 := SaveGame.submit_run(10, 5.0, 2, 0, {})
	var u3: Array = r3.get("unlocked", [])
	if not u3.is_empty():
		_fail("第三局不该有新解锁（实际 %s）" % str(u3))

	# 主菜单成就页
	var menu = root.get_node_or_null("MainMenu")
	if menu == null:
		_fail("找不到主菜单")
		return
	menu._open_achievements()
	var panel = menu._ach_panel
	if panel == null:
		_fail("成就页没有打开")
		return
	var rows := 0
	for c in panel.get_children():
		for ch in c.get_children():
			if ch is Label and str((ch as Label).text).find("/") >= 0:
				rows += 1
	if rows < Achievements.LIST.size():
		_fail("成就页条目数 %d < %d" % [rows, Achievements.LIST.size()])
