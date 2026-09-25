extends CanvasLayer

## Game Over 界面。场景里把本节点 process_mode 设为 Always，
## 所以游戏暂停时按钮和 R 键仍然可用；其余节点保持暂停，敌人冻结。


func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart()


## 展示本局战绩并把灵石存入余额（P2）。game.gd 在玩家死亡时调用。
func show_results(kills: int, survived: float, level: int, coins: int) -> void:
	var game := get_node_or_null("/root/Game")
	var player := get_node_or_null("/root/Game/Player")
	var extra := {
		"win": false,
		"boss": int(game.boss_kill_count) if game != null else 0,
		"weapons": _weapon_ids(player),
		"max_weapon_level": _max_weapon_level(player),
		"character": SaveGame.get_character(),
	}
	var new_flags := SaveGame.submit_run(kills, survived, level, coins, extra)
	var records := SaveGame.load_records()
	%StatsLabel.text = "本夜　守夜 %d:%02d　斩妖 %d　修为 %d\n灵石 +%d（余额 %d）" % [
		int(survived) / 60, int(survived) % 60, kills, level,
		coins, int(records["coins"]),
	]
	if new_flags["time"] or new_flags["kills"] or new_flags["level"]:
		%StatsLabel.text += "\n★ 新纪录！ ★"
	%StatsLabel.text += "\n最高　守夜 %d:%02d　斩妖 %d　修为 %d" % [
		int(records["best_time"]) / 60,
		int(records["best_time"]) % 60,
		records["best_kills"],
		records["best_level"],
	]
	var unlocked: Array = new_flags.get("unlocked", [])
	if not unlocked.is_empty():
		var label = %StatsLabel if has_node("%StatsLabel") else %VictoryStatsLabel
		label.text += "
★ 解锁成就：" + Achievements.names_of(unlocked) + " ★"
	show()


func restart():
	get_tree().paused = false
	Fader.fade_to_scene(get_tree().current_scene.scene_file_path)


func back_to_menu():
	get_tree().paused = false
	Fader.fade_to_scene("res://main_menu.tscn")


func _on_restart_button_pressed():
	restart()


func _on_menu_button_pressed():
	back_to_menu()



## 本局携带的法宝 id 列表（成就统计用）
func _weapon_ids(p) -> Array:
	var out: Array = []
	if p != null:
		for w in p.weapons:
			out.append(str(w["id"]))
	return out


## 本局最高的法宝品阶（成就统计用）
func _max_weapon_level(p) -> int:
	var m := 0
	if p != null:
		for w in p.weapons:
			m = maxi(m, int(w["level"]))
	return m
