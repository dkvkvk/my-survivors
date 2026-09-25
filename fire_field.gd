extends Area2D

## 焚地火域（P7 神通）：留在地面持续灼烧的法阵，纯代码绘制（沿用离火法环的画法）。
## 由 player.gd 施放神通时创建，播完时长自毁。
## 伤害归属默认记给离火法环（source）；融合神通「焚天剑轮」也走这条。

var damage := Balance.SKILL_FIRE_DAMAGE
var radius := Balance.SKILL_FIRE_RADIUS
var source := "aura"
var _life := Balance.SKILL_FIRE_TIME
var _tick := 0.0
var _spin := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2          # 只碰敌人层
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	add_to_group("fx")
	add_to_group("fire_fields")   # 测试与统计用
	VFX.drop_spawn_for(self, VFX.C_ORANGE)


func _process(delta: float) -> void:
	_life -= delta
	_spin += delta * 1.4
	if _life <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = Balance.SKILL_FIRE_TICK
		_burn()
	queue_redraw()


func _burn() -> void:
	var hit_any := false
	for body in get_overlapping_bodies():
		if not body.has_method("take_damage"):
			continue
		body.call_deferred("take_damage", damage, Vector2.ZERO, source)
		hit_any = true
	if hit_any:
		Audio.play("res://sounds/hit.wav", false, randf_range(0.7, 0.85), 0.2)


func _draw() -> void:
	# 快消失时淡出
	var fade: float = clampf(_life / 1.2, 0.0, 1.0)
	var fill := Color(1.0, 0.42, 0.12, 0.20 * fade)
	var edge := Color(1.0, 0.72, 0.28, 0.75 * fade)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, edge, 4.0)
	# 旋转火纹：8 道由内向外的短弧，表示法阵在烧
	for i in 8:
		var a0: float = _spin + TAU * float(i) / 8.0
		draw_arc(Vector2.ZERO, radius * 0.62, a0, a0 + 0.34, 8,
			Color(edge.r, edge.g, edge.b, 0.5 * fade), 3.0)
		draw_arc(Vector2.ZERO, radius * 0.30, a0 + 0.2, a0 + 0.44, 6,
			Color(1.0, 0.9, 0.5, 0.55 * fade), 2.0)
