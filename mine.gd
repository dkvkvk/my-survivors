extends Node2D

## 地火符阵（P6 第 6 把法宝）：在身周布下符雷，妖物靠近即引爆（范围伤害）。
## 符雷节点全部代码创建（沿用 orbit_blades / chain_lightning 的纯代码绘制先例）。
## 数值见 balance.gd 的 MINE_* / SKILL_THUNDERNET_*。
##
## 模型 B：被动等级 = 法宝品阶（player._apply_weapon_passive 调用 configure）。

var level := 0
var evolved := false
var _cooldown := 0.0
var _mines: Array = []  # [{node, arm, life, fuse}]


## 由 player.gd 按**法宝等级**调用（1 起，0 = 未持有）
func configure(p_level: int) -> void:
	level = p_level
	if level <= 0:
		_clear_mines()


## 满级进化：爆炸范围与伤害提升
func evolve() -> void:
	if evolved:
		return
	evolved = true
	Juice.pop(self, 1.6, 0.4)


func _process(delta: float) -> void:
	_update_mines(delta)
	if level <= 0:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = _interval()
		var ang: float = randf() * TAU
		_place(_owner_pos() + Vector2(Balance.MINE_SPAWN_OFFSET, 0).rotated(ang), 0.0)


## 布符间隔（秒）：等级越高越密
func _interval() -> float:
	var v: float = Balance.MINE_INTERVAL - Balance.MINE_INTERVAL_STEP * float(level - 1)
	return maxf(v, Balance.MINE_INTERVAL_MIN)


## 场上符雷上限：每 2 级 +1
func _max_mines() -> int:
	return Balance.MINE_MAX + int((level - 1) / 2)


func _owner_pos() -> Vector2:
	var p := get_parent()
	if p is Node2D:
		return (p as Node2D).global_position
	return global_position


func _place(pos: Vector2, fuse: float) -> void:
	# 超出上限先收掉最早的一张
	while _mines.size() >= _max_mines():
		var old: Dictionary = _mines.pop_front()
		var old_node: Node2D = old["node"]
		if is_instance_valid(old_node):
			old_node.queue_free()

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2      # 只碰敌人层
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = Balance.MINE_TRIGGER_RADIUS
	shape.shape = circle
	area.add_child(shape)
	# 造型：贴地的符（菱形符纸 + 中心雷点），随引信闪烁
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(11, 0), Vector2(0, 13), Vector2(-11, 0),
	])
	paper.color = Color(1.0, 0.86, 0.45)
	area.add_child(paper)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0),
	])
	core.color = Color(0.82, 0.24, 0.2)
	area.add_child(core)
	var glow := Sprite2D.new()
	glow.texture = load("res://assets/fx/glow_64.png")
	glow.scale = Vector2(1.0, 0.7)
	glow.modulate = Color(1.0, 0.62, 0.2, 0.45)
	glow.show_behind_parent = true
	area.add_child(glow)
	area.add_to_group("fx")
	add_child(area)
	area.global_position = pos

	var rec := {
		"node": area,
		"arm": Balance.MINE_ARM_TIME,
		"life": Balance.MINE_LIFE,
		"fuse": fuse,
	}
	area.body_entered.connect(_on_mine_body_entered.bind(rec))
	_mines.append(rec)
	VFX.drop_spawn_for(area, VFX.C_ORANGE)


func _update_mines(delta: float) -> void:
	var owner_pos: Vector2 = _owner_pos()
	var boom: Array = []
	var gone: Array = []
	for rec in _mines:
		var node: Node2D = rec["node"]
		if not is_instance_valid(node):
			gone.append(rec)
			continue
		var arm: float = float(rec["arm"]) - delta
		rec["arm"] = arm
		var life: float = float(rec["life"]) - delta
		rec["life"] = life
		var fuse: float = float(rec["fuse"])
		if fuse > 0.0:
			fuse -= delta
			rec["fuse"] = fuse
			if fuse <= 0.0:
				boom.append(rec)
				continue
		# 引信闪烁：越接近引爆越亮
		if arm <= 0.0:
			var k: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
			node.modulate.a = 0.72 + 0.28 * k
		if life <= 0.0:
			gone.append(rec)
	# 符雷跟着玩家走太远就失效（防"埋在地图另一头"越积越多）
	for rec in _mines:
		var node: Node2D = rec["node"]
		if is_instance_valid(node) and node.global_position.distance_to(owner_pos) > Balance.MINE_MAX_DISTANCE:
			if not gone.has(rec):
				gone.append(rec)
	for rec in boom:
		_detonate(rec)
	for rec in gone:
		var node: Node2D = rec["node"]
		if is_instance_valid(node):
			node.queue_free()
		_mines.erase(rec)


func _on_mine_body_entered(body: Node, rec: Dictionary) -> void:
	if not body.has_method("take_damage"):
		return
	if float(rec["arm"]) > 0.0:
		return
	_detonate(rec)


func _detonate(rec: Dictionary) -> void:
	var node: Node2D = rec["node"]
	if not is_instance_valid(node):
		_mines.erase(rec)
		return
	var pos: Vector2 = node.global_position
	_mines.erase(rec)
	node.queue_free()

	var radius: float = Balance.MINE_BLAST_RADIUS + (Balance.MINE_EVOLVE_RADIUS_BONUS if evolved else 0.0)
	var damage: int = Balance.MINE_DAMAGE + Balance.MINE_DAMAGE_STEP * (level - 1)
	if evolved:
		damage += Balance.MINE_EVOLVE_DAMAGE
	damage += get_parent().bullet_damage - 1   # 与飞剑共享"重装弹药"加成
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		if not mob.has_method("take_damage"):
			continue
		var d: float = pos.distance_to(mob.global_position)
		if d > radius:
			continue
		var kb: Vector2 = (mob.global_position - pos).normalized() * Balance.MINE_KNOCKBACK
		mob.call_deferred("take_damage", damage, kb, "mine")
		VFX.impact(mob.global_position, kb, VFX.C_ORANGE)
	VFX.explosion(pos, radius * 1.5, VFX.C_ORANGE)
	VFX.shockwave(pos, radius, VFX.C_GOLD, 0.28, 6.0)
	Audio.play("res://sounds/hit.wav", false, randf_range(0.8, 0.95), 0.35)
	var cam := get_parent().get_node_or_null("Camera2D")
	if cam != null:
		VFX.shake(cam, 0.3)


## 技能：十方雷网——在身周布下一圈符雷，短引信齐爆
func cast_ultimate() -> void:
	if level <= 0:
		return
	_cooldown = maxf(_cooldown, Balance.MINE_INTERVAL)
	var n: int = Balance.SKILL_THUNDERNET_COUNT
	for i in n:
		var ang: float = TAU * float(i) / float(n)
		var pos: Vector2 = _owner_pos() + Vector2(Balance.SKILL_THUNDERNET_RADIUS, 0).rotated(ang)
		_place(pos, Balance.SKILL_THUNDERNET_FUSE)


func _clear_mines() -> void:
	for rec in _mines:
		var node: Node2D = rec["node"]
		if is_instance_valid(node):
			node.queue_free()
	_mines.clear()
