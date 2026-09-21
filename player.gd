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

# 法力与主动技能（P6）：4 个技能槽对应键位 1/2/3/4，施放消耗蓝条
var mana: float = Balance.MANA_START
var mana_max: float = Balance.MANA_MAX
var skill_slots := ["", "", "", ""]   # 空字符串 = 该槽没装技能
var _skill_cd := {}                    # 技能 id -> 剩余冷却（秒）

# 武器与材料（P6）：武器最多 4 把；每把武器有多个技能但每场只选一个激活。
# 捡到技能切换书可换成本武器的另一个技能。
var weapons: Array = []                # [{id, level, active_skill, kills}]
var materials := {}                    # {材料id: 数量}
var skill_books := 0                   # 技能切换书数量


func _ready():
	_apply_shop_upgrades()
	%HealthBar.max_value = max_health
	%ManaBar.max_value = mana_max
	%ManaBar.value = mana
	# 开局自带手枪（算一把武器，占一个武器位）
	add_weapon("shuriken")


## 法力回复 + 技能冷却 + 键位 1/2/3/4 施放
func _process(delta: float) -> void:
	mana = minf(mana + Balance.MANA_REGEN * delta, mana_max)
	%ManaBar.value = mana
	for id in _skill_cd.keys():
		_skill_cd[id] = maxf(0.0, _skill_cd[id] - delta)
	for i in skill_slots.size():
		if Input.is_action_just_pressed("skill_%d" % (i + 1)):
			cast_skill(i)


## ---------- 武器与材料（P6） ----------

func weapon_count() -> int:
	return weapons.size()


func has_weapon(id: String) -> bool:
	for w in weapons:
		if w["id"] == id:
			return true
	return false


func get_weapon(id: String) -> Dictionary:
	for w in weapons:
		if w["id"] == id:
			return w
	return {}


## 获得武器：装进空位并把它的默认技能同步到技能槽。
## 武器位已满时返回 false（由上层弹替换面板）。
func add_weapon(id: String) -> bool:
	var def: Dictionary = Weapons.get_def(id)
	if def.is_empty():
		return false
	if has_weapon(id):
		return true
	if weapons.size() >= Weapons.MAX_SLOTS:
		return false
	var skills: Array = def.get("skills", [])
	weapons.append({
		"id": id,
		"level": 1,
		"active_skill": skills[0] if skills.size() > 0 else "",
		"kills": 0,
	})
	_sync_skill_slots()
	return true


## 丢弃武器（替换面板用）
func drop_weapon(id: String) -> void:
	for i in weapons.size():
		if weapons[i]["id"] == id:
			weapons.remove_at(i)
			break
	_sync_skill_slots()


## 设置某把武器的"本场激活技能"。需要消耗一本切换书（swap=false 时不消耗，用于首次选择）
func set_active_skill(weapon_id: String, skill_id: String, use_book := true) -> bool:
	var w: Dictionary = get_weapon(weapon_id)
	if w.is_empty():
		return false
	var def: Dictionary = Weapons.get_def(weapon_id)
	if not (skill_id in def.get("skills", [])):
		return false
	if w["active_skill"] == skill_id:
		return true
	if use_book:
		if skill_books <= 0:
			return false
		skill_books -= 1
	w["active_skill"] = skill_id
	_sync_skill_slots()
	return true


## 把武器的激活技能同步进技能槽（槽位顺序 = 武器顺序）
func _sync_skill_slots() -> void:
	for i in skill_slots.size():
		if i < weapons.size():
			skill_slots[i] = weapons[i]["active_skill"]
		else:
			skill_slots[i] = ""


func add_material(id: String, amount := 1) -> void:
	materials[id] = int(materials.get(id, 0)) + amount


func material_count(id: String) -> int:
	return int(materials.get(id, 0))


