# Screenshot untuk pengecekan visual (dijalankan dengan display virtual).
extends SceneTree

var kebun
var frame := 0
var mode := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	mode = args[0] if args.size() > 0 else "portrait"
	if mode == "landscape":
		DisplayServer.window_set_size(Vector2i(1280, 720))
	else:
		DisplayServer.window_set_size(Vector2i(720, 1280))
	kebun = load("res://scenes/Kebun.tscn").instantiate()
	root.add_child(kebun)

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5 and mode != "still":
		kebun.uji_masukan(Vector2(0.7, -0.7))
	if frame == 60:
		kebun.uji_masukan(Vector2.ZERO)
		if mode != "still":
			kebun.do_pakai()
	if frame == 90:
		var img := root.get_texture().get_image()
		img.save_png("/home/claude/scratchpad/godot_%s.png" % mode)
		quit(0)
		return true
	return false
