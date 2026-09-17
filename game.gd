extends Node2D

var kill_count := 0
var run_time := 0.0


func _ready():
	$Timer.wait_time = Balance.SPAWN_INTERVAL


func _process(delta):
	run_time += delta
	%TimeLabel.text = "存活 %d:%02d" % [int(run_time) / 60, int(run_time) % 60]


func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.global_position = %PathFollow2D.global_position
	new_mob.died.connect(_on_mob_died)
	add_child(new_mob)


func _on_mob_died():
	kill_count += 1
	%KillLabel.text = "击杀 %d" % kill_count


func _on_timer_timeout():
	spawn_mob()


func _on_player_health_depleted():
	Audio.play("res://sounds/game-over.wav", false, 1.0, 0.5)
	%GameOver.show()
	get_tree().paused = true
