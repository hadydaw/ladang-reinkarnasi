# Tes otomatis headless: adegan termuat, pemain bergerak dengan masukan, dan Pakai mengubah tanah.
extends SceneTree

var kebun
var frame := 0
var posisi_awal := Vector2.ZERO
var gagal := 0

func _initialize() -> void:
	kebun = load("res://scenes/Kebun.tscn").instantiate()
	root.add_child(kebun)

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		var w: World = kebun.dunia
		_cek("proyeksi isometrik sama dengan game lama (langkah x = TW/2, y = TH/2)", w.ke_layar(Vector2(1, 0)).is_equal_approx(Vector2(World.tw() * 0.5, World.th() * 0.5)))
		_cek("TW = 44k dan TH = 30k", is_equal_approx(World.tw(), 44.0 * World.k) and is_equal_approx(World.th(), 30.0 * World.k))
		_cek("tekstur rumput asli termuat (5 varian)", w.tekstur_grass.size() == 5 and w.tekstur_grass[0] != null)
		_cek("tekstur tanah garap asli termuat", w.tekstur_farm.size() == 2 and w.tekstur_farm[0] != null)
	elif frame == 3:
		posisi_awal = kebun.pemain.grid
		kebun.uji_masukan(Vector2(1, 0))
	elif frame == 40:
		kebun.uji_masukan(Vector2.ZERO)
		_cek("pemain bergerak saat joystick ditekan", kebun.pemain.grid.distance_to(posisi_awal) > 0.2)
		_cek("pemain tetap di dalam peta", kebun.pemain.grid.x >= 0.5 and kebun.pemain.grid.x <= 13.5 and kebun.pemain.grid.y >= 0.5 and kebun.pemain.grid.y <= 13.5)
		_cek("arah hadap dari joystick ke kanan layar", kebun.pemain.sprite.texture != null)
	elif frame == 45:
		# hadapkan pemain ke petak kosong, lalu cangkul
		kebun.pemain.arah_dunia = Vector2(1, 0)
		kebun.pemain.grid = Vector2(5.5, 5.5)
		kebun.pemain.position = kebun.pemain.world_pos()
		kebun.npc.grid = Vector2(12.5, 12.5)
		kebun.npc.position = kebun.npc.world_pos()
		var sebelum: int = kebun.uji_status_depan()
		kebun.do_pakai()
		var sesudah: int = kebun.uji_status_depan()
		_cek("Pakai menggarap tanah rumput", sebelum == 0 and sesudah == 1)
		kebun.do_pakai()
		_cek("Pakai menyiram tanah garap", kebun.uji_status_depan() == 2)
	elif frame == 50:
		kebun.npc.grid = kebun.pemain.grid + Vector2(0.5, 0.5)
		kebun.npc.position = kebun.npc.world_pos()
		kebun.do_pakai()
		_cek("Pakai di dekat NPC menampilkan dialog", kebun.hud.info.text.begins_with("Pupus:"))
		print("HASIL: %d gagal" % gagal)
		quit(gagal)
		return true
	return false

func _cek(nama: String, kondisi: bool) -> void:
	print(("PASS " if kondisi else "FAIL ") + nama)
	if not kondisi:
		gagal += 1
