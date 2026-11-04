# NPC sederhana: diam, lalu berjalan pelan ke petak acak, dan bisa diajak bicara dengan tombol Pakai.
extends "res://scripts/actor.gd"

var tunggu := 2.0
var tujuan := Vector2.ZERO
var ucapan := ["Halo! Panen kamu bagus hari ini.", "Mau aku bantu cangkul?", "Ladang ini tenang ya."]
var urutan := 0

func _process(delta: float) -> void:
	tunggu -= delta
	if tunggu > 0.0:
		diam_dan_hadap()
		return
	var selisih := tujuan - grid
	if selisih.length() < 0.1:
		tujuan = grid + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		tujuan = Vector2(clampf(tujuan.x, 1.0, 12.0), clampf(tujuan.y, 1.0, 12.0))
		tunggu = randf_range(2.0, 4.0)
		return
	set_masukan(world_ke_layar(selisih.normalized()) * 0.5)
	gerak(delta, 14.0)
	set_masukan(Vector2.ZERO)

func bicara() -> String:
	var teks: String = ucapan[urutan % ucapan.size()]
	urutan += 1
	return teks
