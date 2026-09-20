extends CanvasLayer

## 升级三选一界面。present() 会暂停游戏并随机展示 3 张强化卡，
## 本节点 process_mode 设为 Always，所以暂停时卡片仍可点击。


var player: CharacterBody2D
var choices: Array = []


func present(p_player: CharacterBody2D) -> void:
	player = p_player
	var pool = Upgrades.LIST.duplicate()
	# 已进化的武器卡不再出现（P3）
	pool = pool.filter(func(card): return not player.is_card_unavailable(card["id"]))
	pool.shuffle()
	choices = pool.slice(0, 3)
	%Title.text = "★ 升级！选一张强化 ★"
	for i in 3:
		var card: Button = get_node("Card%d" % i)
		card.text = "%s\n%s" % [choices[i]["name"], choices[i]["desc"]]
		# 卡片图标（P5）：无贴图时隐藏图标槽
		var icon_slot: TextureRect = get_node("Card%d/Card%dIcon" % [i, i])
		var icon_path: String = choices[i].get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_slot.texture = load(icon_path)
			icon_slot.show()
		else:
			icon_slot.hide()
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
