extends CharacterBody2D

signal died

var variant := "slime"
var speed := 250.0
var health := 2
var xp_value := 1
var contact_damage := 1.0  # 玩家受击倍率，见 player.gd
# 每只怪锁定玩家周围一个随机偏移点 + 随机停止距离，
# 让怪物围成松散的一圈而不是叠进玩家坐标（软分离，不开物理互撞）
var attack_range := randf_range(22.0, 36.0)
var approach_offset := Vector2.from_angle(randf() * TAU) * randf_range(6.0, 26.0)
# 受击击退的当前速度（px/s），每帧摩擦衰减，数值见 balance.gd 的 KNOCKBACK_*
var _knockback := Vector2.ZERO

# 首领模式（P4）：三段循环 AI + 头顶血条 + 击退抗性
var is_boss := false
var _charge_state := 0  # 0=追击 1=蓄力 2=冲锋
var _charge_timer := 0.0
var _charge_dir := Vector2.ZERO

@onready var player: CharacterBody2D = get_node("/root/Game/Player")
# 受击/接触判定圆：随变体体型缩放，保证"看得见的身体才打得到"
@onready var _body_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	# 供链式闪电等 AoE 武器快速索敌
	add_to_group("mobs")
	%Slime.play_walk()


## 把精灵"脚底"对齐到判定圆心（y=0）。
## 素材高矮不一（史莱姆 24px、首领 32px，还各自乘变体缩放），
## 用固定偏移会让大个子悬空、小个子陷地，所以按实际贴图高度算。
func _ground_sprite() -> void:
	var tex: Texture2D = %Slime.sprite_frames.get_frame_texture(%Slime.animation, 0)
	if tex == null:
		return
	var tex_h: float = float(tex.get_height())
	# 贴图脚底相对精灵中心的偏移（正 = 偏上）
	var foot_off: float = (%Slime.offset.y + tex_h / 2.0) * scale.y
	%Slime.position.y = -foot_off
	# 头顶血条跟着个子走
	%BossBar.offset_top = -foot_off - tex_h * scale.y - 12.0
	%BossBar.offset_bottom = %BossBar.offset_top + 16.0


## 设置判定圆半径。必须 duplicate：mob.tscn 里 CircleShape2D 是共享资源，
## 直接改 radius 会让所有怪一起变（后生成的覆盖先生成的）。
func _set_hit_radius(r: float) -> void:
	var circle: CircleShape2D = _body_shape.shape.duplicate()
	circle.radius = r
	_body_shape.shape = circle


## 按变体名应用属性（数值定义在 balance.gd 的 MOB_VARIANTS）
func setup(variant_name: String) -> void:
	variant = variant_name
	var def: Dictionary = Balance.MOB_VARIANTS[variant_name]
	health = def["hp"]
	speed = randf_range(def["speed"][0], def["speed"][1])
	xp_value = def["xp"]
	contact_damage = def["contact"]
	scale = Vector2.ONE * def["scale"]
	# 碰撞圆按"身体"尺寸给，不跟整张精灵缩放：
	# 新素材很宽（蝙蝠展翼 54px、野兽 48px），若按包围盒缩放，
	# 判定圆会比看得见的身体大一圈——"没碰到却掉血"。
	_body_shape.scale = Vector2.ONE
	_set_hit_radius(def.get("hit_radius", 40.0))
	%Slime.modulate = def["color"]
	%Slime.set_variant(def["sprites"])
	_ground_sprite()


## 升格为首领（P4）：属性覆盖 + 头顶血条。hp_bonus 为按击杀数递增的血量。
func setup_boss(hp_bonus: int) -> void:
	is_boss = true
	setup("tank")  # 回退贴图：重甲兵放大染色
	health = Balance.BOSS_BASE_HP + hp_bonus
	speed = Balance.BOSS_SPEED
	xp_value = Balance.BOSS_XP
	contact_damage = Balance.BOSS_CONTACT
	scale = Vector2.ONE * Balance.BOSS_SCALE
	_body_shape.scale = Vector2.ONE
	_set_hit_radius(Balance.BOSS_HIT_RADIUS)
	%Slime.modulate = Balance.BOSS_COLOR
	if ResourceLoader.exists(Balance.BOSS_SPRITES[0]):
		var paths: Array = Balance.BOSS_SPRITES
		%Slime.set_variant(paths)
		%Slime.modulate = Color(1, 1, 1)
	_ground_sprite()
	_charge_timer = Balance.BOSS_CHARGE_PHASE["chase"]
	%BossBar.max_value = health
	%BossBar.value = health
	%BossBar.show()


func _physics_process(delta):
	# 防护：坐标一旦非有限值（物理求解器极端情况的自愈），传回战场随机点
	if not is_finite(global_position.x) or not is_finite(global_position.y):
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 600.0
		velocity = Vector2.ZERO
		return

	if is_boss:
		_boss_ai(delta)
	else:
		var to_target := (player.global_position + approach_offset) - global_position
		var dist := to_target.length()
		if is_finite(dist) and dist > attack_range:
			velocity = to_target.normalized() * speed
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	# 击退位移叠加在行走之上，指数式衰减回正
	position += _knockback * delta
	_knockback = _knockback.move_toward(Vector2.ZERO, Balance.KNOCKBACK_FRICTION * delta)


