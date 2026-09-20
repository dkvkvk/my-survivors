extends Area2D

## 宝箱（P4）：首领必掉，走过去开启，随机奖励——
## 一半概率直接升一级随机已持有的武器（含触发进化），一半概率金币。
## 外观代码绘制：棕木箱 + 金边 + 锁扣，带轻微浮动。


@onready var player: CharacterBody2D = get_node("/root/Game/Player")
@onready var game: Node2D = get_node("/root/Game")

var _t := 0.0


func _ready():
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/ui/icon_chest.png")
	sprite.scale = Vector2.ONE * 1.5
	add_child(sprite)
	Juice.pop(self, 1.4)


func _process(delta):
	_t += delta
	# 轻微上下浮动，提示可拾取
	position.y += sin(_t * 3.0) * 4.0 * delta


func _on_body_entered(body):
	if body != player:
		return
	queue_free()
	Audio.play("res://sounds/pickup.wav", false, 1.0, 0.35)
	if randf() < Balance.CHEST_WEAPON_CHANCE:
		var id := _pick_weapon_id()
		player.apply_upgrade(id)
		var card_name: String = _weapon_card_name(id)
		Juice.damage_number(game, global_position + Vector2(0, -60), "宝箱：%s！" % card_name, {"color": Color(1.0, 0.85, 0.3), "scale": 1.5})
	else:
		var coins := randi_range(Balance.CHEST_COIN_MIN, Balance.CHEST_COIN_MAX)
		game.call_deferred("add_run_coins", coins)
		Juice.damage_number(game, global_position + Vector2(0, -60), "宝箱：金币 +%d" % coins, {"color": Color(1.0, 0.85, 0.3), "scale": 1.5})


## 优先升级已持有的武器；都没持有则随机送一门
func _pick_weapon_id() -> String:
	var owned: Array = []
	if player.orbit_blade_count > 0 or player.evolved_weapons.has("orbit_blade"):
		owned.append("orbit_blade")
	if player.aura_level > 0 or player.evolved_weapons.has("aura"):
		owned.append("aura")
	if player.extra_bullets > 0 or player.evolved_weapons.has("split_shot"):
		owned.append("split_shot")
	if owned.is_empty():
		owned = ["orbit_blade", "aura", "split_shot"]
	return owned[randi() % owned.size()]


func _weapon_card_name(id: String) -> String:
	match id:
		"orbit_blade":
			return "环形刀刃 +1"
		"aura":
			return "灼热光环 +1"
		"split_shot":
			return "分裂弹头 +1"
	return ""
