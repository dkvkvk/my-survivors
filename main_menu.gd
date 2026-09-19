extends CanvasLayer

## 主菜单（U5）：项目主场景。开始游戏切换到战斗场景，
## 最高纪录从 SaveGame 读取（user://records.json）。


func _ready():
	Audio.play_music("res://sounds/bgm_menu.wav")
	var records := SaveGame.load_records()
	%RecordsLabel.text = "最高纪录　存活 %d:%02d　击杀 %d　Lv %d" % [
		int(records["best_time"]) / 60,
		int(records["best_time"]) % 60,
		records["best_kills"],
		records["best_level"],
	]
	# Web 版跑在浏览器里没有窗口可关，隐藏退出按钮
	if OS.has_feature("web"):
		%QuitButton.hide()


func _on_start_button_pressed():
	Audio.play("res://sounds/pickup.wav", false, 1.6, 0.25)
	Fader.fade_to_scene("res://survivors_game.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