## 首领三段循环：追击 → 蓄力（闪白预示）→ 直线冲锋
func _boss_ai(delta):
	_charge_timer -= delta
	match _charge_state:
		0:
			var to_player := player.global_position - global_position
			velocity = to_player.limit_length(1.0) * speed
			if _charge_timer <= 0.0:
				_charge_state = 1
				_charge_timer = Balance.BOSS_CHARGE_PHASE["windup"]
				Juice.flash(%Slime, Color(3.5, 2.5, 0.8), 0.55)
		1:
			velocity = Vector2.ZERO
			if _charge_timer <= 0.0:
				_charge_state = 2
				_charge_timer = Balance.BOSS_CHARGE_PHASE["dash"]
				_charge_dir = (player.global_position - global_position).normalized()
				Audio.play("res://sounds/hurt.wav", false, 0.7, 0.15)
		2:
			velocity = _charge_dir * speed * Balance.BOSS_CHARGE_SPEED_MULT
			if _charge_timer <= 0.0:
				_charge_state = 0
				_charge_timer = Balance.BOSS_CHARGE_PHASE["chase"]


func take_damage(amount := 1, knockback := Vector2.ZERO):
	%Slime.play_hurt()
	Audio.play("res://sounds/hit.wav", false, randf_range(0.9, 1.1), 0.3)
	Juice.flash(%Slime)
	Juice.damage_number(get_parent(), global_position + Vector2(0, -48), amount)
	health -= amount
	if is_boss:
		knockback *= Balance.BOSS_KNOCKBACK_RESIST
		%BossBar.value = maxf(health, 0.0)
	_knockback += knockback
	if _knockback.length() > Balance.KNOCKBACK_MAX:
		_knockback = _knockback.normalized() * Balance.KNOCKBACK_MAX

	# 注意用 <=：升伤害卡后可能一枪从 1 血打到 -1，用 == 判断会永远杀不死
	if health <= 0:
		died.emit()
		Audio.play("res://sounds/enemy-die.wav", true, randf_range(0.9, 1.1), 0.15)
		Juice.shake(player.get_node("Camera2D"), 0.35)
		Juice.hitstop(0.05)
		drop_xp_gem()
		drop_coins()
		drop_weapon()
		drop_materials()
		if is_boss:
			drop_chest()
		_burst_debris()
		var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = smoke_scene.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		queue_free()


func drop_xp_gem():
	var gem = preload("res://xp_gem.tscn").instantiate()
	gem.value = xp_value
	if xp_value >= 5:
		gem.scale = Vector2(1.3, 1.3)  # 大额经验宝石更大只
	get_parent().add_child(gem)
	gem.global_position = global_position


## 按变体概率掉金币（P2 局外经济），散落成小圈避免叠成一枚
func drop_coins():
	var drop: Dictionary = Balance.COIN_DROPS[variant]
	if randf() > drop["chance"]:
		return
	for i in int(drop["amount"]):
		var coin = preload("res://coin.tscn").instantiate()
		get_parent().add_child(coin)
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(4.0, 20.0)
		coin.global_position = global_position + offset


## 首领死亡必掉宝箱（P4）
## 材料与切换书掉落（P6）：材料按概率掉，切换书稀有。
## 首领一次给较多材料。
func drop_materials() -> void:
	# 铁屑：常见
	if is_boss or randf() < Balance.MATERIAL_DROP_CHANCE:
		var n: int = 4 if is_boss else 1
		for i in n:
			_drop_pickup("material", "scrap")
	# 雷晶：稀有（首领必给）
	if is_boss or randf() < Balance.CRYSTAL_DROP_CHANCE:
		_drop_pickup("material", "crystal")
	# 技能切换书：很稀有
	if randf() < Balance.SKILL_BOOK_DROP_CHANCE:
		_drop_pickup("book", "")


func _drop_pickup(kind: String, mat: String) -> void:
	var p = preload("res://pickup_drop.tscn").instantiate()
	get_parent().add_child(p)
	p.global_position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 22.0)
	p.setup(kind, mat)


## 武器掉落（P6）：普通怪小概率，首领必掉。地上生成 weapon_drop，走近按 F 拾取。
func drop_weapon() -> void:
	var chance: float = 1.0 if is_boss else Balance.WEAPON_DROP_CHANCE
	if randf() > chance:
		return
	var ids: Array = []
	for w in Weapons.LIST:
		ids.append(w["id"])
	var drop = preload("res://weapon_drop.tscn").instantiate()
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
	drop.setup(ids[randi() % ids.size()])


func drop_chest():
	var chest = preload("res://chest.tscn").instantiate()
	get_parent().add_child(chest)
	chest.global_position = global_position


## 死亡时爆一圈同色碎片（一次性粒子，纯代码创建，播完自毁）
func _burst_debris():
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 12
	burst.lifetime = 0.45
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.gravity = Vector2(0, 700)
	burst.initial_velocity_min = 120.0
	burst.initial_velocity_max = 280.0
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 3.0
	burst.color = %Slime.modulate
	burst.finished.connect(burst.queue_free)
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
