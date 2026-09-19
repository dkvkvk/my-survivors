class_name SaveGame

## 存档（U5 最高纪录 + P2 局外经济）：JSON 存到 user://records.json。
## 纯静态工具类，用法与 Balance/Upgrades 一致，无需实例化。
## Web 导出下 user:// 由引擎映射到 IndexedDB，同样可用。


const SAVE_PATH := "user://records.json"


## 读取全部存档。文件不存在或损坏时返回默认值；旧版本文件缺键自动补默认。
static func load_records() -> Dictionary:
	var records := {
		"best_time": 0.0, "best_kills": 0, "best_level": 1,
		"coins": 0, "upgrades": {},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return records
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		for key in records.keys():
			if parsed.has(key):
				if key == "upgrades" and parsed[key] is Dictionary:
					records[key] = parsed[key]
				elif parsed[key] is float:
					records[key] = parsed[key]
	# JSON 数字一律解析为 float，用前转回整型
	records["best_kills"] = int(records["best_kills"])
	records["best_level"] = int(records["best_level"])
	records["coins"] = int(records["coins"])
	return records


## 提交一局战绩：刷新最高纪录、把本局金币存入余额。返回各项是否为新纪录。
static func submit_run(kills: int, survived: float, level: int, coins: int) -> Dictionary:
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
	_write(records)
	return new_flags


## 某强化的当前等级（0 = 未购买）
static func get_upgrade_level(id: String) -> int:
	var upgrades: Dictionary = load_records()["upgrades"]
	return int(upgrades.get(id, 0))


## 当前金币余额
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


static func _write(records: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(records))
		file.close()
