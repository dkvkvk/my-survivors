extends Area2D

## 法宝掉落物（P6）：怪死后按概率掉出，走近显示提示，**按 F 拾取**。
## 法宝位已满时弹替换面板（可选替换或放弃）；不相关的法宝留在原地。
## 外观：图标缺失时用代码画的菱形 + 呼吸光晕（不依赖美术）。

signal picked_up(weapon_id: String)

var weapon_id := ""
var _t := 0.0
var _hint: Label
var _sprite: Sprite2D
var _glow: Sprite2D
var _beam: Sprite2D
var _player: Node

@onready var game: Node = get_node("/root/Game")


func _ready():
	add_to_group("weapon_drops")
	collision_layer = 0
	collision_mask = 1          # 只关心玩家靠近
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 110.0       # 走近提示范围（原来 70 太小，掉落变多后容易漏捡）
	shape.shape = circle
	add_child(shape)

	# 图标（没有美术时用代码画的菱形占位）
	var icon_path := "res://assets/ui/icon_weapon_drop.png"
	if ResourceLoader.exists(icon_path):
		_sprite = Sprite2D.new()
		_sprite.texture = load(icon_path)
		_sprite.scale = Vector2.ONE * 1.8
		add_child(_sprite)
		VFX.drop_halo(_sprite)
		# 光柱：法宝稀有且要按 F 捡，远处也要一眼看到
		_beam = Sprite2D.new()
		_beam.texture = load("res://assets/fx/glow_64.png")
		_beam.scale = Vector2(0.85, 4.6)
		_beam.modulate = Color(0.4, 1.0, 1.0, 0.22)
		_beam.z_index = -1
		add_child(_beam)
	else:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(0, -16), Vector2(13, 0), Vector2(0, 16), Vector2(-13, 0),
		])
		poly.color = Color(0.45, 0.95, 1.0, 0.95)
		add_child(poly)
		_sprite = null

	_glow = Sprite2D.new()
	if _sprite != null:
		_glow.texture = _sprite.texture
		_glow.scale = Vector2.ONE * 2.6
	else:
		_glow.texture = null
	_glow.modulate = Color(0.4, 1.0, 1.0, 0.3)
	_glow.show_behind_parent = true
	add_child(_glow)

	_hint = Label.new()
	_hint.text = "F 拾取"
	_hint.position = Vector2(-44, -58)
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.hide()
	add_child(_hint)

	_player = get_node_or_null("/root/Game/Player")
	VFX.drop_spawn_for(self, VFX.C_CYAN)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func setup(id: String) -> void:
	weapon_id = id


func _process(delta: float) -> void:
	_t += delta
	# 呼吸 + 轻微上下浮动，掉在地上更容易被注意到
	var k: float = 1.0 + 0.10 * sin(_t * 3.5)
	if _sprite != null:
		_sprite.scale = Vector2.ONE * 1.4 * k
	position.y += sin(_t * 2.2) * 6.0 * delta
	if _glow.texture != null:
		_glow.modulate.a = 0.20 + 0.18 * (0.5 + 0.5 * sin(_t * 3.5))
	if _beam != null:
		_beam.modulate.a = 0.16 + 0.14 * (0.5 + 0.5 * sin(_t * 2.2))
	# 走近时按 F 拾取
	if _hint.visible and Input.is_action_just_pressed("pickup"):
		_try_pickup()


func _on_body_entered(body: Node) -> void:
	if body == _player:
		_hint.show()


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_hint.hide()


func _try_pickup() -> void:
	if _player == null or weapon_id == "":
		return
	# 已经拥有 → 转成升级材料
	if _player.has_weapon(weapon_id):
		var def: Dictionary = Weapons.get_def(weapon_id)
		VFX.pickup_pop(global_position, VFX.C_CYAN)
		_player.add_material(def.get("upgrade_material", "scrap"), 2)
		Audio.play("res://sounds/pickup.wav", false, 1.5, 0.35)
		_float_text("+2 " + Weapons.material_name(def.get("upgrade_material", "scrap")))
		queue_free()
		return
	# 有空格 → 直接拿走
	if _player.add_weapon(weapon_id):
		VFX.levelup_burst(global_position, VFX.C_CYAN)
		Audio.play("res://sounds/pickup.wav", false, 1.4, 0.4)
		_float_text("得法宝 · " + Weapons.get_def(weapon_id).get("name", weapon_id))
		queue_free()
		return
	# 位子满了 → 弹替换面板
	var ui: Node = game.get_node_or_null("InventoryUI")
	if ui != null and ui.has_method("ask_replace"):
		_hint.hide()
		ui.ask_replace(weapon_id, self)
	else:
		_float_text("法宝已满")


func _float_text(msg: String) -> void:
	Juice.damage_number(game, global_position + Vector2(0, -50), msg, {"color": Color(0.7, 1.0, 1.0), "scale": 1.2})


## 替换面板取消时调用：把提示重新显示出来
func cancel_replace() -> void:
	if _player != null and global_position.distance_to(_player.global_position) < 90.0:
		_hint.show()
