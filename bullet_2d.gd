extends Area2D

## 手里剑弹体：外观代码绘制的八角星并自旋（无外部素材依赖）。


var travelled_distance = 0
var damage := 1  # 由枪在生成时写入，吃升级加成
var _star: Polygon2D


func _ready():
	_star = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var r := 9.0 if i % 2 == 0 else 4.0
		pts.append(Vector2.RIGHT.rotated(TAU * i / 8.0) * r)
	_star.polygon = pts
	_star.color = Color(0.85, 0.88, 0.95)
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
