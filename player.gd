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

# 法宝被动状态由各法宝节点自己保存（Gun / OrbitBlades / Aura / ChainLightning）；
# 等级的唯一来源是 weapons 数组里的 level（P6 模型 B），这里不再重复存一份。

# 受伤音效节流：被怪围着时每 0.6 秒最多响一次，不然太吵
var hurt_sound_cooldown := 0.0

# 灵力与主动技能（P6）：4 个技能槽对应键位 1/2/3/4，施放消耗蓝条
var mana: float = Balance.MANA_START
var mana_max: float = Balance.MANA_MAX
var skill_slots := ["", "", "", ""]   # 空字符串 = 该槽没装技能
var _skill_cd := {}                    # 技能 id -> 剩余冷却（秒）

# 法宝与材料（P6）：法宝最多 4 把；每把法宝有多个技能但每场只选一个激活。
# 捡到神通残卷可换成本法宝的另一个技能。
var weapons: Array = []                # [{id, level, active_skill, kills}]
var materials := {}                    # {材料id: 数量}
var skill_books := 0                   # 神通残卷数量


func _ready():
	_apply_shop_upgrades()
	%HealthBar.max_value = max_health
	%ManaBar.max_value = mana_max
	%ManaBar.value = mana
	# 开局自带手枪（算一把法宝，占一个法宝位）
	add_weapon("shuriken")


## 灵力回复 + 技能冷却 + 键位 1/2/3/4 施放
func _process(delta: float) -> void:
	mana = minf(mana + Balance.MANA_REGEN * delta, mana_max)
	%ManaBar.value = mana
	for id in _skill_cd.keys():
		_skill_cd[id] = maxf(0.0, _skill_cd[id] - delta)
	for i in skill_slots.size():
		if Input.is_action_just_pressed("skill_%d" % (i + 1)):
			cast_skill(i)


## ---------- 法宝与材料（P6） ----------

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


## 获得法宝：装进空位 → **激活它的被动效果** → 把默认技能同步到技能槽。
## 法宝位已满时返回 false（由上层弹替换面板）。
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
	_apply_weapon_passive(id)
	_sync_skill_slots()
	return true


## 开局选法宝（P6）：本命飞剑是固定基础法宝（保证有自动攻击），
## 选它 = 起手直接给到 START_WEAPON_LEVEL；选其它法宝 = 追加装备（法宝位与技能槽各 +1）。
func apply_start_weapon(id: String) -> void:
	var w: Dictionary = get_weapon(id)
	if w.is_empty():
		add_weapon(id)
	else:
		w["level"] = Balance.START_WEAPON_LEVEL
		_apply_weapon_passive(id)
	var def: Dictionary = Weapons.get_def(id)
	Juice.damage_number(get_parent(), global_position + Vector2(0, -120),
		"起手：%s" % def.get("name", id), {"color": Color(0.6, 1.0, 1.0), "scale": 1.6})
	VFX.levelup_burst(global_position, VFX.C_CYAN)


## 丢弃法宝（替换面板用）：同时卸下它的被动效果
func drop_weapon(id: String) -> void:
	for i in weapons.size():
		if weapons[i]["id"] == id:
			weapons.remove_at(i)
			break
	_clear_weapon_passive(id)
	_sync_skill_slots()


## ---------- 法宝被动（P6 模型 B：法宝 = 被动效果 + 提供技能）----------
## 被动等级 = 法宝等级。加法宝时这里加一个分支即可（法宝节点自己处理数值曲线）。

func _apply_weapon_passive(id: String) -> void:
	var w: Dictionary = get_weapon(id)
	if w.is_empty():
		return
	var lv: int = int(w["level"])
	match id:
		"shuriken":
			$Gun.set_weapon_level(lv)
		"orbit_blade":
			%OrbitBlades.set_blade_count(lv)
		"aura":
			%Aura.configure(lv)
		"chain_lightning":
			%ChainLightning.configure(lv)


func _clear_weapon_passive(id: String) -> void:
	match id:
		"orbit_blade":
			%OrbitBlades.set_blade_count(0)
		"aura":
			%Aura.deactivate()
		"chain_lightning":
			%ChainLightning.configure(0)


## 满级进化：把该法宝的被动切到强化形态（剑光化灵 / 刃风暴 / 烈日领域 / 雷神之怒）
func _evolve_weapon(id: String) -> void:
	match id:
		"shuriken":
			$Gun.evolve()
		"orbit_blade":
			%OrbitBlades.evolve()
		"aura":
			%Aura.evolve()
		"chain_lightning":
			%ChainLightning.evolve()


## 设置某把法宝的"本场激活技能"。需要消耗一本切换书（swap=false 时不消耗，用于首次选择）
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


## 把法宝的激活技能同步进技能槽（槽位顺序 = 法宝顺序）
func _sync_skill_slots() -> void:
	for i in skill_slots.size():
		if i < weapons.size():
			skill_slots[i] = weapons[i]["active_skill"]
		else:
			skill_slots[i] = ""


## 每斩妖一只怪，给所有携带法宝累积 1 点"斩妖经验"（法宝升级条件之一）。
## 说明：目前不区分"是谁打死的"——所有携带法宝同时累积，简单直观；
## 将来要精确归属，需要在 take_damage 里带上来源法宝 id。
func add_kill_credit() -> void:
	for w in weapons:
		w["kills"] = int(w["kills"]) + 1


