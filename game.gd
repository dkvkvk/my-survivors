extends Node2D

var kill_count := 0
var run_time := 0.0

@onready var player = $Player


func _ready():
	player.leveled_up.connect(_on_player_leveled_up)


func _process(delta):
	run_time += delta
	%TimeLabel.text = "存活 %d:%02d" % [int(run_time) / 60, int(run_time) % 60]
	%XPBar.max_value = player.xp_to_next
	%XPBar.value = player.xp
	%LevelLabel.text = "Lv %d" % player.level


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
	# 每次刷怪后按存活时间调整下一次间隔（难度曲线）
	$Timer.wait_time = Balance.spawn_interval(run_time)


func _on_player_leveled_up():
	%LevelUpUI.present(player)


func _on_player_health_depleted():
	Audio.play("res://sounds/game-over.wav", false, 1.0, 0.5)
	%GameOver.show()
	get_tree().paused = true
