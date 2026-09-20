extends Node2D

## 环绕飞刀（U6）：刀刃绕玩家旋转，碰到敌人造成伤害。
## 刀刃节点全部用代码创建（参照 xp_gem 的纯代码绘制先例），不依赖美术素材。
## 数值见 balance.gd 的 ORBIT_BLADE_* 常量；抽到"环形刀刃"卡时由 player.gd 调 set_blade_count。


var blade_count := 0
var evolved := false  # 刃风暴形态
var _radius := Balance.ORBIT_BLADE_RADIUS
var _blades: Array[Area2D] = []
# 同一敌人的受击冷却：{ 敌人 instance_id: 剩余秒 }，所有刀刃共用，
# 避免两把刀扫过同一个怪时一帧内连续结算
var _hit_cooldowns: Dictionary = {}


## 设置刀刃数量，多退少补，并按数量重新均匀分布角度。
func set_blade_count(count: int) -> void:
	blade_count = count
	while _blades.size() < count:
		_add_blade()
	while _blades.size() > count:
		_blades.pop_back().queue_free()
	_layout_blades()


## 进化：刃风暴——转速翻倍、轨道扩大、伤害提升、刀刃变金
func evolve() -> void:
	if evolved:
		return
	evolved = true
	_radius += Balance.BLADE_EVOLVE_RADIUS_BONUS
	_layout_blades()
	for blade in _blades:
		for child in blade.get_children():
			if child is Polygon2D:
				child.color = Color(1.0, 0.66, 0.22)
	Juice.pop(self, 1.6, 0.4)


func _layout_blades() -> void:
	for i in _blades.size():
		var angle := TAU * i / float(blade_count)
		_blades[i].position = Vector2(_radius, 0).rotated(angle)


func _add_blade() -> void:
	var blade := Area2D.new()
	blade.collision_layer = 0
	blade.collision_mask = 2  # 只碰敌人层
	blade.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 34.0
	shape.shape = circle
	blade.add_child(shape)
	# 刀刃朝外的多边形造型，随父节点公转自然形成旋转动画
	var knife := Polygon2D.new()
	knife.polygon = PackedVector2Array([
		Vector2(38, 0), Vector2(-14, 16), Vector2(-26, 0), Vector2(-14, -16),
	])
	knife.color = Color(0.92, 0.95, 1.0)
	blade.add_child(knife)
	blade.body_entered.connect(_on_blade_body_entered)
	add_child(blade)
	_blades.append(blade)


func _process(delta):
	var speed := Balance.ORBIT_BLADE_ROT_SPEED
	if evolved:
		speed *= Balance.BLADE_EVOLVE_ROT_MULT
	rotation += speed * delta
	for id in _hit_cooldowns.keys():
		var left: float = _hit_cooldowns[id] - delta
		if left <= 0.0:
			_hit_cooldowns.erase(id)
		else:
			_hit_cooldowns[id] = left


func _on_blade_body_entered(body):
	if not body.has_method("take_damage"):
		return
	var id: int = body.get_instance_id()
	if _hit_cooldowns.has(id):
		return
	_hit_cooldowns[id] = Balance.ORBIT_BLADE_HIT_CD
	# 与手枪共享"重装弹药"卡的伤害加成
	var damage: int = Balance.ORBIT_BLADE_DAMAGE + (get_parent().bullet_damage - 1)
	if evolved:
		damage += Balance.BLADE_EVOLVE_DAMAGE_BONUS
	# 从玩家中心向外击退
	var kb: Vector2 = (body.global_position - global_position).normalized() * Balance.KNOCKBACK_BLADE
	body.call_deferred("take_damage", damage, kb)
