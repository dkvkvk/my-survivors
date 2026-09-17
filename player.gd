extends CharacterBody2D

signal health_depleted

var health = Balance.PLAYER_MAX_HEALTH

# 受伤音效节流：被怪围着时每 0.6 秒最多响一次，不然太吵
var hurt_sound_cooldown := 0.0


func _physics_process(delta):
	hurt_sound_cooldown = maxf(0.0, hurt_sound_cooldown - delta)

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * Balance.PLAYER_SPEED

	move_and_slide()

	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()

	# Taking damage
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		health -= Balance.PLAYER_DAMAGE_RATE * overlapping_mobs.size() * delta
		%HealthBar.value = health
		if hurt_sound_cooldown <= 0.0:
			Audio.play("res://sounds/hurt.wav", false, 1.0, 0.35)
			hurt_sound_cooldown = 0.6
		if health <= 0.0:
			health_depleted.emit()
