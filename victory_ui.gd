extends CanvasLayer

## 胜利结算（P5）。与 GameOver 同一套结构：CanvasLayer + process_mode=Always，
## 所以游戏暂停时按钮和 R 键仍可用。
## 触发条件（二选一，见 balance.gd）：活满 SURVIVE_WIN_TIME 或击杀 VICTORY_BOSS_KILLS 只首领。

## 本局的胜利原因，用于文案
var _reason := ""


func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart()


## 展示胜利战绩并把金币入账（与失败结算共用 SaveGame.submit_run）。
## reason: "time" = 活满时长，"boss" = 打满首领数
func show_victory(kills: int, survived: float, level: int, coins: int, reason: String) -> void:
	_reason = reason
	var new_flags := SaveGame.submit_run(kills, survived, level, coins)
	var records := SaveGame.load_records()
	%ResultLabel.text = "胜 利"
	if reason == "boss":
		%ReasonLabel.text = "★ 击破 %d 只首领，忍村得救 ★" % Balance.VICTORY_BOSS_KILLS
	else:
		%ReasonLabel.text = "★ 坚守 %d 分钟，等来了黎明 ★" % int(Balance.SURVIVE_WIN_TIME / 60.0)
	%VictoryStatsLabel.text = "本局　存活 %d:%02d　击杀 %d　Lv %d\n金币 +%d（余额 %d）" % [
		int(survived) / 60, int(survived) % 60, kills, level,
		coins, int(records["coins"]),
	]
	if new_flags["time"] or new_flags["kills"] or new_flags["level"]:
		%VictoryStatsLabel.text += "\n★ 新纪录！ ★"
	%VictoryStatsLabel.text += "\n最高　存活 %d:%02d　击杀 %d　Lv %d" % [
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
