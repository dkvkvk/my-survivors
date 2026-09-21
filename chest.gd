extends Area2D

## 宝箱（P4）：首领必掉，走过去开启，随机奖励——
##   材料礼包 / 免材料免击杀直接给一把已持有武器 +1 级 / 金币。
## 外观代码绘制：棕木箱 + 金边 + 锁扣，带轻微浮动。


@onready var player: CharacterBody2D = get_node("/root/Game/Player")
@onready var game: Node2D = get_node("/root/Game")

var _t := 0.0


func _ready():
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/ui/icon_chest.png")
	sprite.scale = Vector2.ONE * 1.5
	add_child(sprite)
	Juice.pop(self, 1.4)


func _process(delta):
	_t += delta
	# 轻微上下浮动，提示可拾取
	position.y += sin(_t * 3.0) * 4.0 * delta


func _on_body_entered(body):
	if body != player:
		return
	queue_free()
	Audio.play("res://sounds/pickup.wav", false, 1.0, 0.35)
	var roll := randf()
	if roll < Balance.CHEST_MATERIAL_CHANCE:
		_give_materials()
	elif roll < Balance.CHEST_MATERIAL_CHANCE + Balance.CHEST_FREE_UPGRADE_CHANCE and _give_free_upgrade():
		pass
	else:
		_give_coins()


func _give_materials() -> void:
	player.add_material("scrap", Balance.CHEST_SCRAP_AMOUNT)
	player.add_material("crystal", Balance.CHEST_CRYSTAL_AMOUNT)
	_float("宝箱：%s x%d  %s x%d" % [
		Weapons.material_name("scrap"), Balance.CHEST_SCRAP_AMOUNT,
		Weapons.material_name("crystal"), Balance.CHEST_CRYSTAL_AMOUNT,
	], Color(0.6, 1.0, 0.85))


## 免材料免击杀直接升级；已全满级时返回 false（上层回退成金币）
func _give_free_upgrade() -> bool:
	var id: String = player.random_upgradable_weapon()
	if id == "" or not player.force_upgrade_weapon(id):
		return false
	_float("宝箱：%s 升级！" % Weapons.get_def(id).get("name", id), Color(1.0, 0.85, 0.3))
	return true


func _give_coins() -> void:
	var coins := randi_range(Balance.CHEST_COIN_MIN, Balance.CHEST_COIN_MAX)
	game.call_deferred("add_run_coins", coins)
	_float("宝箱：金币 +%d" % coins, Color(1.0, 0.85, 0.3))


func _float(msg: String, color: Color) -> void:
	Juice.damage_number(game, global_position + Vector2(0, -60), msg, {"color": color, "scale": 1.5})
