extends Area2D

## 材料 / 切换书掉落物（P6）：复用灵石的磁吸拾取手感。
## kind = "material"（带 material_id）或 "book"（神通残卷）。
## 图标缺失时用代码画的菱形占位（材料=蓝绿，书=金）。

var kind := "material"
var material_id := "scrap"
var _t := 0.0
var _sprite: Sprite2D
var _player: Node
var magnet_speed := 0.0

@onready var game: Node = get_node("/root/Game")


func _ready():
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)

	var icon := _icon_path()
	_sprite = Sprite2D.new()
	if icon != "" and ResourceLoader.exists(icon):
		_sprite.texture = load(icon)
		_sprite.scale = Vector2.ONE * 1.5
		VFX.drop_halo(_sprite)
	else:
		_sprite.texture = null
	add_child(_sprite)

	if _sprite.texture == null:
		# 占位：材料=蓝绿菱形，书=金色菱形
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(0, -13), Vector2(11, 0), Vector2(0, 13), Vector2(-11, 0),
		])
		poly.color = Color(0.5, 1.0, 0.85) if kind == "material" else Color(1.0, 0.85, 0.35)
		add_child(poly)

	_player = get_node_or_null("/root/Game/Player")
	VFX.drop_spawn_for(self, VFX.C_GOLD if kind == "book" else VFX.C_GREEN)
	Juice.pop(self, 1.3)
	body_entered.connect(_on_body_entered)


func _icon_path() -> String:
	if kind == "book":
		return "res://assets/ui/icon_skill_book.png"
	var m: Dictionary = Weapons.MATERIALS.get(material_id, {})
	return m.get("icon", "")


func setup(p_kind: String, p_material := "scrap") -> void:
	kind = p_kind
	material_id = p_material


func _process(delta: float) -> void:
	_t += delta
	# 呼吸，掉在地上更醒目
	if _sprite.texture != null:
		_sprite.scale = Vector2.ONE * 1.1 * (1.0 + 0.10 * sin(_t * 4.0))
	else:
		scale = Vector2.ONE * (1.0 + 0.10 * sin(_t * 4.0))


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var to_player: Vector2 = _player.global_position - global_position
	if to_player.length() < _player.pickup_radius:
		magnet_speed = maxf(magnet_speed + 1400.0 * delta, 400.0)
		position += to_player.normalized() * magnet_speed * delta
	else:
		position += to_player.limit_length(1.0) * Balance.GEM_DRIFT_SPEED * delta


func _on_body_entered(body: Node) -> void:
	if body != _player:
		return
	VFX.pickup_pop(global_position, VFX.C_GOLD if kind == "book" else VFX.C_GREEN)
	queue_free()
	if kind == "book":
		_player.skill_books += 1
		Audio.play("res://sounds/pickup.wav", false, 1.7, 0.35)
	else:
		_player.add_material(material_id, 1)
		Audio.play("res://sounds/pickup.wav", false, randf_range(1.2, 1.5), 0.25)
