extends Area2D


func _ready():
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL


func _process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		var target_enemy = enemies_in_range.front()
		look_at(target_enemy.global_position)


func shoot():
	const BULLET = preload("res://bullet_2d.tscn")
	Audio.play("res://sounds/shoot.wav", false, randf_range(0.9, 1.1), 0.2)
	# 每次开火刷新射速（吃升级加成），开销可忽略
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL / get_parent().fire_rate_mult
	var new_bullet = BULLET.instantiate()
	new_bullet.damage = get_parent().bullet_damage
	new_bullet.global_transform = %ShootingPoint.global_transform
	%ShootingPoint.add_child(new_bullet)


func _on_timer_timeout() -> void:
	shoot()
