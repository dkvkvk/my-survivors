extends Area2D


var travelled_distance = 0


func _physics_process(delta):
	position += Vector2.RIGHT.rotated(rotation) * Balance.BULLET_SPEED * delta

	travelled_distance += Balance.BULLET_SPEED * delta
	if travelled_distance > Balance.BULLET_RANGE:
		queue_free()


func _on_body_entered(body):
	queue_free()
	if body.has_method("take_damage"):
		body.take_damage()
