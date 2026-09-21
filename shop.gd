extends CanvasLayer

## 商店（P2 局外成长）：花死亡结算存下的灵石买永久强化。
## 数据全部来自 balance.gd 的 SHOP 表，购买/校验走 SaveGame。


func _ready():
	Audio.play_music("res://sounds/bgm_menu.wav")
	_refresh()


func _refresh() -> void:
	var coins := SaveGame.get_coins()
	%CoinsLabel.text = "灵石 %d" % coins
	for i in Balance.SHOP.size():
		var def: Dictionary = Balance.SHOP[i]
		var level := SaveGame.get_upgrade_level(def["id"])
		var button: Button = get_node("BuyButton%d" % i)
		if level >= def["max"]:
			button.text = "%s　%d/%d 阶　%s　已满" % [def["name"], level, def["max"], def["desc"]]
			button.disabled = true
			continue
		var cost := int(def["cost"]) * (level + 1)
		button.text = "%s　%d/%d 阶　%s　—　%d 灵石" % [def["name"], level, def["max"], def["desc"], cost]
		button.disabled = coins < cost


func _buy(index: int) -> void:
	var def: Dictionary = Balance.SHOP[index]
	if SaveGame.buy_upgrade(def["id"]):
		Audio.play("res://sounds/pickup.wav", false, 1.3, 0.3)
		_refresh()
	else:
		Audio.play("res://sounds/hurt.wav", false, 0.8, 0.2)


func _on_buy_button_0_pressed():
	_buy(0)


func _on_buy_button_1_pressed():
	_buy(1)


func _on_buy_button_2_pressed():
	_buy(2)


func _on_buy_button_3_pressed():
	_buy(3)


func _on_back_button_pressed():
	Audio.play("res://sounds/pickup.wav", false, 1.6, 0.25)
	Fader.fade_to_scene("res://main_menu.tscn")
