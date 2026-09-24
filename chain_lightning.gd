extends Node2D

## 链式闪电（P5/P6）：被动 + 技能，电弧纯代码绘制（锯齿折线 + 四层辉光）。
##   被动 on_hit()：任意一次命中（子弹/飞刀）作为触发源，逐跳衰减地跳向附近敌人
##   技能 cast_ultimate()：雷神之怒——从天上劈下多道天雷，落点目标再继续跳跃
## 数值见 balance.gd 的 CHAIN_* / SKILL_THUNDER_* / SKY_BOLT_HEIGHT。

var level := 0
var evolved := false  # 满级进化形态
var _cooldown := 0.0
var _lines: Array = []  # 每段电弧：{"from":Vector2, "to":Vector2, "points":PackedVector2Array, "life":float}


## 由 player.gd 按**法宝等级**调用（P6 模型 B）；level 从 1 开始，0 = 未持有该法宝
func configure(p_level: int) -> void:
	level = p_level


## 满级进化：跳跃次数增加、伤害衰减放缓
func evolve() -> void:
	if evolved:
		return
	evolved = true
	Juice.pop(self, 1.6, 0.4)


## 被动触发入口（由 bullet_2d / orbit_blades 调用）。
## exclude_id：触发这次命中的敌人 id——必须排除，否则电弧会原地"打自己"一次
func on_hit(pos: Vector2, exclude_id := 0) -> void:
	if level <= 0 or _cooldown > 0.0:
		return
	_cooldown = Balance.CHAIN_TRIGGER_CD
	var exclude := {}
	if exclude_id != 0:
		exclude[exclude_id] = true
	_strike(pos, 0, 0, exclude)


## 技能「雷神之怒」：向四周劈下多道天雷，落点目标挨一击后再继续跳跃。
## 附近怪不够时按圆周补足落点，保证"大范围雷击"的观感。
func cast_ultimate() -> void:
	if level <= 0:
		return
	_cooldown = Balance.CHAIN_TRIGGER_CD
	for t in _ultimate_targets():
		var pos: Vector2 = t["pos"]
		var id: int = int(t["id"])
		# 天雷：从目标正上方劈下来，落点爆闪
		_add_arc(pos + Vector2(randf_range(-70.0, 70.0), -Balance.SKY_BOLT_HEIGHT), pos)
		VFX.thunder_strike(pos, VFX.C_BLUE)
		if id != 0:
			var mob = instance_from_id(id)
			if mob != null and is_instance_valid(mob):
				mob.call_deferred("take_damage", _hit_damage(Balance.SKILL_THUNDER_DAMAGE_BONUS), Vector2.ZERO, "chain_lightning")
		var exclude := {}
		if id != 0:
			exclude[id] = true
		_strike(pos, Balance.SKILL_THUNDER_EXTRA_JUMPS, Balance.SKILL_THUNDER_DAMAGE_BONUS, exclude)


## 雷神之怒的落点：优先取玩家附近的敌人，不足时圆周均分补足
func _ultimate_targets() -> Array:
	var me: Vector2 = get_parent().global_position
	var out: Array = []
	for mob in get_tree().get_nodes_in_group("mobs"):
		if out.size() >= Balance.SKILL_THUNDER_ORIGINS:
			break
		if not is_instance_valid(mob) or not (mob is Node2D) or not mob.has_method("take_damage"):
			continue
		var p: Vector2 = mob.global_position
		if me.distance_to(p) <= Balance.SKILL_AURA_RADIUS:
			out.append({"pos": p, "id": mob.get_instance_id()})
	var missing: int = Balance.SKILL_THUNDER_ORIGINS - out.size()
	for i in missing:
		var ang: float = TAU * float(i) / float(maxi(missing, 1)) + randf() * 0.6
		out.append({"pos": me + Vector2(Balance.SKILL_AURA_RADIUS * 0.55, 0).rotated(ang), "id": 0})
	return out


## 当前一跳的伤害
func _hit_damage(bonus: int) -> int:
	return Balance.CHAIN_BASE_DAMAGE + Balance.CHAIN_DAMAGE_STEP * (level - 1) + bonus


func _strike(origin: Vector2, extra_jumps := 0, damage_bonus := 0, exclude := {}) -> void:
	var jumps: int = Balance.CHAIN_BASE_JUMPS + Balance.CHAIN_JUMP_STEP * (level - 1) + extra_jumps
	var falloff: float = Balance.CHAIN_FALLOFF
	if evolved:
		jumps += Balance.CHAIN_EVOLVE_EXTRA_JUMPS
		falloff = Balance.CHAIN_EVOLVE_FALLOFF

	var damage: float = float(_hit_damage(damage_bonus))
	var hit_ids: Dictionary = exclude.duplicate()
	var from := origin

	for i in jumps:
		var target := _nearest_mob(from, hit_ids)
		if target == null:
			break
		hit_ids[target.get_instance_id()] = true
		var to: Vector2 = target.global_position
		_add_arc(from, to)
		VFX.impact(to, to - from, VFX.C_BLUE)
		target.call_deferred("take_damage", int(round(damage)), Vector2.ZERO, "chain_lightning")
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
