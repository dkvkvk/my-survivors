extends CanvasLayer

## 暂停菜单（U5）：Esc 开关。场景里把本节点 process_mode 设为 Always，
## 暂停时按钮与 Esc 仍然可用。升级/结算界面打开时不响应，避免状态叠加。


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # 内置 Esc，兼容物理键与合成事件
		if %GameOver.visible or %LevelUpUI.visible or %InventoryUI.visible or %StartSelectUI.visible:
			return
		if visible:
			resume()
		else:
			pause()


func pause():
	show()
	get_tree().paused = true


func resume():
	hide()
	get_tree().paused = false


func _on_resume_button_pressed():
	resume()


func _on_restart_button_pressed():
	get_tree().paused = false
	Fader.fade_to_scene(get_tree().current_scene.scene_file_path)


func _on_menu_button_pressed():
	get_tree().paused = false
	Fader.fade_to_scene("res://main_menu.tscn")
