extends Node2D

## 链式闪电（P5）：任意一次命中（子弹/飞刀）作为触发源，
## 从命中点开始，在 CHAIN_RANGE 内依次跳向最近的敌人，逐跳衰减。
## 电弧纯代码绘制（锯齿折线），不依赖美术素材；数值见 balance.gd 的 CHAIN_*。


var level := 0
var evolved := false  # 雷神之怒形态
var _cooldown := 0.0
var _lines: Array = []  # 每段电弧：{"from":Vector2, "to":Vector2, "points":PackedVector2Array, "life":float}


## 抽到"链式闪电"卡时由 player.gd 调用；level 从 1 开始
func configure(p_level: int) -> void:
	level = p_level


## 进化：雷神之怒——跳跃次数增加、伤害衰减放缓
func evolve() -> void:
	if evolved:
		return
	evolved = true
	Juice.pop(self, 1.6, 0.4)


## 命中触发入口（由 bullet_2d / orbit_blades 调用）
func on_hit(pos: Vector2) -> void:
	if level <= 0 or _cooldown > 0.0:
		return
	_cooldown = Balance.CHAIN_TRIGGER_CD
	_strike(pos)


func _strike(origin: Vector2) -> void:
	var jumps: int = Balance.CHAIN_BASE_JUMPS + Balance.CHAIN_JUMP_STEP * (level - 1)
	var falloff: float = Balance.CHAIN_FALLOFF
	if evolved:
		jumps += Balance.CHAIN_EVOLVE_EXTRA_JUMPS
		falloff = Balance.CHAIN_EVOLVE_FALLOFF

	var damage: float = float(Balance.CHAIN_BASE_DAMAGE + Balance.CHAIN_DAMAGE_STEP * (level - 1))
	var hit_ids := {}
	var from := origin

	for i in jumps:
		var target := _nearest_mob(from, hit_ids)
		if target == null:
			break
		hit_ids[target.get_instance_id()] = true
		var to: Vector2 = target.global_position
		_add_arc(from, to)
		target.call_deferred("take_damage", int(round(damage)))
		from = to
		damage *= falloff
		# 至少保留 1 点伤害，避免高跳数时变成 0
		damage = maxf(damage, 1.0)


## 在 from 周围 CHAIN_RANGE 内找最近的、还没被这条链打过的敌人
func _nearest_mob(from: Vector2, exclude: Dictionary) -> Node2D:
	var best: Node2D = null
	var best_dist := Balance.CHAIN_RANGE
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		if exclude.has(mob.get_instance_id()):
			continue
		if not mob.has_method("take_damage"):
			continue
		var d: float = from.distance_to(mob.global_position)
		if d < best_dist:
			best_dist = d
			best = mob
	return best


func _add_arc(from: Vector2, to: Vector2) -> void:
	_lines.append({
		"from": from,
		"to": to,
		"points": _jagged(from, to),
		"life": Balance.CHAIN_LINE_LIFE,
	})
	queue_redraw()


## 生成一条锯齿折线：把直线均分成若干段，中间点做垂直方向抖动
func _jagged(from: Vector2, to: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var dir := to - from
	var dist := dir.length()
	var perp := Vector2(-dir.y, dir.x).normalized()
	# 段数随距离增加，长弧抖得更多；每段振幅随机，做出电的"毛刺"感
	var segs: int = clampi(int(dist / 26.0), 4, 12)
	for i in segs + 1:
		var t := float(i) / float(segs)
		var p := from.lerp(to, t)
		if i > 0 and i < segs:
			var amp: float = Balance.CHAIN_LINE_JITTER * randf_range(0.35, 1.0)
			p += perp * randf_range(-amp, amp)
		pts.append(p)
	return pts


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _lines.is_empty():
		return
	var alive: Array = []
	for arc in _lines:
		arc["life"] -= delta
		if arc["life"] > 0.0:
			alive.append(arc)
	_lines = alive
	queue_redraw()


func _draw() -> void:
	for arc in _lines:
		var a: float = clampf(arc["life"] / Balance.CHAIN_LINE_LIFE, 0.0, 1.0)
		var pts: PackedVector2Array = arc["points"]
		# 由外到内叠四层：柔光 → 中光 → 青色电芯 → 近白芯，做出"电"的辉光层次
		draw_polyline(pts, Color(0.20, 0.55, 1.0, a * 0.20), 26.0, true)
		draw_polyline(pts, Color(0.30, 0.78, 1.0, a * 0.42), 15.0, true)
		draw_polyline(pts, Color(0.62, 0.95, 1.0, a * 0.95), 7.0, true)
		draw_polyline(pts, Color(1.0, 1.0, 1.0, a), 3.0, true)
		# 落点爆闪，强调"打到这只怪"
		draw_circle(arc["to"], 14.0 * a + 3.0, Color(0.55, 0.90, 1.0, a * 0.35))
		draw_circle(arc["to"], 8.0 * a + 2.0, Color(0.80, 0.97, 1.0, a * 0.65))
		draw_circle(arc["to"], 4.0 * a + 1.0, Color(1.0, 1.0, 1.0, a))
