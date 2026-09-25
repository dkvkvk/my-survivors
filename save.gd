class_name SaveGame

## 存档（U5 最高纪录 + P2 局外经济 + P7 身份与设置）：JSON 存到 user://records.json。
## 纯静态工具类，用法与 Balance/Upgrades 一致，无需实例化。
## Web 导出下 user:// 由引擎映射到 IndexedDB，同样可用。


const SAVE_PATH := "user://records.json"


## 读取全部存档。文件不存在或损坏时返回默认值；旧版本文件缺键自动补默认。
static func load_records() -> Dictionary:
	var records := {
		"best_time": 0.0, "best_kills": 0, "best_level": 1,
		"coins": 0, "upgrades": {},
		"stats": {}, "unlocked": [],
		"character": "", "settings": {},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return records
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		for key in records.keys():
			if not parsed.has(key):
				continue
			var v = parsed[key]
			# JSON 数字一律是 float；字典（upgrades/settings）与字符串（character）原样取
			if v is Dictionary or v is Array or v is float or v is String or v is int or v is bool:
				records[key] = v
	# JSON 数字一律解析为 float，用前转回整型
	records["best_kills"] = int(records["best_kills"])
	records["best_level"] = int(records["best_level"])
	records["coins"] = int(records["coins"])
	return records


## 提交一局战绩：刷新最高纪录、把本局灵石存入余额。返回各项是否为新纪录。
static func submit_run(kills: int, survived: float, level: int, coins: int, extra := {}) -> Dictionary:
	var records := load_records()
	var new_flags := {"time": false, "kills": false, "level": false}
	if survived > records["best_time"]:
		records["best_time"] = survived
		new_flags["time"] = true
	if kills > records["best_kills"]:
		records["best_kills"] = kills
		new_flags["kills"] = true
	if level > records["best_level"]:
		records["best_level"] = level
		new_flags["level"] = true
	records["coins"] = int(records["coins"]) + coins

	# ---- 累计统计（成就用；stats 累加，records 里的 best_* 由上面维护）----
	var stats: Dictionary = records["stats"]
	stats["runs"] = int(stats.get("runs", 0)) + 1
	stats["total_kills"] = int(stats.get("total_kills", 0)) + kills
	stats["total_time"] = float(stats.get("total_time", 0.0)) + survived
	stats["coins_earned"] = int(stats.get("coins_earned", 0)) + coins
	stats["total_boss"] = int(stats.get("total_boss", 0)) + int(extra.get("boss", 0))
	var run_weapons: Array = extra.get("weapons", [])
	stats["max_weapons"] = maxi(int(stats.get("max_weapons", 0)), run_weapons.size())
	stats["max_weapon_level"] = maxi(int(stats.get("max_weapon_level", 0)), int(extra.get("max_weapon_level", 0)))
	if bool(extra.get("win", false)):
		stats["wins"] = int(stats.get("wins", 0)) + 1
	var chars: Array = stats.get("characters", [])
	var ch: String = str(extra.get("character", ""))
	if ch != "" and not chars.has(ch):
		chars.append(ch)
	stats["characters"] = chars
	records["stats"] = stats

	# ---- 成就评估（只在结算时做，避免每帧判）----
	var unlocked: Array = records["unlocked"]
	var newly: Array = Achievements.new_unlocks(stats, records, unlocked)
	for id in newly:
		unlocked.append(id)
	records["unlocked"] = unlocked

	_write(records)
	new_flags["unlocked"] = newly
	return new_flags


## 某强化的当前等级（0 = 未购买）
static func get_upgrade_level(id: String) -> int:
	var upgrades: Dictionary = load_records()["upgrades"]
	return int(upgrades.get(id, 0))


## 当前灵石余额
static func get_coins() -> int:
	return int(load_records()["coins"])


## 购买一级强化：校验等级上限与余额，成功扣款写盘返回 true
static func buy_upgrade(id: String) -> bool:
	var def: Dictionary = {}
	for entry in Balance.SHOP:
		if entry["id"] == id:
			def = entry
			break
	if def.is_empty():
		return false
	var records := load_records()
	var upgrades: Dictionary = records["upgrades"]
	var level := int(upgrades.get(id, 0))
	if level >= def["max"]:
		return false
	var cost := int(def["cost"]) * (level + 1)
	if int(records["coins"]) < cost:
		return false
	records["coins"] = int(records["coins"]) - cost
	upgrades[id] = level + 1
	records["upgrades"] = upgrades
	_write(records)
	return true


## ---------- 身份（P7 多角色）----------

static func get_character() -> String:
	return String(load_records()["character"])


static func set_character(id: String) -> void:
	var records := load_records()
	records["character"] = id
	_write(records)


## ---------- 设置（P7 设置菜单）：音量、抖动强度等 ----------

static func get_settings() -> Dictionary:
	var s = load_records()["settings"]
	return s if s is Dictionary else {}


static func get_setting(key: String, fallback: Variant) -> Variant:
	var s: Dictionary = get_settings()
	return s[key] if s.has(key) else fallback


static func set_setting(key: String, value: Variant) -> void:
	var records := load_records()
	var s: Dictionary = records["settings"]
	s[key] = value
	records["settings"] = s
	_write(records)


static func get_stats() -> Dictionary:
	var s = load_records()["stats"]
	return s if s is Dictionary else {}


static func get_unlocked() -> Array:
	var u = load_records()["unlocked"]
	return u if u is Array else []


static func _write(records: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(records))
		file.close()
