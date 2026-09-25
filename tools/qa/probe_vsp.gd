extends SceneTree

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var v := VideoStreamPlayer.new()
	print("VSP expand=%s loop=%s autoplay=%s" % [
		str("expand" in v), str("loop" in v), str("autoplay" in v)])
	var s: VideoStreamTheora = load("res://menu_loop.ogv")
	print("ogv loaded=", s != null, " len=", s.get_length() if s != null else -1)
	return true
