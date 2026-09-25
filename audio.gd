extends Node

# Code adapted from KidsCanCode

var num_players = 12
var bus = "master"

var available = []
var queue = []

var active_sounds = {}

# 背景音乐：独立播放器循环播放，不占音效池
var _music_player: AudioStreamPlayer
var _music_path := ""

# 音量（P7 设置菜单）：0~1，由设置面板写入存档后调用 apply_volumes() 生效
var music_volume := 1.0
var sfx_volume := 1.0

func apply_volumes() -> void:
	music_volume = clampf(float(SaveGame.get_setting("music", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(SaveGame.get_setting("sfx", 1.0)), 0.0, 1.0)
	if _music_player != null:
		# -16dB 是曲子本身的基准音量，滑块在其上按比例缩放
		_music_player.volume_db = linear_to_db(maxf(music_volume, 0.001)) - 16.0

func _ready():
	apply_volumes()
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.volume_db = -10
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus

func _on_stream_finished(player):
	for path in active_sounds.keys():
		if active_sounds[path].has(player):
			active_sounds[path].erase(player)
			if active_sounds[path].is_empty():
				active_sounds.erase(path)
			break
	available.append(player)

## 播放循环 BGM；同曲在播直接忽略，换曲平滑替换。
func play_music(sound_path: String) -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		add_child(_music_player)
		_music_player.volume_db = linear_to_db(maxf(music_volume, 0.001)) - 16.0
		_music_player.bus = bus
		# WAV 播完自动重播实现循环
		_music_player.finished.connect(func(): _music_player.play())
	if _music_path == sound_path and _music_player.playing:
		return
	_music_path = sound_path
	_music_player.stream = load(sound_path)
	_music_player.play()


func stop_music() -> void:
	_music_path = ""
	if _music_player != null:
		_music_player.stop()


func play(sound_path: String, allow_overlap: bool = false, pitch: float = 1.0, volume: float = 1.0):
	if allow_overlap:
		queue.append({"path": sound_path, "overlap": true, "pitch": pitch, "volume": volume})
	else:
		if not active_sounds.has(sound_path) and not _is_in_queue(sound_path):
			queue.append({"path": sound_path, "overlap": false, "pitch": pitch, "volume": volume})

func _is_in_queue(sound_path: String) -> bool:
	for item in queue:
		if item["path"] == sound_path:
			return true
	return false

func _process(_delta):
	if not queue.is_empty() and not available.is_empty():
		var data = queue.pop_front()
		var sound_path = data["path"]
		var player = available[0]
		available.pop_front()
		
		if not data["overlap"]:
			if not active_sounds.has(sound_path):
				active_sounds[sound_path] = []
			active_sounds[sound_path].append(player)
		
		player.stream = load(sound_path)
		player.pitch_scale = data["pitch"]
		
		player.volume_db = linear_to_db(maxf(float(data["volume"]) * sfx_volume, 0.001))
		
		player.play()

# Utility for decibels

func linear_to_db(linear: float) -> float:
	if linear > 0:
		return 20.0 * log(linear) / log(10.0)
	return -80.0
