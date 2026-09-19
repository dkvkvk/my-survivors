extends Area2D


func _ready():
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL


func _process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	for enemy in enemies_in_range:
		# 防护：跳过坐标异常（NaN/inf）的目标，避免枪朝向被污染
		if is_finite(enemy.global_position.x) and is_finite(enemy.global_position.y):
			look_at(enemy.global_position)
			break


func shoot():
	const BULLET = preload("res://bullet_2d.tscn")
	Audio.play("res://sounds/shoot.wav", false, randf_range(0.9, 1.1), 0.2)
	# 每次开火刷新射速（吃升级加成），开销可忽略
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL / get_parent().fire_rate_mult
	# 分裂弹头（U6）：额外弹丸围绕瞄准方向左右对称扇形展开
	var total: int = 1 + get_parent().extra_bullets
	for i in total:
		var spread: float = deg_to_rad(Balance.BULLET_SPREAD_DEG) * (i - (total - 1) / 2.0)
		var new_bullet = BULLET.instantiate()
		new_bullet.damage = get_parent().bullet_damage
		new_bullet.global_transform = %ShootingPoint.global_transform
		new_bullet.rotation += spread
		%ShootingPoint.add_child(new_bullet)


func _on_timer_timeout() -> void:
	shoot()
