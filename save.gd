class_name SaveGame

## 最高纪录存档（U5）：JSON 存到 user://records.json。
## 纯静态工具类，用法与 Balance/Upgrades 一致，无需实例化。
## Web 导出下 user:// 由引擎映射到 IndexedDB，同样可用。


const SAVE_PATH := "user://records.json"


## 读取最高纪录。文件不存在或损坏时返回默认值。
static func load_records() -> Dictionary:
	var records := {"best_time": 0.0, "best_kills": 0, "best_level": 1}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return records
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		for key in records.keys():
			if parsed.has(key) and parsed[key] is float:
				records[key] = parsed[key]
	# JSON 数字一律解析为 float，用前转回整型
	records["best_kills"] = int(records["best_kills"])
	records["best_level"] = int(records["best_level"])
	return records


## 提交一局战绩：刷新纪录并写盘，返回各项是否为新纪录，
## 供结算界面提示"新纪录"。
static func submit_run(kills: int, survived: float, level: int) -> Dictionary:
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
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(records))
		file.close()
	return new_flags
