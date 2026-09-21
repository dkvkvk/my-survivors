extends Area2D

## 灼热光环（U6）：周期性灼烧范围内所有敌人。
## 碰撞形状与外观全部代码生成，初始隐藏；抽到"灼热光环"卡后由 player.gd 调 configure()。
## 数值见 balance.gd 的 AURA_* 常量。


var level := 0
var evolved := false  # 烈日领域形态
var radius := 0.0
var damage := 0

var _pulse := 0.0  # 呼吸相位（见 _process / _draw）
var _circle: CircleShape2D
var _shape: CollisionShape2D
var _timer: Timer


func _ready():
	_setup()


## 构建碰撞与计时器（幂等）：_ready 即刻执行；极早期调用 configure/evolve 时惰性兜底
func _setup() -> void:
	if _shape != null:
		return
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
	_setup()
	level = p_level
	radius = Balance.AURA_BASE_RADIUS + Balance.AURA_RADIUS_STEP * (level - 1)
	damage = Balance.AURA_BASE_DAMAGE + Balance.AURA_DAMAGE_STEP * (level - 1)
	_circle.radius = radius
	queue_redraw()
	if visible:
		Juice.pop(self, 1.15, 0.25)
	show()
	_timer.start()


## 卸下武器时调用：停止灼烧并隐藏（被动等级 = 武器等级，丢武器就归零）
func deactivate() -> void:
	_setup()
	level = 0
	radius = 0.0
	_circle.radius = 0.0
	_timer.stop()
	hide()
	queue_redraw()


## 满级进化：烈日领域——灼烧间隔减半、伤害提升、变炽黄
func evolve() -> void:
	if evolved:
		return
	_setup()
	evolved = true
	damage += Balance.AURA_EVOLVE_DAMAGE_BONUS
	_timer.wait_time = Balance.AURA_EVOLVE_INTERVAL
	_timer.start()
	queue_redraw()
	Juice.pop(self, 1.5, 0.4)


## 呼吸脉动：光环平时几乎静止，暗场景里容易被忽略，加一层明暗变化提高存在感
func _process(delta: float) -> void:
	if level <= 0 or radius <= 0.0:
		return
	_pulse += delta
	queue_redraw()


func _draw():
	# 半透明圆盘 + 双层描边，纯代码绘制；进化后转为炽黄。
	# 填充透明度/边缘亮度都跟着呼吸走，让玩家一眼看出"这个圈在生效"。
	if level <= 0 or radius <= 0.0:
		return
	var k: float = 0.5 + 0.5 * sin(_pulse * 2.4)
	var fill := Color(1.0, 0.55, 0.25, 0.10 + 0.06 * k)
	var edge := Color(1.0, 0.62, 0.3, 0.55 + 0.30 * k)
	if evolved:
		fill = Color(1.0, 0.85, 0.3, 0.13 + 0.07 * k)
		edge = Color(1.0, 0.9, 0.45, 0.65 + 0.30 * k)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, edge, 5.0)
	draw_arc(Vector2.ZERO, radius * 0.86, 0.0, TAU, 48,
		Color(edge.r, edge.g, edge.b, edge.a * 0.45), 2.0)


func _on_timer_timeout():
	if level <= 0:
		return
	var hit_any := false
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.call_deferred("take_damage", damage)
			hit_any = true
	if hit_any:
		# 命中时轻微脉冲 + 一圈灼热环，给"灼烧正在生效"的反馈
		Juice.pop(self, 1.08, 0.3)
		var col: Color = VFX.C_GOLD if evolved else VFX.C_ORANGE
		VFX.shockwave(global_position, radius, col, 0.3, 4.0)
		VFX.burst(global_position, 6, col, 90.0, 0.5, "spark", 1.4, -160.0)
