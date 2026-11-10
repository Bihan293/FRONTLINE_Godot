extends RefCounted
class_name FRONTLINEWeaponSoundBank

## Запечённые варианты выстрела. Раньше банк ресемплировал один сэмпл в
## GDScript при первом спавне каждого оружия — это давало фризы 300-600 мс
## и синтетический «8-битный» призвук. Теперь все варианты лежат в assets.

const FALLBACK: AudioStreamWAV = preload("res://assets/audio/weapons/ak47.wav")

const SHOTS := {
	"ak47": preload("res://assets/audio/weapons/ak47.wav"),
	"mp40": preload("res://assets/audio/weapons/mp40.wav"),
	"mosin": preload("res://assets/audio/weapons/mosin.wav"),
	"m1911": preload("res://assets/audio/weapons/m1911.wav"),
	"shotgun": preload("res://assets/audio/weapons/shotgun.wav"),
	"ppsh41": preload("res://assets/audio/weapons/ppsh41.wav"),
	"kar98k": preload("res://assets/audio/weapons/kar98k.wav"),
	"panzerfaust": preload("res://assets/audio/weapons/panzerfaust.wav"),
}

static func get_shot(weapon_id: String) -> AudioStreamWAV:
	return SHOTS.get(weapon_id, FALLBACK)
