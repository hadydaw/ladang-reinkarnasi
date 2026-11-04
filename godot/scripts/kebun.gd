# Adegan utama prototipe kebun: merakit dunia, pemain, NPC, pohon, kamera, dan HUD.
extends Node2D

const World = preload("res://scripts/world.gd")
const Actor = preload("res://scripts/actor.gd")
const Npc = preload("res://scripts/npc.gd")
const HudScript = preload("res://scripts/hud.gd")

var dunia
var benda: Node2D
var pemain
var npc
var kamera: Camera2D
var hud

func _ready() -> void:
	dunia = World.new()
	dunia.z_index = -100
	add_child(dunia)

	benda = Node2D.new()
	benda.y_sort_enabled = true
	add_child(benda)

	pemain = Actor.new()
	benda.add_child(pemain)
	pemain.siapkan("Rose", {
		"depan": "res://assets/sprite/sprites_depan_001.webp",
		"belakang": "res://assets/sprite/sprites_belakang_001.webp",
		"kiri": "res://assets/sprite/sprites_kiri_001.webp",
		"kanan": "res://assets/sprite/sprites_kanan_001.webp",
		"serongkiri": "res://assets/sprite/sprites_serongkiri_001.webp",
		"serongkanan": "res://assets/sprite/sprites_serongkanan_001.webp",
	}, {
		"depan": "res://assets/sprite/sprite_walk_depan_001.webp",
		"belakang": "res://assets/sprite/sprite_walk_belakang_001.webp",
		"kiri": "res://assets/sprite/sprite_walk_kiri_001.webp",
		"kanan": "res://assets/sprite/sprite_walk_kanan_001.webp",
		"serongkiri": "res://assets/sprite/sprite_walk_serongkiri_001.webp",
		"serongkanan": "res://assets/sprite/sprite_walk_serongkanan_001.webp",
	}, Vector2(6.5, 6.5))

	npc = Npc.new()
	benda.add_child(npc)
	npc.siapkan("Pupus", {"depan": "res://assets/sprite/sprites_depan_002.webp"}, {}, Vector2(9.5, 6.5))
	npc.tujuan = npc.grid

	for p in [[2.5, 3.5, "res://assets/bangunan/tree_assets_001.webp"], [11.5, 2.5, "res://assets/bangunan/tree_assets_002.webp"], [3.5, 11.5, "res://assets/bangunan/tree_assets_002.webp"], [12.5, 11.5, "res://assets/bangunan/tree_assets_001.webp"]]:
		var pohon := Sprite2D.new()
		pohon.texture = load(p[2])
		pohon.centered = false
		pohon.scale = Vector2(0.5, 0.5)
		var kaki := Actor.ke_layar_peta(Vector2(p[0], p[1]))
		pohon.position = kaki - Vector2(pohon.texture.get_width() * 0.25, pohon.texture.get_height() * 0.5)
		pohon.z_index = 0
		benda.add_child(pohon)

	kamera = Camera2D.new()
	kamera.position_smoothing_enabled = true
	add_child(kamera)
	kamera.make_current()

	hud = HudScript.new()
	add_child(hud)
	hud.gerak.connect(func(v): pemain.set_masukan(v))
	hud.pakai.connect(do_pakai)
	hud.tampilkan("Geser joystick untuk berjalan. Pakai untuk mencangkul atau bicara.")

func _process(delta: float) -> void:
	World.k = clampf(get_viewport_rect().size.x / 420.0 * 1.25, 1.0, 1.8)
	dunia.set_pusat(pemain.grid)
	pemain.gerak(delta, World.W)
	kamera.position = pemain.position + Vector2(0, -80)

func do_pakai() -> void:
	if pemain.grid.distance_to(npc.grid) < 1.6:
		hud.tampilkan("Pupus: " + npc.bicara())
		return
	var target: Vector2 = pemain.grid + pemain.arah_dunia.normalized() * 0.9
	var gx := int(floor(target.x))
	var gy := int(floor(target.y))
	if not dunia.di_dalam(gx, gy):
		hud.tampilkan("Tidak ada tanah di sana.")
		return
	match dunia.status(gx, gy):
		World.TANAH_RUMPUT:
			dunia.atur_status(gx, gy, World.TANAH_GARAP)
			hud.tampilkan("Tanah sudah digarap.")
		World.TANAH_GARAP:
			dunia.atur_status(gx, gy, World.TANAH_BASAH)
			hud.tampilkan("Tanah sudah disiram.")
		_:
			hud.tampilkan("Tanah ini sudah basah.")

# Dipakai tes otomatis: masukan arah layar dan status petak di depan pemain.
func uji_masukan(v: Vector2) -> void:
	pemain.set_masukan(v)

func uji_status_depan() -> int:
	var target: Vector2 = pemain.grid + pemain.arah_dunia.normalized() * 0.9
	return dunia.status(int(floor(target.x)), int(floor(target.y)))
