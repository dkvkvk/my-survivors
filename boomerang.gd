extends Node2D

## 回风梭（P6 第 5 把法宝）：掷出后飞出再折返，去程/返程各能命中一次。
## 飞梭节点全部代码创建（沿用 orbit_blades / chain_lightning 的纯代码绘制先例）。
## 数值见 balance.gd 的 BOOMERANG_* / SKILL_WHIRLWIND_*。
##
## 模型 B：被动等级 = 法宝品阶（player._apply_weapon_passive 调用 configure）。

var level := 0
var evolved := false
var _cooldown := 0.0
var _shots: Array = []  # [{node, dir, travelled, returning, hit:{id:true}}]


## 由 player.gd 按**法宝等级**调用（1 起，0 = 未持有）
func configure(p_level: int) -> void:
	level = p_level
	if level <= 0:
		_clear_shots()


## 满级进化：飞梭变大变快、伤害提升
func evolve() -> void:
	if evolved:
		return
	evolved = true
	Juice.pop(self, 1.6, 0.4)


func _process(delta: float) -> void:
	_update_shots(delta)
	if level <= 0:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = _interval()
		_throw(_shot_count(), _aim_dir())


## 投掷间隔（秒）：等级越高越密
func _interval() -> float:
	var v: float = Balance.BOOMERANG_INTERVAL - Balance.BOOMERANG_INTERVAL_STEP * float(level - 1)
	return maxf(v, Balance.BOOMERANG_INTERVAL_MIN)


## 每次掷出的枚数：每 BOOMERANG_COUNT_STEP 级 +1
func _shot_count() -> int:
	return 1 + int((level - 1) / Balance.BOOMERANG_COUNT_STEP)


func _aim_dir() -> Vector2:
	var best: Node2D = null
	var best_d := 1e20
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		if not mob.has_method("take_damage"):
			continue
		var d: float = global_position.distance_to(mob.global_position)
		if d < best_d:
			best_d = d
			best = mob
	if best == null:
		return Vector2.RIGHT.rotated(randf() * TAU)
	return (best.global_position - global_position).normalized()


## 掷出一组飞梭：第一枚朝目标，其余按扇形散开
func _throw(count: int, dir: Vector2) -> void:
	for i in count:
		var offset: float = 0.0
		if count > 1:
			offset = (float(i) / float(count - 1) - 0.5) * Balance.BOOMERANG_SPREAD * float(count - 1)
		_add_shot(dir.rotated(offset))


## pierce=true 是神通「穿云巨梭」：更大更快、走直线穿透、到射程就消失（不折返）
func _add_shot(dir: Vector2, pierce := false) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2      # 只碰敌人层
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = Balance.BOOMERANG_HIT_RADIUS
	shape.shape = circle
	area.add_child(shape)
	# 造型：细长梭形（两头尖），随飞行方向旋转
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([
		Vector2(20, 0), Vector2(2, 10), Vector2(-14, 0), Vector2(2, -10),
	])
	blade.color = Color(1.0, 0.72, 0.3) if evolved else Color(0.62, 0.98, 1.0)
	if pierce:
		blade.scale = Vector2(2.0, 2.0)
		blade.color = Color(1.0, 0.93, 0.66)
	area.add_child(blade)
	var glow := Sprite2D.new()
	glow.texture = load("res://assets/fx/glow_64.png")
	glow.scale = Vector2(1.1, 0.8)
	glow.modulate = Color(1.0, 0.8, 0.4, 0.5) if evolved else Color(0.4, 0.95, 1.0, 0.5)
	glow.show_behind_parent = true
	area.add_child(glow)
	area.add_to_group("fx")
	area.rotation = dir.angle()
	add_child(area)
	area.global_position = global_position
	var rec := {
		"node": area,
		"dir": dir,
		"travelled": 0.0,
		"returning": false,
		"pierce": pierce,
		"hit": {},
	}
	area.body_entered.connect(_on_shot_body_entered.bind(rec))
	_shots.append(rec)
	VFX.trail(area, VFX.C_CYAN, 10.0, 10, 0.14)


