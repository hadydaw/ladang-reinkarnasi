# Joystick layar sentuh. Keluaran: vektor arah dalam rentang -1..1 saat jari ditekan.
extends Control

signal berubah(v: Vector2)

const RADIUS := 90.0
var aktif_indeks := -1
var nilai := Vector2.ZERO
var pusat_layar := Vector2.ZERO   # posisi pusat joystick (px, koordinat global)

func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.6, RADIUS * 2.6)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and aktif_indeks == -1:
			aktif_indeks = event.index
			_atur(event.position)
			accept_event()
		elif not event.pressed and event.index == aktif_indeks:
			_lepas()
			accept_event()
	elif event is InputEventScreenDrag and event.index == aktif_indeks:
		_atur(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			aktif_indeks = 0
			_atur(event.position)
		else:
			_lepas()
		accept_event()
	elif event is InputEventMouseMotion and aktif_indeks == 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_atur(event.position)
		accept_event()

func _atur(lokal: Vector2) -> void:
	var pusat := size * 0.5
	var v := lokal - pusat
	if v.length() > RADIUS:
		v = v.normalized() * RADIUS
	nilai = v / RADIUS
	queue_redraw()
	berubah.emit(nilai)

func _lepas() -> void:
	aktif_indeks = -1
	nilai = Vector2.ZERO
	queue_redraw()
	berubah.emit(nilai)

func _draw() -> void:
	var pusat := size * 0.5
	draw_circle(pusat, RADIUS, Color(0.12, 0.08, 0.05, 0.45))
	draw_arc(pusat, RADIUS, 0, TAU, 64, Color(0.88, 0.67, 0.35, 0.8), 4.0)
	draw_circle(pusat + nilai * RADIUS * 0.6, RADIUS * 0.42, Color(0.75, 0.48, 0.23, 0.85))
