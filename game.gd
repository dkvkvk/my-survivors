extends Node2D

var kill_count := 0
var run_time := 0.0
var run_coins := 0  # 本局拾取的灵石，死亡时结算入存档余额
var current_wave: Dictionary = Balance.WAVES[0]
var boss_kill_count := 0  # 斩妖妖王数，决定下一只的血量
var weapon_drops := 0     # 已掉出的法宝数（开局保底用，见 weapon_pity_ready）
var _boss_timer := 0.0
var _run_ended := false  # 已结算（胜利或失败），防止重复触发

# 手感探针（开发用，见 HANDOVER §3）：MS_FEEL_PROBE=1 时统计相机抖动与定帧冻结比例
var _probe_n := 0
var _probe_sum := 0.0
var _probe_max := 0.0
var _probe_over4 := 0
var _probe_over10 := 0
var _probe_frozen := 0
var _probe_fps_sum := 0.0
var _probe_fps_min := 0.0

@onready var player = $Player

# 分块地图（chunk_map.gd）：预设计小地图随机拼接，碰撞挂在瓦片上。
# 看得见的墙才撞得上，从根源消灭空气墙。
var _chunk_map: Node2D


func _ready():
	Audio.play_music("res://sounds/bgm_battle.wav")
	# 占位文字可能与 balance.gd 脱节（改胜利线时漏改场景）——启动即按常量刷一遍
	%BossProgressLabel.text = "妖王 0/%d" % Balance.VICTORY_BOSS_KILLS
	player.leveled_up.connect(_on_player_leveled_up)
	_chunk_map = preload("res://chunk_map.gd").new()
	add_child(_chunk_map)
	# 触屏操作（P2b）：只有真有触摸时才存在，桌面键鼠下自毁（不抢输入）
	add_child(preload("res://touch_controls.gd").new())
	_boss_timer = Balance.BOSS_FIRST_DELAY  # 妖王倒计时（P4）
	# 开局选法宝（P6）：弹 4 张卡并暂停游戏，选完才正式开打
	%StartSelectUI.call_deferred("open", player)


func _process(delta):
	run_time += delta
	# 守夜时间 + 距胜利倒计时（P5）
	var left: float = maxf(0.0, Balance.SURVIVE_WIN_TIME - run_time)
	%TimeLabel.text = "守夜 %d:%02d　｜　黎明 %d:%02d" % [
		int(run_time) / 60, int(run_time) % 60,
		int(left) / 60, int(left) % 60,
	]
	%BossProgressLabel.text = "妖王 %d/%d" % [boss_kill_count, Balance.VICTORY_BOSS_KILLS]
	%XPBar.max_value = player.xp_to_next
	%XPBar.value = player.xp
	%LevelLabel.text = "修为 %d" % player.level
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
	# 妖王倒计时（P4）：到点且上一只已被斩妖才刷新
	if _boss_timer > 0.0:
		_boss_timer -= delta
		if _boss_timer <= 0.0:
			_spawn_boss()
	# 胜利条件（P5）：活满时长 或 打满妖王数，任一达成即胜利
	if not _run_ended:
		if run_time >= Balance.SURVIVE_WIN_TIME:
			_win("time")
		elif boss_kill_count >= Balance.VICTORY_BOSS_KILLS:
			_win("boss")
	if OS.get_environment("MS_FEEL_PROBE") == "1":
		_feel_probe()