func _update_shots(delta: float) -> void:
	var speed_mult: float = Balance.BOOMERANG_EVOLVE_SPEED_MULT if evolved else 1.0
	var reach: float = Balance.BOOMERANG_RANGE + (Balance.BOOMERANG_EVOLVE_RANGE_BONUS if evolved else 0.0)
	var owner_pos: Vector2 = get_parent().global_position if get_parent() is Node2D else global_position
	var dead: Array = []
	for rec in _shots:
		var node: Node2D = rec["node"]
		if not is_instance_valid(node):
			dead.append(rec)
			continue
		if bool(rec["returning"]):
			var back: Vector2 = (owner_pos - node.global_position)
			if back.length() <= Balance.BOOMERANG_RETURN_CATCH:
				dead.append(rec)
				node.queue_free()
				continue
			var rdir: Vector2 = back.normalized()
			node.global_position += rdir * Balance.BOOMERANG_RETURN_SPEED * speed_mult * delta
			node.rotation = rdir.angle()
		else:
			var dir: Vector2 = rec["dir"]
			var pierce: bool = bool(rec.get("pierce", false))
			var spd: float = (Balance.SKILL_PIERCE_SPEED if pierce else Balance.BOOMERANG_SPEED) * speed_mult
			node.global_position += dir * spd * delta
			node.rotation = dir.angle()
			rec["travelled"] = float(rec["travelled"]) + spd * delta
			var limit: float = Balance.SKILL_PIERCE_RANGE if pierce else reach
			if float(rec["travelled"]) >= limit:
				if pierce:
					dead.append(rec)
					node.queue_free()
					continue
				rec["returning"] = true
				var hits: Dictionary = rec["hit"]
				hits.clear()      # 返程可以再命中一次
	for rec in dead:
		_shots.erase(rec)


func _on_shot_body_entered(body: Node, rec: Dictionary) -> void:
	if not body.has_method("take_damage"):
		return
	var id: int = body.get_instance_id()
	var hits: Dictionary = rec["hit"]
	if hits.has(id):
		return
	hits[id] = true
	var damage: int = Balance.BOOMERANG_DAMAGE + Balance.BOOMERANG_DAMAGE_STEP * (level - 1)
	if bool(rec.get("pierce", false)):
		damage = Balance.SKILL_PIERCE_DAMAGE + Balance.BOOMERANG_DAMAGE_STEP * (level - 1)
	if evolved:
		damage += Balance.BOOMERANG_EVOLVE_DAMAGE
	damage += get_parent().bullet_damage - 1   # 与飞剑共享"重装弹药"加成
	var dir: Vector2 = rec["dir"]
	var kb: Vector2 = dir * Balance.BOOMERANG_KNOCKBACK
	body.call_deferred("take_damage", damage, kb, "boomerang")
	var node: Node2D = rec["node"]
	if is_instance_valid(node):
		VFX.impact(node.global_position, dir, VFX.C_CYAN)
	get_parent().call_deferred("on_weapon_hit", body.global_position, id)


## 神通「穿云巨梭」：一枚巨型飞梭走直线穿透全部敌人（进化后两枚）
func cast_pierce() -> void:
	if level <= 0:
		return
	_add_shot(_aim_dir(), true)
	if evolved:
		_add_shot(_aim_dir().rotated(0.16), true)


## 技能：风卷残云——向四周掷出一圈飞梭
func cast_ultimate() -> void:
	if level <= 0:
		return
	_cooldown = maxf(_cooldown, _interval())
	var n: int = Balance.SKILL_WHIRLWIND_COUNT
	for i in n:
		_add_shot(Vector2.RIGHT.rotated(TAU * float(i) / float(n)))


func _clear_shots() -> void:
	for rec in _shots:
		var node: Node2D = rec["node"]
		if is_instance_valid(node):
			node.queue_free()
	_shots.clear()
