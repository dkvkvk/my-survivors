extends Area2D

## 手里剑弹体：外观代码绘制的八角星并自旋（无外部素材依赖）。


var travelled_distance = 0
var damage := 1  # 由枪在生成时写入，吃升级加成
var _star: Sprite2D

@onready var player: CharacterBody2D = get_node("/root/Game/Player")


func _ready():
	_star = Sprite2D.new()
	_star.texture = load("res://assets/ui/icon_shuriken.png")
	add_child(_star)


func _physics_process(delta):
	position += Vector2.RIGHT.rotated(rotation) * Balance.BULLET_SPEED * delta
	_star.rotation += 18.0 * delta

	travelled_distance += Balance.BULLET_SPEED * delta
	if travelled_distance > Balance.BULLET_RANGE:
		queue_free()
	# 防护：坐标异常立即自毁，防止污染物理空间
	if not is_finite(position.x) or not is_finite(position.y):
		queue_free()


func _on_body_entered(body):
	# body_entered 在物理刷新中触发，节点增删必须延迟执行，
	# 否则会破坏物理空间状态（Godot 会报 flushing queries 错误）
	queue_free()
	if body.has_method("take_damage"):
		# 沿弹道方向击退
		var kb := Vector2.RIGHT.rotated(rotation) * Balance.KNOCKBACK_BULLET
		body.call_deferred("take_damage", damage, kb)
		# 命中事件喂给链式闪电（没这张卡时是空操作）
		player.call_deferred("on_weapon_hit", body.global_position, body.get_instance_id())
