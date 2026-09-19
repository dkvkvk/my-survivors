extends CharacterBody2D

signal health_depleted
signal leveled_up

var max_health = Balance.PLAYER_MAX_HEALTH
var health = Balance.PLAYER_MAX_HEALTH

# 经验与成长（U3）：升级三选一会改这些字段，战斗逻辑从这里读
var xp := 0
var level := 1
var xp_to_next: int = Balance.xp_for_level(1)
var speed_mult := 1.0
var fire_rate_mult := 1.0
var bullet_damage := 1
var pickup_radius := Balance.PICKUP_RADIUS

# 武器卡（U6）：环形刀刃数量 / 灼热光环等级 / 手枪额外弹丸
var orbit_blade_count := 0
var aura_level := 0
var extra_bullets := 0

# 受伤音效节流：被怪围着时每 0.6 秒最多响一次，不然太吵
var hurt_sound_cooldown := 0.0


func _ready():
	%HealthBar.max_value = max_health


func _physics_process(delta):
	hurt_sound_cooldown = maxf(0.0, hurt_sound_cooldown - delta)

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * Balance.PLAYER_SPEED * speed_mult

	move_and_slide()
	# 角色外观动画由 hero.gd 按速度自动驱动

	# Taking damage（不同怪物的接触伤害倍率不同，见 balance.gd 的 MOB_VARIANTS）
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		var contact_total := 0.0
		for mob in overlapping_mobs:
			if "contact_damage" in mob:
				contact_total += mob.contact_damage
		health -= Balance.PLAYER_DAMAGE_RATE * contact_total * delta
		%HealthBar.value = health
		if hurt_sound_cooldown <= 0.0:
			Audio.play("res://sounds/hurt.wav", false, 1.0, 0.35)
			Juice.flash(self, Color(4, 0.8, 0.8))
			Juice.shake($Camera2D, 0.2)
			hurt_sound_cooldown = 0.6
		if health <= 0.0:
			health_depleted.emit()


## 收取经验。够一级就升级并发出信号，游戏主逻辑收到后弹出三选一。
## 连升多级时一次结算经验，只弹一次卡（略有优惠，简化处理）。
func add_xp(amount: int) -> void:
	xp += amount
	if xp < xp_to_next:
		return
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = Balance.xp_for_level(level)
	health = minf(health + Balance.LEVEL_UP_HEAL, max_health)
	%HealthBar.value = health
	leveled_up.emit()


## 应用一张强化卡的效果。id 与 upgrades.gd 的卡池对应。
func apply_upgrade(id: String) -> void:
	match id:
		"speed":
			speed_mult += 0.12
		"fire_rate":
			fire_rate_mult += 0.15
		"damage":
			bullet_damage += 1
		"max_health":
			max_health += 25.0
			health = minf(health + 25.0, max_health)
			%HealthBar.max_value = max_health
		"magnet":
			pickup_radius *= 1.35
		"orbit_blade":
			orbit_blade_count += 1
			%OrbitBlades.set_blade_count(orbit_blade_count)
		"aura":
			aura_level += 1
			%Aura.configure(aura_level)
		"split_shot":
			extra_bullets += 1
	%HealthBar.value = health
