extends RefCounted
class_name FRONTLINEPlayerAudio

## Пул персональных SFX игрока, акустика помещения и звук шагов.
## Компонент владеет плеерами и таймерами, игрок только запрашивает звук.

const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")
const SFX_FOOTSTEPS = [
	preload("res://assets/audio/footstep_000.ogg"),
	preload("res://assets/audio/footstep_001.ogg"),
	preload("res://assets/audio/footstep_002.ogg"),
]

var sfx_shot: AudioStreamPlayer
var sfx_empty: AudioStreamPlayer
var sfx_reload_out: AudioStreamPlayer
var sfx_reload_in: AudioStreamPlayer
var sfx_ui: AudioStreamPlayer
var sfx_footstep: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_kill: AudioStreamPlayer
var footstep_timer := 0.0
var indoor_factor := 0.0

var _player: CharacterBody3D
var _acoustic_timer := 0.0

func setup(player: CharacterBody3D) -> void:
	_player = player
	sfx_shot = _make_sfx(COMBAT_AUDIO.BUS_COMBAT_DIRECT)
	sfx_empty = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_reload_out = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_reload_in = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_ui = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_footstep = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_hit = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_kill = _make_sfx(COMBAT_AUDIO.BUS_SFX)

func play(player: AudioStreamPlayer, stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func play_shot(weapon_id: String) -> void:
	var profile: Dictionary = COMBAT_AUDIO.WEAPON_PROFILES.get(weapon_id, {})
	# Высота уже зашита в ресемплированный сэмпл банка; второй pitch-множитель
	# делал звук мультяшным.
	var pitch := randf_range(0.97, 1.03)
	var volume: float = float(profile.get("vol", -2.0))
	if indoor_factor > 0.35:
		volume += indoor_factor * 1.5
		sfx_shot.bus = COMBAT_AUDIO.BUS_INDOOR_REVERB
	else:
		sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
	play(sfx_shot, WEAPON_SOUND.get_shot(weapon_id), volume, pitch)

func update_acoustics(delta: float) -> void:
	_acoustic_timer -= delta
	if _acoustic_timer > 0.0:
		return
	_acoustic_timer = 0.25 # 4 раза в секунду — оптимально для 60 FPS на мобилках
	var camera: Camera3D = _player.get("camera")
	if camera == null or not _player.is_inside_tree():
		return
	var world_3d := _player.get_world_3d()
	var under_roof := COMBAT_AUDIO.is_indoors(world_3d, camera.global_position, 8.5)
	var target_factor := 1.0 if under_roof else 0.0
	indoor_factor = lerpf(indoor_factor, target_factor, 0.45)

func update_footsteps(delta: float, planar_speed: float, on_floor: bool, walk_speed: float) -> void:
	if planar_speed <= 0.4 or not on_floor:
		return
	footstep_timer -= delta
	if footstep_timer > 0.0:
		return
	footstep_timer = 0.32 if planar_speed > walk_speed + 0.5 else 0.48
	var stream: AudioStream = SFX_FOOTSTEPS[randi() % SFX_FOOTSTEPS.size()]
	play(sfx_footstep, stream, -14.0, randf_range(0.92, 1.08))

func _make_sfx(bus_name: StringName = &"SFX") -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.max_polyphony = 4
	player.bus = bus_name
	_player.add_child(player)
	return player
