extends Area2D


var travelled_distance = 0
var damage := 1  # 由枪在生成时写入，吃升级加成


func _physics_process(delta):
	position += Vector2.RIGHT.rotated(rotation) * Balance.BULLET_SPEED * delta

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
		body.call_deferred("take_damage", damage)
