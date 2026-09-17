extends Node2D

var kill_count := 0
var run_time := 0.0
var current_wave: Dictionary = Balance.WAVES[0]

@onready var player = $Player


func _ready():
	player.leveled_up.connect(_on_player_leveled_up)


func _process(delta):
	run_time += delta
	%TimeLabel.text = "存活 %d:%02d" % [int(run_time) / 60, int(run_time) % 60]
	%XPBar.max_value = player.xp_to_next
	%XPBar.value = player.xp
	%LevelLabel.text = "Lv %d" % player.level
	# 无限草地：地面按贴图尺寸的整数倍跟随玩家，花纹无缝衔接
	$Ground.global_position = player.global_position.snapped(Vector2(1024, 1024))


func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
	new_mob.setup(Balance.pick_variant(current_wave))
	new_mob.died.connect(_on_mob_died)


func _on_timer_timeout():
	spawn_mob()
	# 每次刷怪后按存活时间刷新波次（难度与怪物组合）
	current_wave = Balance.current_wave(run_time)
	$Timer.wait_time = current_wave["spawn"]


func _on_mob_died():
	kill_count += 1
	%KillLabel.text = "击杀 %d" % kill_count


func _on_player_leveled_up():
	%LevelUpUI.present(player)


func _on_player_health_depleted():
	Audio.play("res://sounds/game-over.wav", false, 1.0, 0.5)
	%GameOver.show()
	get_tree().paused = true
