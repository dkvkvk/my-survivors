extends CharacterBody2D

signal died


var speed = randf_range(Balance.MOB_MIN_SPEED, Balance.MOB_MAX_SPEED)
var health = Balance.MOB_HEALTH
# 每只怪锁定玩家周围一个随机偏移点 + 随机停止距离，
# 让怪物围成松散的一圈而不是叠进玩家坐标（软分离，不开物理互撞）
var attack_range := randf_range(26.0, 48.0)
var approach_offset := Vector2.from_angle(randf() * TAU) * randf_range(6.0, 26.0)

@onready var player: CharacterBody2D = get_node("/root/Game/Player")


func _ready():
	%Slime.play_walk()


func _physics_process(_delta):
	# 防护：坐标一旦非有限值（物理求解器极端情况的自愈），传回战场随机点
	if not is_finite(global_position.x) or not is_finite(global_position.y):
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 600.0
		velocity = Vector2.ZERO
		return

	var to_target := (player.global_position + approach_offset) - global_position
	var dist := to_target.length()
	if is_finite(dist) and dist > attack_range:
		velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func take_damage(amount := 1):
	%Slime.play_hurt()
	Audio.play("res://sounds/hit.wav", false, randf_range(0.9, 1.1), 0.3)
	Juice.flash(%Slime)
	Juice.damage_number(get_parent(), global_position + Vector2(0, -48), amount)
	health -= amount

	if health == 0:
		died.emit()
		Audio.play("res://sounds/enemy-die.wav", true, randf_range(0.9, 1.1), 0.15)
		Juice.shake(player.get_node("Camera2D"), 0.35)
		Juice.hitstop(0.05)
		drop_xp_gem()
		var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = smoke_scene.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		queue_free()


func drop_xp_gem():
	var gem = preload("res://xp_gem.tscn").instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position
