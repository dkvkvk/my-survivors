extends CanvasLayer

## 胜利结算（P5）。与 GameOver 同一套结构：CanvasLayer + process_mode=Always，
## 所以游戏暂停时按钮和 R 键仍可用。
## 触发条件（二选一，见 balance.gd）：活满 SURVIVE_WIN_TIME 或斩妖 VICTORY_BOSS_KILLS 只妖王。

## 本局的胜利原因，用于文案
var _reason := ""


func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart()


## 展示胜利战绩并把灵石入账（与失败结算共用 SaveGame.submit_run）。
## reason: "time" = 活满时长，"boss" = 打满妖王数
func show_victory(kills: int, survived: float, level: int, coins: int, reason: String) -> void:
	_reason = reason
	var new_flags := SaveGame.submit_run(kills, survived, level, coins)
	var records := SaveGame.load_records()
	%ResultLabel.text = "胜 利"
	if reason == "boss":
		%ReasonLabel.text = "★ 斩三妖王，妖潮无锚自溃 ★"
	else:
		%ReasonLabel.text = "★ 坚守至黎明，妖潮退散 ★"
	%VictoryStatsLabel.text = "本夜　守夜 %d:%02d　斩妖 %d　修为 %d\n灵石 +%d（余额 %d）" % [
		int(survived) / 60, int(survived) % 60, kills, level,
		coins, int(records["coins"]),
	]
	if new_flags["time"] or new_flags["kills"] or new_flags["level"]:
		%VictoryStatsLabel.text += "\n★ 新纪录！ ★"
	%VictoryStatsLabel.text += "\n最高　守夜 %d:%02d　斩妖 %d　修为 %d" % [
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
