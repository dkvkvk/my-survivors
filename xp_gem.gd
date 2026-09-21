extends Area2D

## 经验宝石：怪死后掉落。进入玩家拾取半径会被加速吸过来，碰到玩家即收取。
## 外观用 icon_gem.png，外面套一层柔光 + 呼吸缩放——深色石板地面上原本太小太暗，
## 玩家反馈"掉落的经验不显眼"，所以这里放大并加了发光。

const VISUAL_SCALE := 2.2      # 宝石本体放大倍数（原图 9x12，太小）
const GLOW_SCALE := 3.8        # 柔光层放大倍数
const PULSE_SPEED := 4.0       # 呼吸速度
const PULSE_DEPTH := 0.12      # 呼吸幅度

var value := Balance.GEM_VALUE
var magnet_speed := 0.0
var _visual: Sprite2D
var _glow: Sprite2D
var _t := 0.0

@onready var player: CharacterBody2D = get_node("/root/Game/Player")


func _ready():
	Juice.pop(self, 1.4)
	_visual = $Visual
	_visual.scale = Vector2.ONE * VISUAL_SCALE
	# 柔光层：同贴图放大、低透明度、青色偏亮，垫在本体后面
	_glow = Sprite2D.new()
	_glow.texture = _visual.texture
	_glow.scale = Vector2.ONE * GLOW_SCALE
	_glow.modulate = Color(0.45, 1.0, 1.0, 0.35)
	_glow.show_behind_parent = true
	add_child(_glow)


func _process(delta):
	_t += delta
	# 呼吸：本体轻微缩放 + 柔光忽明忽暗，在杂乱地面上更容易被注意到
	var k: float = 1.0 + PULSE_DEPTH * sin(_t * PULSE_SPEED)
	_visual.scale = Vector2.ONE * VISUAL_SCALE * k
	_glow.modulate.a = 0.22 + 0.20 * (0.5 + 0.5 * sin(_t * PULSE_SPEED))


func _physics_process(delta):
	var to_player := player.global_position - global_position
	if to_player.length() < player.pickup_radius:
		# 进入磁吸范围后越飞越快
		magnet_speed = maxf(magnet_speed + 1400.0 * delta, 400.0)
		position += to_player.normalized() * magnet_speed * delta
	else:
		# 磁吸范围外也缓慢滚向玩家，不用专门跑图去捡
		position += to_player.limit_length(1.0) * Balance.GEM_DRIFT_SPEED * delta


func _on_body_entered(body):
	if body == player:
		queue_free()
		Audio.play("res://sounds/pickup.wav", false, randf_range(1.1, 1.35), 0.2)
		# 加经验可能触发升级暂停，延迟到物理刷新外执行
		player.call_deferred("add_xp", value)
