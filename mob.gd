extends CharacterBody2D

signal died


var speed = randf_range(Balance.MOB_MIN_SPEED, Balance.MOB_MAX_SPEED)
var health = Balance.MOB_HEALTH

@onready var player = get_node("/root/Game/Player")


func _ready():
	%Slime.play_walk()


func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()


func take_damage(amount := 1):
	%Slime.play_hurt()
	Audio.play("res://sounds/hit.wav", false, randf_range(0.9, 1.1), 0.3)
	Juice.flash(%Slime)
	Juice.damage_number(get_parent(), global_position + Vector2(0, -48), amount)
	health -= amount

	if health == 0:
		died.emit()
		Audio.play("res://sounds/enemy-die.wav", true, randf_range(0.9, 1.1), 0.15)
		Juice.shake(player.get_node("Camera2D"), 0.35)
		Juice.hitstop(0.05)
		drop_xp_gem()
		var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = smoke_scene.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		queue_free()


func drop_xp_gem():
	var gem = preload("res://xp_gem.tscn").instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position
