# Dunia isometrik berbasis TileMapLayer + TileSet.
# Ukuran tile mengikuti aset asli: 256 x 155 px (diamond penuh), langkah 128 x 77.5 px.
# Aset tidak diregangkan: setiap PNG/WebP dipakai dalam ukuran aslinya.
extends Node2D

const TILE_W := 256
const TILE_H := 155
const HALF_W := 128.0
const HALF_H := 77.5   # TILE_H / 2
const N := 14          # ukuran peta N x N petak

const TANAH_RUMPUT := 0
const TANAH_GARAP := 1
const TANAH_BASAH := 2

const RUMPUT := [
	"res://assets/terrain/terrain_001.webp",
	"res://assets/terrain/terrain_002.webp",
	"res://assets/terrain/terrain_003.webp",
	"res://assets/terrain/terrain_004.webp",
	"res://assets/terrain/terrain_005.webp",
]
const GARAP := "res://assets/terrain/terrain_011.webp"

const TUMPANG := 1.03   # tile ditumpuk sedikit (skala seragam) agar tepi bevel aset tidak tampak sebagai garis
var ts: TileSet
var petak: Array = []   # petak[gy][gx] = status tanah
var id_rumput: Array = []
var id_garap := -1
var id_basah := -1

func _ready() -> void:
	petak.resize(N)
	for gy in N:
		var baris: Array = []
		baris.resize(N)
		baris.fill(TANAH_RUMPUT)
		petak[gy] = baris

	ts = _bangun_tileset()
	# latar di balik sudut transparan tile diisi warna rumput, bukan abu-abu
	RenderingServer.set_default_clear_color(Color(0.22, 0.27, 0.12))
	queue_redraw()

func _bangun_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(TILE_W, TILE_H)
	var id := 0
	for path in RUMPUT:
		_tambah_sumber(ts, id, load(path), Color(1, 1, 1))
		id_rumput.append(id)
		id += 1
	id_garap = id
	_tambah_sumber(ts, id, load(GARAP), Color(1, 1, 1))
	id += 1
	id_basah = id
	_tambah_sumber(ts, id, load(GARAP), Color(0.66, 0.6, 0.55))  # tanah basah: aset yang sama, lebih gelap
	return ts

func _tambah_sumber(ts: TileSet, id: int, tex: Texture2D, warna: Color) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE_W, TILE_H)
	ts.add_source(src, id)
	src.create_tile(Vector2i.ZERO)
	src.get_tile_data(Vector2i.ZERO, 0).modulate = warna

# Sumber tile (TileSet) untuk setiap petak. Varian rumput tetap per petak.
func _sumber(gx: int, gy: int) -> int:
	var st: int = petak[gy][gx]
	if st == TANAH_GARAP:
		return id_garap
	if st == TANAH_BASAH:
		return id_basah
	return id_rumput[(gx * 7 + gy * 13) % id_rumput.size()]

func _draw() -> void:
	if ts == null:
		return
	for gy in N:
		for gx in N:
			var sumber := ts.get_source(_sumber(gx, gy)) as TileSetAtlasSource
			var tex := sumber.texture
			var ukuran := Vector2(TILE_W, TILE_H) * TUMPANG
			var pusat := ke_layar(Vector2(gx + 0.5, gy + 0.5))
			draw_texture_rect(tex, Rect2(pusat - ukuran * 0.5, ukuran), false, sumber.get_tile_data(Vector2i.ZERO, 0).modulate)

# Proyeksi (x, y) dalam satuan petak ke layar. Dipakai aktor dan objek.
static func ke_layar(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * HALF_W, (g.x + g.y) * HALF_H)

func di_dalam(gx: int, gy: int) -> bool:
	return gx >= 0 and gy >= 0 and gx < N and gy < N

func status(gx: int, gy: int) -> int:
	return petak[gy][gx]

func atur_status(gx: int, gy: int, nilai: int) -> void:
	petak[gy][gx] = nilai
	queue_redraw()
