extends CanvasLayer

## Game Over 界面。场景里把本节点 process_mode 设为 Always，
## 所以游戏暂停时按钮和 R 键仍然可用；其余节点保持暂停，敌人冻结。


func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart()


func restart():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_restart_button_pressed():
	restart()
