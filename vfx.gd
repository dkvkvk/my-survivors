extends Node

## 全局特效库（autoload VFX）——《不退》所有打击 / 技能 / 拾取特效的唯一入口。
## 全部「纯代码绘制 + 程序化生成的像素贴图」（assets/fx/，本项目自制 CC0），
## 不依赖任何第三方素材；配色统一为 青霓虹 / 金 / 赤红（和风 + 科技）。
##
## 用法（任意脚本里）：
##   VFX.impact(pos, dir)                      命中爆点
##   VFX.shockwave(pos, 260.0, VFX.C_CYAN)     扩散冲击环
##   VFX.screen_flash(VFX.C_GOLD, 0.30)        全屏闪
##   VFX.trail(node, VFX.C_CYAN, 12.0)         给移动节点挂拖尾
## 特效挂在当前战斗场景下，播完自毁；游戏暂停时特效一起冻结。

const FX_DIR := "res://assets/fx/"

# 配色
const C_CYAN := Color(0.45, 0.95, 1.0)
const C_BLUE := Color(0.35, 0.65, 1.0)
const C_GOLD := Color(1.0, 0.82, 0.35)
const C_ORANGE := Color(1.0, 0.55, 0.2)
const C_RED := Color(1.0, 0.35, 0.3)
const C_GREEN := Color(0.5, 1.0, 0.7)
const C_WHITE := Color(1.0, 1.0, 1.0)

const FX_GROUP := "fx"
const FX_LIMIT := 260   # 同屏特效节点上限，超了就只出最便宜的（防止极端情况掉帧）

var _glow: Texture2D
var _star: Texture2D
var _spark: Texture2D
var _smoke: Texture2D
var _flash_rect: ColorRect = null
var _flash_tween: Tween = null


func _ready() -> void:
	_glow = _try_load("glow_64.png")
	_star = _try_load("star_64.png")
	_spark = _try_load("spark_32.png")
	_smoke = _try_load("smoke_64.png")


func _try_load(f: String) -> Texture2D:
	var p: String = FX_DIR + f
	if ResourceLoader.exists(p):
		return load(p)
	return null


## 特效挂载点：战斗场景根（/root/Game）；不在战斗场景时退化为当前场景
func world() -> Node:
	var g: Node = get_tree().get_root().get_node_or_null("Game")
	if g != null:
		return g
	return get_tree().current_scene


func _busy() -> bool:
	return get_tree().get_nodes_in_group(FX_GROUP).size() >= FX_LIMIT


func _add(n: Node2D, z: int) -> Node2D:
	var w: Node = world()
	if w == null:
		n.queue_free()
		return null
	n.z_index = z
	# 关键：特效一律 ALWAYS。升级/结算会暂停游戏，若跟着暂停，
	# 短命特效会冻在半透明状态留在画面上（升级光柱卡在升级卡后面）。
	n.process_mode = Node.PROCESS_MODE_ALWAYS
	n.add_to_group(FX_GROUP)
	w.add_child(n)
	return n


## ---------- 冲击环 / 光环 ----------

## 扩散冲击环（技能起手、爆炸、落地都能用）。fill=true 时带一层半透明填充
func shockwave(pos: Vector2, radius: float, color: Color = C_CYAN, duration := 0.35,
		width := 7.0, fill := false, z := 40) -> void:
	var n := _Ring.new()
	n.setup(radius, color, duration, width, fill)
	n.global_position = pos
	_add(n, z)


## 由外向内收缩的环（首领蓄力预警）
func warning_ring(pos: Vector2, radius: float, color: Color = C_RED, duration := 0.7) -> void:
	var n := _Ring.new()
	n.setup(radius, color, duration, 8.0, true, true)
	n.global_position = pos
	_add(n, -5)


## ---------- 斩击 ----------

## 新月斩击弧（近战 / 刃风暴）
func slash_arc(pos: Vector2, angle: float, radius: float, color: Color = C_CYAN,
		duration := 0.22, span := 1.7, z := 42) -> void:
	var n := _Slash.new()
	n.setup(radius, color, duration, span)
	n.global_position = pos
	n.rotation = angle
	_add(n, z)


