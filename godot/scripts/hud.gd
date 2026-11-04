# Lapisan kontrol layar sentuh: joystick (kiri bawah), tombol Pakai (kanan bawah), teks info.
# Posisi memperhitungkan area aman (poni, status bar, navigation bar) bila tersedia.
extends CanvasLayer

signal gerak(v: Vector2)
signal pakai()

var joystick: Control
var tombol_pakai: Button
var info: Label
var margin_aman := Vector2.ZERO

func _ready() -> void:
	margin_aman = _hitung_area_aman()
	joystick = preload("res://scripts/joystick.gd").new()
	joystick.berubah.connect(func(v): gerak.emit(v))
	add_child(joystick)

	tombol_pakai = Button.new()
	tombol_pakai.text = "Pakai"
	tombol_pakai.custom_minimum_size = Vector2(170, 170)
	tombol_pakai.add_theme_font_size_override("font_size", 40)
	tombol_pakai.pressed.connect(func(): pakai.emit())
	add_child(tombol_pakai)

	info = Label.new()
	info.add_theme_font_size_override("font_size", 30)
	info.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	info.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
	info.add_theme_constant_override("outline_size", 6)
	info.position = Vector2(24, 24) + margin_aman
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	get_viewport().size_changed.connect(_susun)
	_susun()

func _susun() -> void:
	var ukuran := get_viewport().get_visible_rect().size
	joystick.position = Vector2(40, ukuran.y - joystick.custom_minimum_size.y - 40) + Vector2(margin_aman.x, -margin_aman.y)
	joystick.size = joystick.custom_minimum_size
	tombol_pakai.position = Vector2(ukuran.x - 170 - 40, ukuran.y - 170 - 60) - margin_aman * Vector2(1, -1)
	info.size = Vector2(maxf(200.0, ukuran.x - 48.0 - margin_aman.x), 0)

func tampilkan(teks: String) -> void:
	info.text = teks

func _hitung_area_aman() -> Vector2:
	var layar := DisplayServer.screen_get_size()
	var aman := DisplayServer.get_display_safe_area()
	if layar.x <= 0 or aman.size.x <= 0:
		return Vector2.ZERO
	# sisi kiri dan bawah, dalam piksel layar; dipakai sebagai margin tambahan
	return Vector2(aman.position.x, layar.y - aman.end.y)
