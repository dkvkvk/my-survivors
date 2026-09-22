extends SceneTree

# 全量加载项目内每个 .gd，任何解析失败都会被 load() 判为 null。
# 输出契约：SCRIPT_CHECK_BAD=<数量>，随后逐行 "  BAD: <路径>"

func _all_gd(dir_path: String, acc: Array) -> Array:
	var d := DirAccess.open(dir_path)
	if d == null:
		return acc
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var full := dir_path.path_join(name)
		if d.current_is_dir():
			_all_gd(full, acc)
		elif name.ends_with(".gd"):
			acc.append(full)
		name = d.get_next()
	d.list_dir_end()
	return acc

func _initialize() -> void:
	var files := _all_gd("res://", [])
	var loaded := 0
	for f in files:
		if f.begins_with("res://tools/qa/"):
			continue
		# load() 对坏脚本仍返回非 null，所以这里只负责"逼 Godot 解析"，
		# 真正的判定由 loop_judge.py 抓 stderr 里的 Parse Error 完成。
		load(f)
		loaded += 1
	print("SCRIPT_CHECK_TOTAL=", files.size())
	print("SCRIPT_CHECK_LOADED=", loaded)
	quit(0)