## 旋转刀光：count 条斩击弧围绕一点旋转扩散（刃风暴）
func spin_slash(pos: Vector2, radius: float, color: Color = C_CYAN, count := 5, duration := 0.45) -> void:
	var base := randf() * TAU
	for i in count:
		var n := _Slash.new()
		n.setup(radius * randf_range(0.8, 1.05), color, duration * randf_range(0.8, 1.1),
			randf_range(1.1, 1.9), randf_range(2.4, 5.2))
		n.global_position = pos
		n.rotation = base + TAU * i / float(count)
		_add(n, 42)


## ---------- 粒子 ----------

## 爆散粒子：tex 取 "spark" / "star" / "smoke" / "glow"
func burst(pos: Vector2, count: int, color: Color = C_CYAN, speed := 260.0,
		life := 0.5, tex := "spark", size := 2.0, gravity := 700.0, z := 38) -> void:
	if _busy():
		return
	var p := CPUParticles2D.new()
	p.texture = _tex_for(tex)
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 1.0
	p.amount = maxi(count, 1)
	p.lifetime = life
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, gravity)
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.25
	p.color = color
	p.global_position = pos
	var n := _add(p, z)
	if n != null:
		p.emitting = true
		# 粒子播完自毁（多等一点寿命，避免最后一帧被截断）
		get_tree().create_timer(life * 1.6 + 0.1).timeout.connect(p.queue_free)


func _tex_for(name: String) -> Texture2D:
	match name:
		"star":
			return _star
		"smoke":
			return _smoke
		"glow":
			return _glow
		_:
			return _spark


## ---------- 组合特效（日常调用这几个就够） ----------

## 命中爆点：星芒闪 + 小环 + 少量火花。dir 为受击方向（火花朝反方向溅）
func impact(pos: Vector2, dir: Vector2 = Vector2.ZERO, color: Color = C_CYAN, strong := false) -> void:
	var s := _Flash.new()
	s.setup(_star, 0.9 if not strong else 1.4, 0.16, color, randf() * TAU)
	s.global_position = pos
	_add(s, 44)
	if _busy():
		return
	shockwave(pos, 22.0 if not strong else 34.0, color, 0.18, 3.0, false, 43)
	var back: Vector2 = -dir.normalized() if dir.length() > 0.01 else Vector2.UP
	burst(pos, 4 if not strong else 7, color, 200.0, 0.28, "spark", 1.6, 520.0, 38)


## 击杀爆炸：填充环 + 碎片 + 烟
func explosion(pos: Vector2, radius: float, color: Color = C_ORANGE) -> void:
	shockwave(pos, radius, color, 0.4, 9.0, true)
	shockwave(pos, radius * 0.55, C_WHITE, 0.22, 4.0)
	burst(pos, 12, color, 340.0, 0.55, "spark", 2.2, 760.0)
	burst(pos, 5, Color(0.75, 0.78, 0.82, 0.55), 110.0, 0.75, "smoke", 2.6, -40.0, 36)


## 拾取小反馈（经验宝石 / 金币 / 材料 / 武器）
func pickup_pop(pos: Vector2, color: Color = C_GREEN) -> void:
	var s := _Flash.new()
	s.setup(_star, 0.55, 0.18, color, randf() * TAU)
	s.global_position = pos
	_add(s, 44)
	shockwave(pos, 16.0, color, 0.16, 2.5, false, 43)


## 升级：脚下双环 + 光柱 + 星芒
func levelup_burst(pos: Vector2, color: Color = C_GOLD) -> void:
	shockwave(pos, 150.0, color, 0.5, 8.0)
	shockwave(pos, 90.0, C_WHITE, 0.3, 4.0)
	var pillar := _Pillar.new()
	pillar.setup(_glow, color, 0.7)
	pillar.global_position = pos
	_add(pillar, 41)
	burst(pos, 14, color, 260.0, 0.8, "star", 1.8, -120.0, 39)
	screen_flash(color, 0.14, 0.22)


