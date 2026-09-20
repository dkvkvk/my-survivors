extends Node2D

var kill_count := 0
var run_time := 0.0
var run_coins := 0  # 本局拾取的金币，死亡时结算入存档余额
var current_wave: Dictionary = Balance.WAVES[0]
var boss_kill_count := 0  # 击杀首领数，决定下一只的血量
var _boss_timer := 0.0

@onready var player = $Player

# 分块地图（chunk_map.gd）：预设计小地图随机拼接，碰撞挂在瓦片上。
# 看得见的墙才撞得上，从根源消灭空气墙。
var _chunk_map: Node2D


func _ready():
	Audio.play_music("res://sounds/bgm_battle.wav")
	player.leveled_up.connect(_on_player_leveled_up)
	_chunk_map = preload("res://chunk_map.gd").new()
	add_child(_chunk_map)
	_boss_timer = Balance.BOSS_FIRST_DELAY  # 首领倒计时（P4）


func _process(delta):
	run_time += delta
	%TimeLabel.text = "存活 %d:%02d" % [int(run_time) / 60, int(run_time) % 60]
	%XPBar.max_value = player.xp_to_next
	%XPBar.value = player.xp
	%LevelLabel.text = "Lv %d" % player.level
	# 无限草地：地面按贴图尺寸的整数倍跟随玩家，花纹无缝衔接
	$Ground.global_position = player.global_position.snapped(Vector2(1024, 1024))
	# 环境光尘：发射区跟随玩家，粒子本体留在世界坐标，走动时视野内始终有浮尘
	$Ambient.global_position = player.global_position
	# 低血量警告：低于 30% 出现红色脉冲，血量越低越急促
	var hp_ratio: float = player.health / player.max_health
	if hp_ratio < 0.3 and hp_ratio > 0.0:
		var urgency: float = (0.3 - hp_ratio) / 0.3
		%LowHpWarning.color.a = urgency * (0.14 + 0.12 * absf(sin(Time.get_ticks_msec() / (160.0 - 60.0 * urgency))))
	else:
		%LowHpWarning.color.a = 0.0
	# 首领倒计时（P4）：到点且上一只已被击杀才刷新
	if _boss_timer > 0.0:
		_boss_timer -= delta
		if _boss_timer <= 0.0:
			_spawn_boss()


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


## 金币拾取入口（coin.gd 延迟调用）
func add_run_coins(amount: int) -> void:
	run_coins += amount
	%CoinLabel.text = "金币 %d" % run_coins


## 刷新一只首领（P4）：血量随击杀数递增，三段冲锋 AI，死后掉宝箱
func _spawn_boss() -> void:
	%PathFollow2D.progress_ratio = randf()
	var boss = preload("res://mob.tscn").instantiate()
	boss.global_position = %PathFollow2D.global_position
	add_child(boss)
	boss.setup_boss(boss_kill_count * Balance.BOSS_HP_PER_KILL)
	boss.died.connect(_on_boss_died)
	_show_boss_warn()


func _on_boss_died() -> void:
	boss_kill_count += 1
	_boss_timer = Balance.BOSS_INTERVAL  # 下一只开始倒计时


func _show_boss_warn() -> void:
	Audio.play("res://sounds/game-over.wav", false, 1.4, 0.3)
	%BossWarnLabel.modulate.a = 1.0
	%BossWarnLabel.show()
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(%BossWarnLabel, "modulate:a", 0.0, 0.8)


func _on_player_leveled_up():
	%LevelUpUI.present(player)


func _on_player_health_depleted():
	Audio.play("res://sounds/game-over.wav", false, 1.0, 0.5)
	%GameOver.show_results(kill_count, run_time, player.level, run_coins)
	get_tree().paused = true
