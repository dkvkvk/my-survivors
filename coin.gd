extends Area2D

## 金币（P2 局外经济）：怪按概率掉落，磁吸拾取逻辑同经验宝石，
## 外观为代码绘制的金色八边形。拾取后计入本局金币，死亡时入账存档。


var value := Balance.COIN_VALUE
var magnet_speed := 0.0

@onready var player: CharacterBody2D = get_node("/root/Game/Player")
@onready var game: Node2D = get_node("/root/Game")


func _ready():
	var octagon := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var r := 11.0 if i % 2 == 0 else 7.0
		pts.append(Vector2.RIGHT.rotated(TAU * i / 8.0 + PI / 8.0) * r)
	octagon.polygon = pts
	octagon.color = Color(1.0, 0.78, 0.2)
	add_child(octagon)
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([
		Vector2(-3, -5), Vector2(3, -5), Vector2(0, 2),
	])
	shine.color = Color(1.0, 0.95, 0.6)
	add_child(shine)
	Juice.pop(self, 1.3)


func _physics_process(delta):
	var to_player := player.global_position - global_position
	if to_player.length() < player.pickup_radius:
		magnet_speed = maxf(magnet_speed + 1400.0 * delta, 400.0)
		position += to_player.normalized() * magnet_speed * delta
	else:
		position += to_player.limit_length(1.0) * Balance.GEM_DRIFT_SPEED * delta


func _on_body_entered(body):
	if body == player:
		queue_free()
		Audio.play("res://sounds/pickup.wav", false, randf_range(1.5, 1.8), 0.22)
		game.call_deferred("add_run_coins", value)