func add_material(id: String, amount := 1) -> void:
	materials[id] = int(materials.get(id, 0)) + amount


func material_count(id: String) -> int:
	return int(materials.get(id, 0))


## 法宝升级：材料够 且 斩妖数够 才成功
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
	_apply_weapon_passive(id)
	Audio.play("res://sounds/pickup.wav", false, 1.5, 0.4)
	Juice.pop(self, 1.4, 0.3)
	# 满级即进入进化形态（旧版"第 6 张同名卡进化"已取消）
	if Weapons.is_maxed(def, int(w["level"])):
		_evolve_weapon(id)
		Juice.damage_number(get_parent(), global_position + Vector2(0, -120), "★ 满级进化 ★",
			{"color": Color(1.0, 0.85, 0.3), "scale": 2.0})
	return true


## 宝箱奖励：无视材料与斩妖数，直接给一把已持有法宝 +1 级
func force_upgrade_weapon(id: String) -> bool:
	var w: Dictionary = get_weapon(id)
	if w.is_empty():
		return false
	var def: Dictionary = Weapons.get_def(id)
	if Weapons.is_maxed(def, int(w["level"])):
		return false
	w["level"] = int(w["level"]) + 1
	_apply_weapon_passive(id)
	if Weapons.is_maxed(def, int(w["level"])):
		_evolve_weapon(id)
	Juice.pop(self, 1.4, 0.3)
	return true


## 随机一把**还没满级**的已持有法宝（宝箱用）；都满级或没法宝返回空串
func random_upgradable_weapon() -> String:
	var pool: Array = []
	for w in weapons:
		if not Weapons.is_maxed(Weapons.get_def(w["id"]), int(w["level"])):
			pool.append(w["id"])
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


## 技能槽里某个技能的下标（找不到返回 -1）
func skill_slot_of(skill_id: String) -> int:
	for i in skill_slots.size():
		if skill_slots[i] == skill_id:
			return i
	return -1


## ---------- 技能 ----------

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
			VFX.shockwave(global_position, 210.0, VFX.C_CYAN, 0.3, 6.0)
			VFX.screen_flash(VFX.C_CYAN, 0.10, 0.14)
			_shuriken_burst()
		"blade_storm":
			VFX.spin_slash(global_position, Balance.SKILL_BLADE_RADIUS, VFX.C_CYAN, 6, 0.5)
			VFX.shockwave(global_position, Balance.SKILL_BLADE_RADIUS, VFX.C_WHITE, 0.32, 7.0)
			_hit_all_in_radius(Balance.SKILL_BLADE_RADIUS, Balance.SKILL_BLADE_DAMAGE)
		"sunburst":
			VFX.shockwave(global_position, Balance.SKILL_AURA_RADIUS, VFX.C_GOLD, 0.45, 10.0, true)
			VFX.shockwave(global_position, Balance.SKILL_AURA_RADIUS * 0.6, VFX.C_ORANGE, 0.3, 6.0)
			VFX.burst(global_position, 16, VFX.C_GOLD, 420.0, 0.7, "star", 2.0, 120.0)
			VFX.screen_flash(VFX.C_GOLD, 0.26, 0.26)
			_hit_all_in_radius(Balance.SKILL_AURA_RADIUS, Balance.SKILL_AURA_DAMAGE)
		"thunder":
			VFX.shockwave(global_position, Balance.SKILL_AURA_RADIUS, VFX.C_BLUE, 0.4, 8.0)
			VFX.screen_flash(VFX.C_BLUE, 0.30, 0.22)
			%ChainLightning.cast_ultimate()


## 万剑归宗：以自身为中心放射一圈子弹
func _shuriken_burst() -> void:
	const BULLET = preload("res://bullet_2d.tscn")
	var n: int = Balance.SKILL_SHURIKEN_COUNT
	for i in n:
		var b = BULLET.instantiate()
		b.damage = $Gun.bullet_damage_now() + Balance.SKILL_SHURIKEN_DAMAGE_BONUS
		b.global_position = global_position
		b.rotation = TAU * i / float(n)
		get_parent().add_child(b)
		VFX.trail(b, VFX.C_CYAN, 9.0, 10, 0.16)


## 对半径内所有敌人造成一次伤害（近身爆发类技能共用）
func _hit_all_in_radius(radius: float, damage: int) -> void:
	var hit := 0
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		if global_position.distance_to(mob.global_position) <= radius:
			mob.call_deferred("take_damage", damage)
			# 命中爆点最多画 10 个，避免一次打 40 只怪时刷屏
			if hit < 10:
				VFX.impact(mob.global_position, mob.global_position - global_position, VFX.C_GOLD)
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
	VFX.levelup_burst(global_position)
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
	%HealthBar.value = health


## 任意法宝命中敌人时调用（bullet_2d / orbit_blades），
## 由链式闪电自己判断等级与冷却——没有这张卡时这里等于空操作。
func on_weapon_hit(pos: Vector2, exclude_id := 0) -> void:
	%ChainLightning.on_hit(pos, exclude_id)
