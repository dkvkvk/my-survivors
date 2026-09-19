extends Area2D

## 灼热光环（U6）：周期性灼烧范围内所有敌人。
## 碰撞形状与外观全部代码生成，初始隐藏；抽到"灼热光环"卡后由 player.gd 调 configure()。
## 数值见 balance.gd 的 AURA_* 常量。


var level := 0
var radius := 0.0
var damage := 0

var _circle: CircleShape2D
var _shape: CollisionShape2D
var _timer: Timer


func _ready():
	hide()
	collision_layer = 0
	collision_mask = 2  # 只碰敌人层
	monitorable = false

	_shape = CollisionShape2D.new()
	_circle = CircleShape2D.new()
	_circle.radius = 0.0
	_shape.shape = _circle
	add_child(_shape)

	_timer = Timer.new()
	_timer.wait_time = Balance.AURA_INTERVAL
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


## 按等级配置半径/伤害并激活。level 从 1 开始，重复抽卡按公式叠加。
func configure(p_level: int) -> void:
	level = p_level
	radius = Balance.AURA_BASE_RADIUS + Balance.AURA_RADIUS_STEP * (level - 1)
	damage = Balance.AURA_BASE_DAMAGE + Balance.AURA_DAMAGE_STEP * (level - 1)
	_circle.radius = radius
	queue_redraw()
	if visible:
		Juice.pop(self, 1.15, 0.25)
	show()
	_timer.start()


func _draw():
	# 半透明橙色圆盘加一圈描边，纯代码绘制
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.55, 0.25, 0.1))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.55, 0.25, 0.45), 4.0)


func _on_timer_timeout():
	if level <= 0:
		return
	var hit_any := false
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.call_deferred("take_damage", damage)
			hit_any = true
	if hit_any:
		# 命中时轻微脉冲，给"灼烧正在生效"的反馈
		Juice.pop(self, 1.08, 0.3)
