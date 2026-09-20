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

# 武器卡（U6）：环形刀刃数量 / 灼热光环等级 / 手枪额外弹丸 / 链式闪电等级
var orbit_blade_count := 0
var aura_level := 0
var extra_bullets := 0
var chain_level := 0
# 武器进化（P3）：同名卡抽满 5 级后第 6 张触发进化，进化后从卡池移除
var evolved_weapons := {}

# 受伤音效节流：被怪围着时每 0.6 秒最多响一次，不然太吵
var hurt_sound_cooldown := 0.0


func _ready():
	_apply_shop_upgrades()
	%HealthBar.max_value = max_health


## 应用商店局外强化（P2）：改的是初始面板，局内卡牌照常叠加
func _apply_shop_upgrades() -> void:
	max_health += Balance.SHOP_HP_PER_LEVEL * SaveGame.get_upgrade_level("hp")
	health = max_health
	bullet_damage += Balance.SHOP_DMG_PER_LEVEL * SaveGame.get_upgrade_level("dmg")
	speed_mult += Balance.SHOP_SPD_PER_LEVEL * SaveGame.get_upgrade_level("spd")
	pickup_radius *= 1.0 + Balance.SHOP_MAG_PER_LEVEL * SaveGame.get_upgrade_level("mag")


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
			if _try_evolve("orbit_blade"):
				%OrbitBlades.evolve()
			else:
				orbit_blade_count += 1
				%OrbitBlades.set_blade_count(orbit_blade_count)
		"aura":
			if _try_evolve("aura"):
				%Aura.evolve()
			else:
				aura_level += 1
				%Aura.configure(aura_level)
		"split_shot":
			if _try_evolve("split_shot"):
				$Gun.evolve()
			else:
				extra_bullets += 1
		"chain_lightning":
			if _try_evolve("chain_lightning"):
				%ChainLightning.evolve()
			else:
				chain_level += 1
				%ChainLightning.configure(chain_level)
	%HealthBar.value = health


## 武器满级后再抽一张同名卡时触发进化（返回 true）。计数封顶在 EVOLVE_LEVEL。
func _try_evolve(id: String) -> bool:
	var count := 0
	match id:
		"orbit_blade":
			count = orbit_blade_count
		"aura":
			count = aura_level
		"split_shot":
			count = extra_bullets
		"chain_lightning":
			count = chain_level
	if count >= Balance.EVOLVE_LEVEL and not evolved_weapons.has(id):
		evolved_weapons[id] = true
		Audio.play("res://sounds/pickup.wav", false, 2.0, 0.4)
		Juice.damage_number(get_parent(), global_position + Vector2(0, -120), "★ 进化 ★", {"color": Color(1.0, 0.85, 0.3), "scale": 2.0})
		return true
	return false


## 卡池过滤：已进化的武器卡不再出现（供 level_up_ui 调用）
func is_card_unavailable(id: String) -> bool:
	return evolved_weapons.has(id)


## 任意武器命中敌人时调用（bullet_2d / orbit_blades），
## 由链式闪电自己判断等级与冷却——没有这张卡时这里等于空操作。
func on_weapon_hit(pos: Vector2) -> void:
	%ChainLightning.on_hit(pos)
