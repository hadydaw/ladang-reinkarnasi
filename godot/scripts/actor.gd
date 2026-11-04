# Aktor berbasis petak: pemain dan NPC. Arah tampilan dipilih dari arah gerak di layar.
extends Node2D

const SKALA := 0.5
const KECEPATAN := 2.4   # petak per detik

var grid := Vector2.ZERO  # posisi di peta (petak, desimal)
var arah_dunia := Vector2(0, 1)   # arah hadap terakhir di peta
var sprite: Sprite2D
var frames := {}          # "depan" -> [Texture2D, ...]
var langkah := 0.0
var jalan := false
var masukan := Vector2.ZERO   # arah layar, dari joystick (panjang 0..1)

func siapkan(nama: String, frame_dasar: Dictionary, frame_jalan: Dictionary, awal: Vector2) -> void:
	grid = awal
	for arah in frame_dasar.keys():
		var daftar: Array = [load(frame_dasar[arah])]
		if frame_jalan.has(arah):
			daftar.append(load(frame_jalan[arah]))
		frames[arah] = daftar
	sprite = Sprite2D.new()
	sprite.name = nama
	sprite.centered = false
	sprite.scale = Vector2(SKALA, SKALA)
	add_child(sprite)
	_atur_gambar("depan", 0)
	position = world_pos()

func world_pos() -> Vector2:
	return world_ke_layar(grid)

func world_ke_layar(g: Vector2) -> Vector2:
	return ke_layar_peta(g)

static func ke_layar_peta(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * 128.0, (g.x + g.y) * 64.0)

# Arah layar (x kanan, y bawah) dipetakan ke salah satu gambar hadap.
static func arah_gambar(v: Vector2) -> String:
	if v.length() < 0.01:
		return ""
	if absf(v.x) > absf(v.y) * 2.0:
		return "kanan" if v.x > 0 else "kiri"
	if absf(v.y) > absf(v.x) * 2.0:
		return "depan" if v.y > 0 else "belakang"
	return "serongkanan" if v.x > 0 else "serongkiri"

func _atur_gambar(arah: String, bingkai: int) -> void:
	if not frames.has(arah):
		arah = "depan"
	var daftar: Array = frames[arah]
	sprite.texture = daftar[bingkai % daftar.size()]
	# kaki tokoh berada di titik posisi node
	sprite.position = Vector2(-sprite.texture.get_width() * SKALA * 0.5, -sprite.texture.get_height() * SKALA + 24)

func set_masukan(v: Vector2) -> void:
	masukan = v

# Gerak di peta. Input layar diubah ke arah peta, lalu dibatasi di dalam peta.
func gerak(delta: float, batas: float) -> void:
	if masukan.length() < 0.05:
		jalan = false
		return
	var v := masukan.normalized() * minf(masukan.length(), 1.0)
	var a := 128.0
	var b := 64.0
	var dunia := Vector2((v.x / a + v.y / b) * 0.5, (v.y / b - v.x / a) * 0.5).normalized()
	arah_dunia = dunia
	grid += dunia * KECEPATAN * v.length() * delta
	grid = Vector2(clampf(grid.x, 0.5, batas - 0.5), clampf(grid.y, 0.5, batas - 0.5))
	position = world_pos()
	jalan = true
	langkah += delta * 6.0
	var arah_s := arah_gambar(v)
	_atur_gambar(arah_s, int(langkah) % 2 if jalan else 0)
	z_index = int(grid.x + grid.y) * 2 + 1

func diam_dan_hadap() -> void:
	jalan = false
	z_index = int(grid.x + grid.y) * 2 + 1
