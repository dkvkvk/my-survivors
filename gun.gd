extends Area2D

## 手里剑（P6 模型 B 的被动效果）：自动索敌投掷。
## 武器等级越高 → 弹丸越多、单发伤害越高、射速越快；满级进入"手里剑大师"形态。
## 数值见 balance.gd 的 WEAPON_SHURIKEN_* 与 GUN_EVOLVE_*。

var weapon_level := 1
var evolved := false


func _ready():
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL


## 由 player.gd 按武器等级调用（1 = 刚拿到）
func set_weapon_level(lv: int) -> void:
	weapon_level = maxi(lv, 1)


## 当前单发伤害（技能「手里剑乱舞」也读这里，保证被动与技能同源）
func bullet_damage_now() -> int:
	var lv_bonus: int = int((weapon_level - 1) / Balance.WEAPON_SHURIKEN_LEVEL_STEP)
	return int(get_parent().bullet_damage) + lv_bonus


## 当前每次开火的弹丸数（分裂弹头已并入武器等级）
func bullet_count_now() -> int:
	var total: int = 1 + int((weapon_level - 1) / Balance.WEAPON_SHURIKEN_LEVEL_STEP)
	if evolved:
		total += Balance.GUN_EVOLVE_EXTRA_BULLETS
	return total


## 满级进化：手里剑大师——弹丸再多两发、射速提升
func evolve() -> void:
	if evolved:
		return
	evolved = true
	Juice.pop(self, 1.6, 0.4)


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
	# 每次开火刷新射速（吃升级卡与武器等级），开销可忽略
	var rate: float = float(get_parent().fire_rate_mult) * (1.0 + Balance.WEAPON_SHURIKEN_RATE_PER_LEVEL * (weapon_level - 1))
	if evolved:
		rate *= Balance.GUN_EVOLVE_FIRE_RATE_MULT
	$Timer.wait_time = Balance.GUN_FIRE_INTERVAL / rate
	VFX.muzzle_flash(%ShootingPoint.global_position, rotation, VFX.C_CYAN)
	# 多发围绕瞄准方向左右对称扇形展开
	var total: int = bullet_count_now()
	for i in total:
		var spread: float = deg_to_rad(Balance.BULLET_SPREAD_DEG) * (i - (total - 1) / 2.0)
		var new_bullet = BULLET.instantiate()
		new_bullet.damage = bullet_damage_now()
		new_bullet.global_transform = %ShootingPoint.global_transform
		new_bullet.rotation += spread
		%ShootingPoint.add_child(new_bullet)


func _on_timer_timeout() -> void:
	shoot()
