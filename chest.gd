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
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-20, -12), Vector2(20, -12), Vector2(24, 14),
		Vector2(-24, 14),
	])
	body.color = Color(0.55, 0.36, 0.18)
	add_child(body)
	var lid := Polygon2D.new()
	lid.polygon = PackedVector2Array([
		Vector2(-22, -24), Vector2(22, -24), Vector2(20, -12), Vector2(-20, -12),
	])
	lid.color = Color(0.68, 0.46, 0.22)
	add_child(lid)
	for trim_y in [-24.0, -12.0, 14.0]:
		var trim := Polygon2D.new()
		trim.polygon = PackedVector2Array([
			Vector2(-22, trim_y - 1.5), Vector2(22, trim_y - 1.5),
			Vector2(22, trim_y + 1.5), Vector2(-22, trim_y + 1.5),
		])
		trim.color = Color(0.95, 0.78, 0.25)
		add_child(trim)
	var lock := Polygon2D.new()
	lock.polygon = PackedVector2Array([
		Vector2(-3, -16), Vector2(3, -16), Vector2(3, -8), Vector2(-3, -8),
	])
	lock.color = Color(1.0, 0.88, 0.4)
	add_child(lock)
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
