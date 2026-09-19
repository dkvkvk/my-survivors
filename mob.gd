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

@onready var player: CharacterBody2D = get_node("/root/Game/Player")


func _ready():
	%Slime.play_walk()


## 按变体名应用属性（数值定义在 balance.gd 的 MOB_VARIANTS）
func setup(variant_name: String) -> void:
	variant = variant_name
	var def: Dictionary = Balance.MOB_VARIANTS[variant_name]
	health = def["hp"]
	speed = randf_range(def["speed"][0], def["speed"][1])
	xp_value = def["xp"]
	contact_damage = def["contact"]
	scale = Vector2.ONE * def["scale"]
	%Slime.modulate = def["color"]
	%Slime.set_variant(def["sprites"])


func _physics_process(delta):
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
	# 击退位移叠加在行走之上，指数式衰减回正
	position += _knockback * delta
	_knockback = _knockback.move_toward(Vector2.ZERO, Balance.KNOCKBACK_FRICTION * delta)


func take_damage(amount := 1, knockback := Vector2.ZERO):
	%Slime.play_hurt()
	Audio.play("res://sounds/hit.wav", false, randf_range(0.9, 1.1), 0.3)
	Juice.flash(%Slime)
	Juice.damage_number(get_parent(), global_position + Vector2(0, -48), amount)
	health -= amount
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
