extends CanvasLayer

## 全局过渡与屏幕效果（U7 美化）：autoload 常驻，跨场景守夜。
## - 暗角滤镜：全屏轻量后期，聚焦画面中心
## - 黑场过渡：fade_to_scene() 先淡出再切场景再淡入，遮住场景加载跳变
## 两个 ColorRect 均 mouse_filter = IGNORE，不挡任何点击。


const FADE_TIME := 0.35

var _fade_rect: ColorRect


func _ready():
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://vignette.gdshader")
	vignette.material = mat
	add_child(vignette)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	fade_in()


## 从黑场淡入（启动/进入新场景后）。
func fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, FADE_TIME)


## 淡出 → 切场景 → 淡入。切游戏/回主菜单/重开都走这里。
func fade_to_scene(path: String) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, FADE_TIME)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))
	tw.tween_interval(0.05)  # 给新场景留出首帧
	tw.tween_property(_fade_rect, "color:a", 0.0, FADE_TIME)