## 武器升级：材料够 且 击杀数够 才成功
func can_upgrade_weapon(id: String) -> bool:
	var w: Dictionary = get_weapon(id)
	if w.is_empty():
		return false
	var def: Dictionary = Weapons.get_def(id)
	if int(w["level"]) >= int(def.get("max_level", 5)):
		return false
	if int(w["kills"]) < int(def.get("kills_per_level", 100)) * int(w["level"]):
		return false
	return material_count(def.get("upgrade_material", "scrap")) >= Weapons.upgrade_cost(def, int(w["level"]))


func upgrade_weapon(id: String) -> bool:
	if not can_upgrade_weapon(id):
		return false
	var w: Dictionary = get_weapon(id)
	var def: Dictionary = Weapons.get_def(id)
	var mat: String = def.get("upgrade_material", "scrap")
	materials[mat] = material_count(mat) - Weapons.upgrade_cost(def, int(w["level"]))
	w["level"] = int(w["level"]) + 1
	Audio.play("res://sounds/pickup.wav", false, 1.5, 0.4)
	Juice.pop(self, 1.4, 0.3)
	return true


## ---------- 技能 ----------

## 学会一个技能：放进第一个空槽；没有空槽则返回 false（由上层弹替换界面）
func learn_skill(id: String) -> bool:
	if not Skills.has(id):
		return false
	for i in skill_slots.size():
		if skill_slots[i] == id:
			return true   # 已经有了
	for i in skill_slots.size():
		if skill_slots[i] == "":
			skill_slots[i] = id
			return true
	return false


## 把技能装到指定槽（id 传空字符串 = 卸下）
func equip_skill(slot: int, id: String) -> void:
	if slot < 0 or slot >= skill_slots.size():
		return
	skill_slots[slot] = id


## 该技能当前剩余冷却（供 HUD 画遮罩）
func get_skill_cooldown(id: String) -> float:
	return float(_skill_cd.get(id, 0.0))


## 施放某个槽位的技能：校验有技能、蓝够、不在冷却
func cast_skill(slot: int) -> void:
	if slot < 0 or slot >= skill_slots.size():
		return
	var id: String = skill_slots[slot]
	if id == "":
		return
	var def: Dictionary = Skills.get_def(id)
	if def.is_empty():
		return
	var cost: float = float(def.get("mana", 0.0))
	if mana < cost or get_skill_cooldown(id) > 0.0:
		return
	mana -= cost
	_skill_cd[id] = float(def.get("cd", 1.0))
	Audio.play("res://sounds/pickup.wav", false, 1.2, 0.35)
	Juice.pop(self, 1.25, 0.3)
	_run_skill_effect(id)


## 技能效果：加新技能 = 这里加一个分支
func _run_skill_effect(id: String) -> void:
	match id:
		"shuriken_burst":
			_shuriken_burst()
		"blade_storm":
			_hit_all_in_radius(Balance.SKILL_BLADE_RADIUS, Balance.SKILL_BLADE_DAMAGE)
		"sunburst":
			_hit_all_in_radius(Balance.SKILL_AURA_RADIUS, Balance.SKILL_AURA_DAMAGE)
		"thunder":
			%ChainLightning.on_hit(global_position)


## 手里剑乱舞：以自身为中心放射一圈子弹
func _shuriken_burst() -> void:
	const BULLET = preload("res://bullet_2d.tscn")
	var n: int = Balance.SKILL_SHURIKEN_COUNT
	for i in n:
		var b = BULLET.instantiate()
		b.damage = bullet_damage + Balance.SKILL_SHURIKEN_DAMAGE_BONUS
		b.global_position = global_position
		b.rotation = TAU * i / float(n)
		get_parent().add_child(b)


## 对半径内所有敌人造成一次伤害（近身爆发类技能共用）
func _hit_all_in_radius(radius: float, damage: int) -> void:
	var hit := 0
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		if global_position.distance_to(mob.global_position) <= radius:
			mob.call_deferred("take_damage", damage)
			hit += 1
	if hit > 0:
		Juice.shake($Camera2D, 0.25)


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
