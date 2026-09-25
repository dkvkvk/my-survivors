extends Node2D

## 守山人角色外观（素材：Ninja Adventure，CC0）。
## 自动读取父节点（Player）的速度，按主轴方向播放四向走路/待机动画。
## 物理与碰撞仍在 player.tscn 上，这里只负责外观。

const SHEET := preload("res://assets/hero/ninja_sheet.png")
const SHADOW := preload("res://assets/hero/shadow.png")
const FRAME := 16
# 精灵表列 = 朝向（下0 上1 左2 右3；行 0=待机帧，行 0-3=走路循环）
#
# ⚠️ 朝向列必须"帧间自洽"才拿来当走路循环——否则播起来像边走边转身。
# 2026-09-24 在**当前的守山人表**上重测（每帧不透明像素质心 + 肤色质心）：
#   col0 质心 7.1/7.1/7.1/7.0  ✅ 自洽
#   col1 质心 6.7/6.6/6.7/6.7  ✅ 自洽
#   col2 质心 6.5/6.4/6.5/6.5，脸一律在左  ✅ 自洽（面朝左）
#   col3 质心 8.5/6.4/6.5/6.5，**row0 整体右移 2px 且脸朝右，其余 3 帧脸朝左**  ❌ 这一列不能用来播走路
# 所以：左向直接用 col2，右向**镜像 col2**（镜像自洽的列 = 自洽的反向走路），
# 坏掉的 col3 整个不用。HANDOVER 坑 #11b 的"col2 坏 / col3 好"是**旧忍者表**上的结论，
# 换表后失效——L0 判据 hero-columns 现在会机器校验这件事（自洽性 + 朝向符号）。
const DIR_COL := {"down": 0, "up": 1, "left": 2}
const MIRROR_OF := {"right": "left"}
# 6.0：新敌人素材比旧素材高大，主角同步放大才不会显得是"小不点"
const SPRITE_SCALE := 6.6

var _sprite: AnimatedSprite2D
var _last_dir := "down"


func _ready():
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	_sprite.position = Vector2(0, -22)
	# 身份配色（P7 多角色）：代码调色，不需要额外美术（独立行走表见 XIANXIA_ART_PROMPTS 第八节 B 组）
	var tint: Color = Characters.current_def().get("tint", Color(1, 1, 1))
	_sprite.modulate = tint
	add_child(_sprite)
	_sprite.play("idle_down")

	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.scale = Vector2.ONE * 4.5
	shadow.position = Vector2(0, 14)
	shadow.modulate = Color(0, 0, 0, 0.35)
	shadow.show_behind_parent = true
	add_child(shadow)


## 用区域贴图切精灵表：每个朝向一条待机（1 帧）+ 一条走路（4 帧循环）
func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	# 有独立素材的朝向
	for dir in DIR_COL:
		_add_dir_anims(frames, dir, DIR_COL[dir])
	# 镜像朝向（左向复用右向的列，播放时由 _sprite.flip_h 翻转）
	for dir in MIRROR_OF:
		_add_dir_anims(frames, dir, DIR_COL[MIRROR_OF[dir]])
	return frames


## 给一个朝向建 idle_xxx / walk_xxx 两条动画
func _add_dir_anims(frames: SpriteFrames, dir: String, col: int) -> void:
	var idle: String = "idle_" + dir
	frames.add_animation(idle)
	frames.add_frame(idle, _frame(col, 0))
	var walk: String = "walk_" + dir
	frames.add_animation(walk)
	frames.set_animation_speed(walk, 8.0)
	frames.set_animation_loop(walk, true)
	for row in 4:
		frames.add_frame(walk, _frame(col, row))


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
	# 右向是左向（col2）的镜像，播放时水平翻转
	_sprite.flip_h = _last_dir == "right"
	if _sprite.animation != want or not _sprite.is_playing():
		_sprite.play(want)
