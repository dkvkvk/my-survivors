extends CanvasLayer

## Game Over 界面。场景里把本节点 process_mode 设为 Always，
## 所以游戏暂停时按钮和 R 键仍然可用；其余节点保持暂停，敌人冻结。


func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart()


## 展示本局战绩并提交最高纪录存档（U5）。game.gd 在玩家死亡时调用。
func show_results(kills: int, survived: float, level: int) -> void:
	var new_flags := SaveGame.submit_run(kills, survived, level)
	var records := SaveGame.load_records()
	%StatsLabel.text = "本局　存活 %d:%02d　击杀 %d　Lv %d" % [
		int(survived) / 60, int(survived) % 60, kills, level,
	]
	if new_flags["time"] or new_flags["kills"] or new_flags["level"]:
		%StatsLabel.text += "\n★ 新纪录！ ★"
	%StatsLabel.text += "\n最高　存活 %d:%02d　击杀 %d　Lv %d" % [
		int(records["best_time"]) / 60,
		int(records["best_time"]) % 60,
		records["best_kills"],
		records["best_level"],
	]
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
