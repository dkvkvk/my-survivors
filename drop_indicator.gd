extends Node2D
## 屏幕边缘掉落指示：法宝掉落 / 藏宝匣跑出视野时，在屏幕边缘画金色箭头指向它。
## 为什么只指示这两样：法宝要按 F 捡、藏宝匣是妖王奖励，错过太亏；
## 灵珠/灵石数量多，画箭头会刷屏。颜色沿用全局色彩语言：金 = 奖励。
##
## ⚠️ 为什么画在**世界层**而不是 HUD(CanvasLayer)：实测把本节点挂进 HUD 后，
## 绘制只有落在屏幕中央约 x∈[243,1676] 的区域才可见（HUD 的 Control 子节点也都在
## 这个区域内，所以平时看不出来），左右边缘的箭头会被吞掉。世界层铺满全屏，稳。
## 做法：把"屏幕边缘点"反算成世界坐标再画，于是箭头钉在屏幕上、不随摄像机移动。

const MARGIN := 30.0
const GROUPS := ["weapon_drops", "chests"]

var _t := 0.0


func _ready() -> void:
	z_index = 200
	top_level = true          # 不继承父节点变换，绘制坐标 == 世界坐标


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport_rect().size
	var half := vp * 0.5
	var center: Vector2 = cam.get_screen_center_position()
	var z: Vector2 = cam.zoom
	var inner := Rect2(Vector2(MARGIN, MARGIN), vp - Vector2(MARGIN, MARGIN) * 2.0)
	var pulse := 0.72 + 0.28 * sin(_t * 6.0)
	# 半透明叠在暗地面上会明显变暗（实测被压掉三成），所以透明度给高一点
	var col := Color(1.0, 0.86, 0.42, 0.78 + 0.22 * pulse)
	for g in GROUPS:
		for d in get_tree().get_nodes_in_group(g):
			if not is_instance_valid(d) or not d.is_inside_tree():
				continue
			var sp: Vector2 = ((d as Node2D).global_position - center) * z + half
			if inner.has_point(sp):
				continue
			var edge: Vector2 = sp.clamp(inner.position, inner.position + inner.size)
			var dir: Vector2 = sp - edge
			if dir.length_squared() < 1.0:
				continue
			var w_edge: Vector2 = center + (edge - half) / z
			_draw_arrow(w_edge, dir.normalized(), col)


func _draw_arrow(at: Vector2, dir: Vector2, col: Color) -> void:
	var tip := at + dir * 13.0
	var back := at - dir * 4.0
	var perp := Vector2(-dir.y, dir.x)
	draw_colored_polygon(
		PackedVector2Array([tip, back + perp * 8.5, back - perp * 8.5]), col)
	draw_circle(at - dir * 15.0, 2.5, Color(col.r, col.g, col.b, col.a * 0.65))