## 枪口闪光（朝 angle 方向）
func muzzle_flash(pos: Vector2, angle: float, color: Color = C_CYAN) -> void:
	var s := _Flash.new()
	s.setup(_glow, 0.42, 0.09, color, angle)
	s.global_position = pos
	_add(s, 45)


## 天雷落点：地面炸环 + 火花（链式闪电用）
func thunder_strike(pos: Vector2, color: Color = C_BLUE) -> void:
	shockwave(pos, 90.0, color, 0.35, 6.0)
	shockwave(pos, 45.0, C_WHITE, 0.2, 3.0)
	burst(pos, 8, color, 300.0, 0.45, "spark", 1.8, 900.0)
	screen_flash(color, 0.12, 0.14)


## ---------- 全屏闪 ----------

## 全屏闪：全局复用一块遮罩，多次调用只刷新颜色（不会叠加成一片死白）
func screen_flash(color: Color = C_WHITE, alpha := 0.28, duration := 0.18) -> void:
	var w: Node = world()
	if w == null:
		return
	if _flash_rect == null or not is_instance_valid(_flash_rect):
		var layer := CanvasLayer.new()
		layer.layer = 12   # 在 HUD(10) 之上、背包(20) 之下
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
		_flash_rect = ColorRect.new()
		_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash_rect.color = Color(0, 0, 0, 0)
		layer.add_child(_flash_rect)
		w.add_child(layer)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_rect.color = Color(color.r, color.g, color.b, alpha)
	_flash_tween = _flash_rect.create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## ---------- 拖尾 ----------

## 给移动节点（子弹 / 飞刀 / 首领）挂一条拖尾；节点销毁后拖尾自己淡出
func trail(target: Node2D, color: Color = C_CYAN, width := 10.0, points := 12, life := 0.18) -> void:
	if target == null or _busy():
		return
	var t := _Trail.new()
	t.setup(target, color, width, points, life)
	_add(t, 39)


## ---------- 内部实现 ----------

## 短促的星芒 / 光晕闪
class _Flash extends Node2D:
	var _tex: Texture2D
	var _base := 1.0
	var _dur := 0.16
	var _col := Color.WHITE
	var _t := 0.0
	var _spr: Sprite2D

	func setup(tex: Texture2D, base: float, dur: float, col: Color, rot: float) -> void:
		_tex = tex
		_base = base
		_dur = dur
		_col = col
		rotation = rot

	func _ready() -> void:
		_spr = Sprite2D.new()
		_spr.texture = _tex
		_spr.modulate = _col
		add_child(_spr)

	func _process(delta: float) -> void:
		_t += delta
		var k: float = clampf(_t / _dur, 0.0, 1.0)
		var s: float = _base * (0.55 + 0.9 * k)
		scale = Vector2.ONE * s
		_spr.modulate.a = 1.0 - k
		if k >= 1.0:
			queue_free()


## 扩散 / 收缩圆环
class _Ring extends Node2D:
	var _max := 100.0
	var _col := Color.WHITE
	var _dur := 0.35
	var _w := 7.0
	var _fill := false
	var _inward := false
	var _t := 0.0
	var _r := 0.0

	func setup(max_r: float, col: Color, dur: float, w: float, fill: bool, inward := false) -> void:
		_max = max_r
		_col = col
		_dur = dur
		_w = w
		_fill = fill
		_inward = inward
		_r = max_r if inward else 0.0

	func _process(delta: float) -> void:
		_t += delta
		var k: float = clampf(_t / _dur, 0.0, 1.0)
		if _inward:
			_r = _max * (1.0 - k * k)
		else:
			_r = _max * (1.0 - pow(1.0 - k, 2.4))
		queue_redraw()
		if k >= 1.0:
			queue_free()

	func _draw() -> void:
		var k: float = clampf(_t / _dur, 0.0, 1.0)
		var a: float = 1.0 - k
		if _fill and _r > 1.0:
			draw_circle(Vector2.ZERO, _r, Color(_col.r, _col.g, _col.b, a * 0.16))
		if _r > 1.0:
			draw_arc(Vector2.ZERO, _r, 0.0, TAU, 64,
				Color(_col.r, _col.g, _col.b, a * 0.95), maxf(_w * (1.0 - 0.55 * k), 1.0), true)
			draw_arc(Vector2.ZERO, _r * 0.86, 0.0, TAU, 64,
				Color(1.0, 1.0, 1.0, a * 0.5), maxf(_w * 0.35, 1.0), true)


