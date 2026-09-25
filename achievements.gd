class_name Achievements

## 成就表（P7）：用**累计统计**而不是单局数据来解锁——这样才能鼓励玩家反复来打。
## 统计存在存档的 stats 字典里（save.gd），已解锁的 id 存在 unlocked 数组里。
##
## 加成就 = 这里加一行（stat 指向 stats 里的键，或 records 里的 best_time/best_level）。
## 解锁时机：每局结算时 SaveGame.submit_run() 统一评估（见 save.gd）。

const LIST := [
	{"id": "first_run", "name": "初出茅庐", "desc": "完成第一夜", "stat": "runs", "target": 1},
	{"id": "kills_100", "name": "斩妖百只", "desc": "累计斩妖 100", "stat": "total_kills", "target": 100},
	{"id": "kills_1000", "name": "斩妖千只", "desc": "累计斩妖 1000", "stat": "total_kills", "target": 1000},
	{"id": "kills_10000", "name": "斩妖万只", "desc": "累计斩妖 10000", "stat": "total_kills", "target": 10000},
	{"id": "survive_600", "name": "守夜一刻", "desc": "单夜守到 10 分钟", "stat": "best_time", "target": 600},
	{"id": "win_1", "name": "守到黎明", "desc": "通关一次（活满或斩五妖王）", "stat": "wins", "target": 1},
	{"id": "win_5", "name": "夜夜不坠", "desc": "通关五次", "stat": "wins", "target": 5},
	{"id": "boss_3", "name": "斩王三尊", "desc": "累计斩妖王 3 只", "stat": "total_boss", "target": 3},
	{"id": "full_load", "name": "满配出行", "desc": "单夜带满 4 件法宝", "stat": "max_weapons", "target": 4},
	{"id": "weapon_max", "name": "阶位圆满", "desc": "把一件法宝养到五阶", "stat": "max_weapon_level", "target": 5},
	{"id": "coins_1000", "name": "万宝楼常客", "desc": "累计入账灵石 1000", "stat": "coins_earned", "target": 1000},
	{"id": "level_60", "name": "修为六十", "desc": "单夜修为到 60", "stat": "best_level", "target": 60},
	{"id": "two_chars", "name": "三身各显", "desc": "用过 2 个不同身份", "stat": "character_count", "target": 2},
]


static func get_def(id: String) -> Dictionary:
	for a in LIST:
		if str(a["id"]) == id:
			return a
	return {}


## 某个成就当前的进度值（records 里的 best_* 与 stats 里的累计值分开取）
static func progress(stats: Dictionary, records: Dictionary, def: Dictionary) -> int:
	var key: String = str(def.get("stat", ""))
	if key == "best_time":
		return int(float(records.get("best_time", 0.0)))
	if key == "best_level":
		return int(records.get("best_level", 0))
	if key == "character_count":
		var chars = stats.get("characters", [])
		return (chars as Array).size() if chars is Array else 0
	return int(stats.get(key, 0))


## 当前满足条件的所有成就 id
static func satisfied(stats: Dictionary, records: Dictionary) -> Array:
	var out: Array = []
	for a in LIST:
		if progress(stats, records, a) >= int(a["target"]):
			out.append(str(a["id"]))
	return out


## 这次新解锁的 id（已解锁的不重复给）
static func new_unlocks(stats: Dictionary, records: Dictionary, unlocked: Array) -> Array:
	var out: Array = []
	for id in satisfied(stats, records):
		if not unlocked.has(id):
			out.append(id)
	return out


## 把 id 列表转成"名字串"（结算界面显示用）
static func names_of(ids: Array) -> String:
	var names: Array = []
	for id in ids:
		var def := get_def(str(id))
		names.append(str(def.get("name", id)))
	return "、".join(names)
