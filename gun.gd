extends Area2D

var evolved := false  # 手里剑大师形态


func _ready():
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL


func _process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	for enemy in enemies_in_range:
		# 防护：跳过坐标异常（NaN/inf）的目标，避免枪朝向被污染
		if is_finite(enemy.global_position.x) and is_finite(enemy.global_position.y):
			look_at(enemy.global_position)
			break


## 进化：手里剑大师——弹丸再多两发、射速提升
func evolve() -> void:
	if evolved:
		return
	evolved = true
	Juice.pop(self, 1.6, 0.4)


func shoot():
	const BULLET = preload("res://bullet_2d.tscn")
	Audio.play("res://sounds/shoot.wav", false, randf_range(0.9, 1.1), 0.2)
	# 每次开火刷新射速（吃升级加成），开销可忽略
	var rate: float = get_parent().fire_rate_mult
	if evolved:
		rate *= Balance.GUN_EVOLVE_FIRE_RATE_MULT
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL / rate
	# 分裂弹头（U6）：额外弹丸围绕瞄准方向左右对称扇形展开
	var total: int = 1 + get_parent().extra_bullets
	if evolved:
		total += Balance.GUN_EVOLVE_EXTRA_BULLETS
	for i in total:
		var spread: float = deg_to_rad(Balance.BULLET_SPREAD_DEG) * (i - (total - 1) / 2.0)
		var new_bullet = BULLET.instantiate()
		new_bullet.damage = get_parent().bullet_damage
		new_bullet.global_transform = %ShootingPoint.global_transform
		new_bullet.rotation += spread
		%ShootingPoint.add_child(new_bullet)


func _on_timer_timeout() -> void:
	shoot()
