extends Node2D
class_name World
# Terjemahan langsung dari src/game.html (Kebun):
#   iso()          -> ke_layar()      (sx = (x-y)*TW/2, sy = (x+y)*TH/2, TW = 44k, TH = 30k)
#   TERRAIN.grass  -> TERRAIN_GRASS   (transform affine v: puncak, kiri, kanan)
#   drawTileImg()  -> _gambar_tile()  (gambar dipetakan affine ke diamond, diperbesar 2% untuk menutup sambungan)
#   groundFor()    -> _tanah()        (varian rumput memakai vnoise, arah gambar memakai hash)
#   hash()         -> hash_tanah()    (wseed 0, seperti game lama)
# Belum dimigrasi di tahap ini: jalan (natural), lahan garap dan tanam (farm), sungai, dekorasi.

const W := 100                 # dunia 100 x 100 petak (game.html: W = 100)
const MARGIN := 30             # tanah diperpanjang di luar peta (game.html: MG = 30)
const RADIUS_GAMBAR := 26      # radius petak yang digambar di sekitar pemain (efisiensi)
const TANAH_RUMPUT := 0
const TANAH_GARAP := 1
const TANAH_BASAH := 2

# TERRAIN.grass dan TERRAIN.farm dari game.html (urutan sama). v = [puncakX, puncakY, kiriX, kiriY, kananX, kananY]
const TERRAIN_GRASS := [
	["res://assets/terrain/terrain_001.webp", [129.0, 0.0, 0.0, 74.0, 255.0, 71.0]],
	["res://assets/terrain/terrain_002.webp", [127.5, 0.0, 0.0, 74.0, 255.0, 73.0]],
	["res://assets/terrain/terrain_003.webp", [128.0, 0.0, 0.0, 74.0, 255.0, 73.0]],
	["res://assets/terrain/terrain_004.webp", [128.0, 0.0, 0.0, 82.0, 255.0, 72.0]],
	["res://assets/terrain/terrain_005.webp", [128.0, 0.0, 0.0, 75.0, 255.0, 73.0]],
]
# farm: 0 kering, 1 basah (urutan dari groundFor)
const TERRAIN_FARM := [
	["res://assets/terrain/terrain_011.webp", [129.5, 0.0, 0.0, 91.0, 255.0, 91.0]],
	["res://assets/terrain/terrain_012.webp", [127.5, 0.0, 0.0, 91.0, 255.0, 91.0]],
]

# Skala layar, sama dengan resize() di game.html: k = clamp(lebar / 420 * 1.25, 1, 1.8)
static var k := 1.0

static func tw() -> float:
	return 44.0 * k

static func th() -> float:
	return 30.0 * k

# Proyeksi isometrik game lama. Titik (x, y) adalah sudut kiri atas petak.
static func ke_layar(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * tw() * 0.5, (g.x + g.y) * th() * 0.5)

# Konversi int ke int32 seperti operator JavaScript (^ dan |)
static func _i32(v: int) -> int:
	var m := v & 0xFFFFFFFF
	if m >= 0x80000000:
		m -= 0x100000000
	return m

# hash() dari game.html dengan wseed 0
static func hash_tanah(x: int, y: int) -> float:
	var h := _i32(x * 73856093) ^ _i32(y * 19349663)
	return float(absi(h) % 1000) / 1000.0

# vnoise() dari game.html: noise halus agar varian tile membentuk area yang menyatu
static func vnoise(x: int, y: int, sc: float) -> float:
	var gx := float(x) / sc
	var gy := float(y) / sc
	var x0 := floorf(gx)
	var y0 := floorf(gy)
	var fx := gx - x0
	var fy := gy - y0
	var u := fx * fx * (3.0 - 2.0 * fx)
	var v := fy * fy * (3.0 - 2.0 * fy)
	var xi := int(x0)
	var yi := int(y0)
	var a := hash_tanah(xi + 777, yi + 333)
	var b := hash_tanah(xi + 778, yi + 333)
	var c := hash_tanah(xi + 777, yi + 334)
	var d := hash_tanah(xi + 778, yi + 334)
	var top := a + (b - a) * u
	var bot := c + (d - c) * u
	return top + (bot - top) * v

