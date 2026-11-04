# Dunia isometrik: lantai petak dan status tanah (kering, tergarap, basah).
extends Node2D

const TW := 256.0   # lebar petak isometrik (px)
const TH := 128.0   # tinggi petak isometrik (px)
const N := 14       # ukuran peta N x N petak

const TANAH_RUMPUT := 0
const TANAH_GARAP := 1
const TANAH_BASAH := 2

var tex_rumput: Texture2D
var tex_garap: Texture2D
var petak: Array = []   # petak[gy][gx] = status tanah

func _ready() -> void:
	tex_rumput = load("res://assets/terrain/terrain_001.webp")
	tex_garap = load("res://assets/terrain/terrain_011.webp")
	petak.resize(N)
	for gy in N:
		var baris: Array = []
		baris.resize(N)
		baris.fill(TANAH_RUMPUT)
		petak[gy] = baris

# Proyeksi petak (gx, gy) ke layar; pusat petak.
static func ke_layar(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * TW * 0.5, (g.x + g.y) * TH * 0.5)

static func dari_layar(p: Vector2) -> Vector2:
	var a := p.x / (TW * 0.5)
	var b := p.y / (TH * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)

func di_dalam(gx: int, gy: int) -> bool:
	return gx >= 0 and gy >= 0 and gx < N and gy < N

func status(gx: int, gy: int) -> int:
	return petak[gy][gx]

func atur_status(gx: int, gy: int, nilai: int) -> void:
	petak[gy][gx] = nilai
	queue_redraw()

func _draw() -> void:
	for gy in N:
		for gx in N:
			var tex := tex_garap if petak[gy][gx] != TANAH_RUMPUT else tex_rumput
			var warna := Color(1, 1, 1)
			if petak[gy][gx] == TANAH_BASAH:
				warna = Color(0.66, 0.6, 0.55)
			var pusat := ke_layar(Vector2(gx + 0.5, gy + 0.5))
			draw_texture(tex, pusat - tex.get_size() * 0.5, warna)