## 新月斩击弧：外弧 + 内弧围成的填充带，随寿命向外扩张并淡出
class _Slash extends Node2D:
	var _radius := 100.0
	var _col := Color.WHITE
	var _dur := 0.22
	var _span := 1.7
	var _spin := 0.0
	var _t := 0.0
	var _pts := PackedVector2Array()

	func setup(radius: float, col: Color, dur: float, span: float, spin := 0.0) -> void:
		_radius = radius
		_col = col
		_dur = dur
		_span = span
		_spin = spin
		_build()

	func _build() -> void:
		var segs := 18
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in segs + 1:
			var a: float = -_span * 0.5 + _span * float(i) / float(segs)
			outer.append(Vector2.RIGHT.rotated(a) * _radius)
			# 内弧做成"刀刃"形：中间厚、两头收成尖
			var taper: float = 0.30 + 0.55 * sin(PI * float(i) / float(segs))
			inner.append(Vector2.RIGHT.rotated(a) * _radius * (1.0 - taper * 0.42))
		inner.reverse()
		_pts = outer + inner

	func _process(delta: float) -> void:
		_t += delta
		var k: float = clampf(_t / _dur, 0.0, 1.0)
		scale = Vector2.ONE * (0.72 + 0.42 * k)
		rotation += _spin * delta
		queue_redraw()
		if k >= 1.0:
			queue_free()

	func _draw() -> void:
		var k: float = clampf(_t / _dur, 0.0, 1.0)
		var a: float = (1.0 - k) * (1.0 - k)
		draw_colored_polygon(_pts, Color(_col.r, _col.g, _col.b, a * 0.75))
		draw_polyline(_pts, Color(1.0, 1.0, 1.0, a), 3.0, true)


## 升级光柱：一张光晕贴图纵向拉伸
class _Pillar extends Node2D:
	var _spr: Sprite2D
	var _dur := 0.7
	var _t := 0.0

	func setup(tex: Texture2D, col: Color, dur: float) -> void:
		_dur = dur
		_spr = Sprite2D.new()
		_spr.texture = tex
		_spr.modulate = col
		add_child(_spr)

	func _process(delta: float) -> void:
		_t += delta
		var k: float = clampf(_t / _dur, 0.0, 1.0)
		_spr.scale = Vector2(1.1 + 0.5 * k, 5.5 + 5.0 * k)
		_spr.position.y = -_spr.scale.y * 20.0
		_spr.modulate.a = (1.0 - k) * 0.85
		if k >= 1.0:
			queue_free()


## 拖尾：每帧把目标坐标推进 Line2D，节点没了就淡出
class _Trail extends Line2D:
	var _target: Node2D
	var _max_pts := 12
	var _life := 0.18
	var _dying := 0.0
	var _fading := false

	func setup(target: Node2D, col: Color, width: float, points: int, life: float) -> void:
		_target = target
		_max_pts = points
		_life = life
		width = width
		default_color = col
		joint_mode = Line2D.LINE_JOINT_ROUND
		begin_cap_mode = Line2D.LINE_CAP_ROUND
		end_cap_mode = Line2D.LINE_CAP_ROUND
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.0))
		g.set_color(1, Color(1, 1, 1, 0.85))
		gradient = g

	func _process(delta: float) -> void:
		if _fading:
			_dying += delta
			modulate.a = maxf(1.0 - _dying / _life, 0.0)
			if modulate.a <= 0.0:
				queue_free()
			return
		if _target == null or not is_instance_valid(_target):
			_fading = true
			return
		add_point(_target.global_position)
		while get_point_count() > _max_pts:
			remove_point(0)