var tekstur_grass: Array[Texture2D] = []
var tekstur_farm: Array[Texture2D] = []
var pusat := Vector2i(W / 2, W / 2)   # petak pemain, pusat area yang digambar
var petak := {}                       # Vector2i -> status tanah (sementara, sampai migrasi ladang)

func _ready() -> void:
	for e in TERRAIN_GRASS:
		tekstur_grass.append(load(e[0]))
	for e in TERRAIN_FARM:
		tekstur_farm.append(load(e[0]))

# Status tanah petak (sementara: hanya status garap dan basah)
func di_dalam(gx: int, gy: int) -> bool:
	return gx >= 0 and gy >= 0 and gx < W and gy < W

func status(gx: int, gy: int) -> int:
	return petak.get(Vector2i(gx, gy), TANAH_RUMPUT)

func atur_status(gx: int, gy: int, nilai: int) -> void:
	petak[Vector2i(gx, gy)] = nilai
	queue_redraw()

func set_pusat(g: Vector2) -> void:
	var p := Vector2i(int(floor(g.x)), int(floor(g.y)))
	if p != pusat:
		pusat = p
		queue_redraw()

func _draw() -> void:
	var xlo := maxi(-MARGIN, pusat.x - RADIUS_GAMBAR)
	var xhi := mini(W - 1 + MARGIN, pusat.x + RADIUS_GAMBAR)
	var ylo := maxi(-MARGIN, pusat.y - RADIUS_GAMBAR)
	var yhi := mini(W - 1 + MARGIN, pusat.y + RADIUS_GAMBAR)
	# urutan dari belakang ke depan (x + y), seperti game lama
	for d in range(xlo + ylo, xhi + yhi + 1):
		for x in range(xlo, xhi + 1):
			var y := d - x
			if y < ylo or y > yhi:
				continue
			_tanah(x, y)

# groundFor() untuk tanah dasar: lahan garap memakai TERRAIN.farm, sisanya rumput
func _tanah(x: int, y: int) -> void:
	var st := status(x, y)
	var flip := hash_tanah(x * 7 + 3, y * 13 + 5) > 0.5
	if st == TANAH_GARAP or st == TANAH_BASAH:
		var idx := 0 if st == TANAH_GARAP else 1
		_gambar_tile(tekstur_farm[idx], TERRAIN_FARM[idx][1], x, y, false)
		return
	var i := clampi(int(floorf(vnoise(x, y, 4.0) * 5.0)), 0, 4)
	_gambar_tile(tekstur_grass[i], TERRAIN_GRASS[i][1], x, y, flip)

# drawTileImg() dari game.html: gambar dipetakan affine dari transform v ke diamond petak
func _gambar_tile(tex: Texture2D, v: Array, x: int, y: int, flip: bool) -> void:
	var T := ke_layar(Vector2(x, y))
	var L := ke_layar(Vector2(x, y + 1))
	var R := ke_layar(Vector2(x + 1, y))
	var Bp := L + R - T
	var C := ke_layar(Vector2(x + 0.5, y + 0.5))
	T -= C
	L -= C
	R -= C
	Bp -= C
	# diamond pemotong selalu tidak dibalik, arah gambar yang dibalik
	var clip := [T * 1.02, R * 1.02, Bp * 1.02, L * 1.02]
	var Ld := R if flip else L
	var Rd := L if flip else R
	var Ts := Vector2(v[0], v[1])
	var Ls := Vector2(v[2], v[3])
	var Rs := Vector2(v[4], v[5])
	var e1 := Rs - Ts
	var e2 := Ls - Ts
	var f1 := Rd - T
	var f2 := Ld - T
	var det := f1.x * f2.y - f2.x * f1.y
	var ukuran := tex.get_size()
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for p in clip:
		var dv: Vector2 = p - T
		var a := (dv.x * f2.y - f2.x * dv.y) / det
		var b := (f1.x * dv.y - dv.x * f1.y) / det
		var img := Ts + a * e1 + b * e2
		pts.append(p + C)   # kembali ke koordinat dunia
		uvs.append(img / ukuran)
	draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)