## 手感探针（开发用）：每 120 帧汇报一次"相机抖动强度分布 + 定帧冻结比例"。
## 调抖动/hitstop 时用它对比前后，别靠感觉（见 HANDOVER §3）。
func _feel_probe() -> void:
	var cam = player.get_node_or_null("Camera2D")
	if cam == null:
		return
	_probe_n += 1
	var off: float = cam.offset.length()
	_probe_sum += off
	_probe_max = maxf(_probe_max, off)
	if _probe_fps_min <= 0.0 or Engine.get_frames_per_second() < _probe_fps_min:
		_probe_fps_min = Engine.get_frames_per_second()
	_probe_fps_sum += Engine.get_frames_per_second()
	if off > 4.0:
		_probe_over4 += 1
	if off > 10.0:
		_probe_over10 += 1
	if Engine.time_scale < 1.0:
		_probe_frozen += 1
	if _probe_n % 120 == 0:
		print("FEELSTAT frames=%d mean=%.2f max=%.2f over4=%.0f%% over10=%.0f%% frozen=%.0f%% mobs=%d fps=%.0f(min %.0f) fx=%d" % [
			_probe_n, _probe_sum / float(_probe_n), _probe_max,
			100.0 * float(_probe_over4) / float(_probe_n),
			100.0 * float(_probe_over10) / float(_probe_n),
			100.0 * float(_probe_frozen) / float(_probe_n),
			get_tree().get_nodes_in_group("mobs").size(),
			_probe_fps_sum / float(_probe_n), _probe_fps_min,
			get_tree().get_nodes_in_group("fx").size()])
		_probe_n = 0
		_probe_sum = 0.0
		_probe_max = 0.0
		_probe_over4 = 0
		_probe_over10 = 0
		_probe_frozen = 0
		_probe_fps_sum = 0.0
		_probe_fps_min = 0.0


## 开局保底判定：前 WEAPON_PITY_TIME 秒内，每攒够 WEAPON_PITY_KILLS 次斩妖还没掉够法宝就返回 true
func weapon_pity_ready() -> bool:
	if run_time > Balance.WEAPON_PITY_TIME:
		return false
	if weapon_drops >= Balance.WEAPON_PITY_MAX:
		return false
	return kill_count >= (weapon_drops + 1) * Balance.WEAPON_PITY_KILLS


func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
	new_mob.setup(Balance.pick_variant(current_wave))
	new_mob.died.connect(_on_mob_died)


func _on_timer_timeout():
	spawn_mob()
	# 每次刷怪后按守夜时间刷新更次（难度与怪物组合）
	current_wave = Balance.current_wave(run_time)
	$Timer.wait_time = current_wave["spawn"]


func _on_mob_died(source: String) -> void:
	kill_count += 1
	%KillLabel.text = "斩妖 %d" % kill_count
	# 法宝升级条件之一：斩妖数累积（P6），只记给致命一击的法宝
	player.add_kill_credit(source)


## 灵石拾取入口（coin.gd 延迟调用）
func add_run_coins(amount: int) -> void:
	run_coins += amount
	%CoinLabel.text = "灵石 %d" % run_coins


## 刷新一只妖王（P4）：血量随斩妖数递增，三段冲锋 AI，死后掉宝箱
func _spawn_boss() -> void:
	%PathFollow2D.progress_ratio = randf()
	var boss = preload("res://mob.tscn").instantiate()
	boss.global_position = %PathFollow2D.global_position
	add_child(boss)
	boss.setup_boss(boss_kill_count * Balance.BOSS_HP_PER_KILL)
	boss.died.connect(_on_boss_died)
	_show_boss_warn()


func _on_boss_died(_source: String) -> void:
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
	if _run_ended:
		return
	_run_ended = true
	Audio.play("res://sounds/game-over.wav", false, 1.0, 0.5)
	# 结算时收起 HUD：斩妖/时间/血条/蓝条/技能栏不该压在结算界面上面
	$HUD.hide()
	%GameOver.show_results(kill_count, run_time, player.level, run_coins)
	get_tree().paused = true


## 胜利结算（P5）：reason = "time"（活满）或 "boss"（打满妖王数）
func _win(reason: String) -> void:
	_run_ended = true
	Audio.play("res://sounds/pickup.wav", false, 1.0, 0.6)
	Audio.play("res://sounds/game-over.wav", false, 1.3, 0.3)
	$HUD.hide()
	%VictoryUI.show_victory(kill_count, run_time, player.level, run_coins, reason)
	get_tree().paused = true
