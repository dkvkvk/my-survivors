extends AnimatedSprite2D

## 敌人外观适配器：mob.gd 继续沿用原 %Slime 接口
## （play_walk / play_hurt / modulate），贴图换成 Kenney 两帧怪物（CC0），
## SpriteFrames 纯代码构建，贴图路径来自 balance.gd 变体表的 "sprites"。


const WALK_FPS := 6.0

var _base_scale: Vector2


func _ready():
	_base_scale = scale


## 按变体贴图对构建两帧走路动画并播放
func set_variant(paths: Array) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("walk")
	frames.set_animation_speed("walk", WALK_FPS)
	frames.set_animation_loop("walk", true)
	for p in paths:
		frames.add_frame("walk", load(p))
	sprite_frames = frames
	play("walk")


func play_walk():
	# _ready 可能早于 setup() 的 set_variant()，动画尚未建好时静默跳过
	if sprite_frames != null and sprite_frames.has_animation("walk"):
		if animation != "walk" or not is_playing():
			play("walk")


## 受击：短促压扁回弹，配合 Juice.flash 的白闪
func play_hurt():
	var tw := create_tween()
	tw.tween_property(self, "scale", _base_scale * Vector2(1.25, 0.75), 0.05)
	tw.tween_property(self, "scale", _base_scale, 0.12)
