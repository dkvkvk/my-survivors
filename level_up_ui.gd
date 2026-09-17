extends CanvasLayer

## 升级三选一界面。present() 会暂停游戏并随机展示 3 张强化卡，
## 本节点 process_mode 设为 Always，所以暂停时卡片仍可点击。


var player: CharacterBody2D
var choices: Array = []


func present(p_player: CharacterBody2D) -> void:
	player = p_player
	var pool = Upgrades.LIST.duplicate()
	pool.shuffle()
	choices = pool.slice(0, 3)
	%Title.text = "★ 升级！选一张强化 ★"
	$Card0.text = "%s\n%s" % [choices[0]["name"], choices[0]["desc"]]
	$Card1.text = "%s\n%s" % [choices[1]["name"], choices[1]["desc"]]
	$Card2.text = "%s\n%s" % [choices[2]["name"], choices[2]["desc"]]
	get_tree().paused = true
	show()


func _choose(index: int) -> void:
	player.apply_upgrade(choices[index]["id"])
	Audio.play("res://sounds/pickup.wav", false, 1.6, 0.25)
	hide()
	get_tree().paused = false


func _on_card_0_pressed():
	_choose(0)


func _on_card_1_pressed():
	_choose(1)


func _on_card_2_pressed():
	_choose(2)
