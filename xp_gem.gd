extends Area2D

## 经验宝石：怪死后掉落。进入玩家拾取半径会被加速吸过来，碰到玩家即收取。
## 外观用代码里的 Polygon2D 菱形，不依赖外部素材。


var value := Balance.GEM_VALUE
var magnet_speed := 0.0

@onready var player: CharacterBody2D = get_node("/root/Game/Player")


func _ready():
	Juice.pop(self, 1.4)


func _physics_process(delta):
	var to_player := player.global_position - global_position
	if to_player.length() < player.pickup_radius:
		# 进入磁吸范围后越飞越快
		magnet_speed = maxf(magnet_speed + 1400.0 * delta, 400.0)
		position += to_player.normalized() * magnet_speed * delta
	else:
		# 磁吸范围外也缓慢滚向玩家，不用专门跑图去捡
		position += to_player.limit_length(1.0) * Balance.GEM_DRIFT_SPEED * delta


func _on_body_entered(body):
	if body == player:
		queue_free()
		Audio.play("res://sounds/pickup.wav", false, randf_range(1.1, 1.35), 0.2)
		# 加经验可能触发升级暂停，延迟到物理刷新外执行
		player.call_deferred("add_xp", value)
