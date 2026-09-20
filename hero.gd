extends Node2D

## 忍者角色外观（素材：Ninja Adventure，CC0）。
## 自动读取父节点（Player）的速度，按主轴方向播放四向走路/待机动画。
## 物理与碰撞仍在 player.tscn 上，这里只负责外观。

const SHEET := preload("res://assets/hero/ninja_sheet.png")
const SHADOW := preload("res://assets/hero/shadow.png")
const FRAME := 16
# 精灵表列 = 朝向（与素材源码一致：下0 上1 左2 右3；行 0=待机帧，0-3=走路循环）
const DIR_COL := {"down": 0, "up": 1, "left": 2, "right": 3}
const SPRITE_SCALE := 4.0

var _sprite: AnimatedSprite2D
var _last_dir := "down"


func _ready():
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	_sprite.position = Vector2(0, -12)
	add_child(_sprite)
	_sprite.play("idle_down")

	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.scale = Vector2.ONE * 3.0
	shadow.position = Vector2(0, 12)
	shadow.modulate = Color(0, 0, 0, 0.35)
	shadow.show_behind_parent = true
	add_child(shadow)


## 用区域贴图切精灵表：每个朝向一条待机（1 帧）+ 一条走路（4 帧循环）
func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for dir in DIR_COL:
		var col: int = DIR_COL[dir]
		var idle: String = "idle_" + dir
		frames.add_animation(idle)
		frames.add_frame(idle, _frame(col, 0))
		var walk: String = "walk_" + dir
		frames.add_animation(walk)
		frames.set_animation_speed(walk, 8.0)
		frames.set_animation_loop(walk, true)
		for row in 4:
			frames.add_frame(walk, _frame(col, row))
	return frames


func _frame(col: int, row: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = SHEET
	tex.region = Rect2(col * FRAME, row * FRAME, FRAME, FRAME)
	return tex


func _process(_delta):
	var v: Vector2 = get_parent().velocity
	var moving := v.length() > 10.0
	if absf(v.x) > absf(v.y):
		if absf(v.x) > 10.0:
			_last_dir = "right" if v.x > 0.0 else "left"
	elif absf(v.y) > 10.0:
		_last_dir = "down" if v.y > 0.0 else "up"
	var want := ("walk_" if moving else "idle_") + _last_dir
	if _sprite.animation != want or not _sprite.is_playing():
		_sprite.play(want)
