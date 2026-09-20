extends Area2D

## 金币（P2 局外经济）：怪按概率掉落，磁吸拾取逻辑同经验宝石，
## 外观为代码绘制的金色八边形。拾取后计入本局金币，死亡时入账存档。


var value := Balance.COIN_VALUE
var magnet_speed := 0.0

@onready var player: CharacterBody2D = get_node("/root/Game/Player")
@onready var game: Node2D = get_node("/root/Game")


func _ready():
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/ui/icon_coin.png")
	sprite.scale = Vector2.ONE * 0.9
	add_child(sprite)
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
