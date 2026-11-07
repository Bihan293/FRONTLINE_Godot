extends RefCounted
class_name FRONTLINECombatAudio

## Централизованный менеджер боевой 3D-акустики, шин, окклюзии и пространственных эффектов.
## Реализует:
## - Автоматическую инициализацию шин (CombatDirect, CombatOccluded, IndoorReverb)
## - Проверку физической окклюзии (препятствия между источником и слушателем)
## - 3D-свист пролетающих сверхзвуковых пуль (Flyby Crack) в точке сближения с головой
## - 3D-импакты попаданий (плоть, металл, грунт)
## - Профили выстрелов для всех 8 видов оружия

const SFX_WHIZ = preload("res://assets/audio/bullet_whiz.wav")
const SFX_EXPLOSION = preload("res://assets/audio/explosion.wav")
const SFX_HIT_FLESH = preload("res://assets/audio/hit_flesh.ogg")
const SFX_HIT_METAL = preload("res://assets/audio/hit_metal.ogg")

const BUS_SFX := &"SFX"
const BUS_AMBIENCE := &"Ambience"
const BUS_COMBAT_DIRECT := &"CombatDirect"
const BUS_COMBAT_OCCLUDED := &"CombatOccluded"
const BUS_INDOOR_REVERB := &"IndoorReverb"

const WORLD_LAYER_MASK := 1 << 0
const MAX_ACTIVE_3D_SFX := 16

static var _last_flyby_time := 0.0
static var _active_3d_players: Array[AudioStreamPlayer3D] = []

const WEAPON_PROFILES := {
	"ak47": {
		"pitch": 0.98,
		"vol": -1.5,
		"unit_size": 16.0,
		"max_dist": 220.0,
	},
	"mp40": {
		"pitch": 1.16,
		"vol": -2.5,
		"unit_size": 12.0,
		"max_dist": 160.0,
	},
	"mosin": {
		"pitch": 0.74,
		"vol": 1.2,
		"unit_size": 22.0,
		"max_dist": 280.0,
	},
	"m1911": {
		"pitch": 1.32,
		"vol": -3.5,
		"unit_size": 8.0,
		"max_dist": 95.0,
	},
	"shotgun": {
		"pitch": 0.78,
		"vol": 0.8,
		"unit_size": 18.0,
		"max_dist": 140.0,
	},
	"ppsh41": {
		"pitch": 1.24,
		"vol": -3.0,
		"unit_size": 11.0,
		"max_dist": 170.0,
	},
	"kar98k": {
		"pitch": 0.68,
		"vol": 1.5,
		"unit_size": 24.0,
		"max_dist": 300.0,
	},
	"panzerfaust": {
		"pitch": 0.62,
		"vol": 2.2,
		"unit_size": 26.0,
		"max_dist": 320.0,
	},
}

## Гарантирует наличие всех аудиошин и эффектов фильтрации/реверберации в AudioServer
static func ensure_audio_buses() -> void:
	_ensure_bus(BUS_AMBIENCE, &"Master")
	_ensure_bus(BUS_SFX, &"Master")
	_ensure_bus(BUS_COMBAT_DIRECT, BUS_SFX)

	var occ_idx := AudioServer.get_bus_index(BUS_COMBAT_OCCLUDED)
	if occ_idx < 0:
		occ_idx = AudioServer.bus_count
		AudioServer.add_bus(occ_idx)
		AudioServer.set_bus_name(occ_idx, BUS_COMBAT_OCCLUDED)
		AudioServer.set_bus_send(occ_idx, BUS_SFX)
		AudioServer.set_bus_volume_db(occ_idx, -4.0)

		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = 1250.0
		lpf.resonance = 0.6
		AudioServer.add_bus_effect(occ_idx, lpf)

	var rev_idx := AudioServer.get_bus_index(BUS_INDOOR_REVERB)
	if rev_idx < 0:
		rev_idx = AudioServer.bus_count
		AudioServer.add_bus(rev_idx)
		AudioServer.set_bus_name(rev_idx, BUS_INDOOR_REVERB)
		AudioServer.set_bus_send(rev_idx, BUS_SFX)

		var rev := AudioEffectReverb.new()
		rev.room_size = 0.40
		rev.damping = 0.5
		rev.dry = 0.65
		rev.wet = 0.45
		AudioServer.add_bus_effect(rev_idx, rev)

static func _ensure_bus(bus_name: StringName, send_to: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)

## Получение позиции уха игрока (или активной камеры)
static func get_listener_position(tree: SceneTree) -> Vector3:
	if tree == null:
		return Vector3.ZERO
	var player = tree.get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and "camera" in player and player.camera != null:
		return player.camera.global_position
	return Vector3.ZERO

## Проверка прямой видимости до слушателя (окклюзия стенами/землей)
static func check_occlusion(world_3d: World3D, from_pos: Vector3, to_listener: Vector3) -> bool:
	if world_3d == null:
		return false
	var space := world_3d.direct_space_state
	if space == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(from_pos, to_listener)
	query.collision_mask = WORLD_LAYER_MASK
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	return not hit.is_empty()

## Проверка, находится ли позиция под потолком / крышей (в помещении)
static func is_indoors(world_3d: World3D, pos: Vector3, max_height := 7.5) -> bool:
	if world_3d == null:
		return false
	var space := world_3d.direct_space_state
	if space == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(pos, pos + Vector3.UP * max_height)
	query.collision_mask = WORLD_LAYER_MASK
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	return not hit.is_empty()

## Маршрутизация на правильную шину: если в помещении -> IndoorReverb, если за стеной -> CombatOccluded, иначе CombatDirect
static func route_combat_bus(world_3d: World3D, sound_pos: Vector3, listener_pos: Vector3) -> StringName:
	if is_indoors(world_3d, sound_pos):
		return BUS_INDOOR_REVERB
	if check_occlusion(world_3d, sound_pos + Vector3(0.0, 1.4, 0.0), listener_pos):
		return BUS_COMBAT_OCCLUDED
	return BUS_COMBAT_DIRECT

## 3D-свист пули рядом со слушателем (сверхзвуковой хлыст)
static func trigger_bullet_flyby_3d(world: Node, from: Vector3, to: Vector3, ear_pos: Vector3) -> void:
	if world == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_flyby_time < 0.055:
		return

	var seg := to - from
	var seg_len := seg.length()
	if seg_len < 0.2:
		return
	var dir := seg / seg_len
	var to_ear := ear_pos - from
	var proj := to_ear.dot(dir)
	if proj < 0.2 or proj > seg_len:
		return

	var closest_pt := from + dir * proj
	var dist := closest_pt.distance_to(ear_pos)
	if dist >= 0.35 and dist <= 3.2:
		_last_flyby_time = now
		_clean_active_players()
		if _active_3d_players.size() >= MAX_ACTIVE_3D_SFX:
			return

		var sfx := AudioStreamPlayer3D.new()
		sfx.stream = SFX_WHIZ
		sfx.bus = BUS_COMBAT_DIRECT
		sfx.unit_size = 3.5
		sfx.max_distance = 24.0
		sfx.pitch_scale = randf_range(0.92, 1.18)
		sfx.position = closest_pt
		sfx.add_to_group("combat_audio_voice")
		world.add_child(sfx)
		sfx.play()
		_active_3d_players.append(sfx)
		sfx.finished.connect(func():
			_active_3d_players.erase(sfx)
			if is_instance_valid(sfx):
				sfx.queue_free()
		)

## Воспроизведение пространственного импакта попадания в 3D
static func play_surface_impact(world: Node, pos: Vector3, normal: Vector3, surface_type: String) -> void:
	if world == null:
		return
	_clean_active_players()
	if _active_3d_players.size() >= MAX_ACTIVE_3D_SFX:
		return

	var sfx := AudioStreamPlayer3D.new()
	match surface_type:
		"flesh":
			sfx.stream = SFX_HIT_FLESH
			sfx.unit_size = 6.0
			sfx.max_distance = 45.0
			sfx.pitch_scale = randf_range(0.88, 1.12)
			sfx.volume_db = -1.0
		"metal":
			sfx.stream = SFX_HIT_METAL
			sfx.unit_size = 8.0
			sfx.max_distance = 65.0
			sfx.pitch_scale = randf_range(1.05, 1.28)
			sfx.volume_db = -2.0
		_:
			# Удар по грунту / бетону
			sfx.stream = SFX_HIT_FLESH
			sfx.unit_size = 7.0
			sfx.max_distance = 50.0
			sfx.pitch_scale = randf_range(0.55, 0.72)
			sfx.volume_db = -4.0

	sfx.bus = BUS_SFX
	sfx.position = pos + normal * 0.05
	sfx.add_to_group("combat_audio_voice")
	world.add_child(sfx)
	sfx.play()
	_active_3d_players.append(sfx)
	sfx.finished.connect(func():
		_active_3d_players.erase(sfx)
		if is_instance_valid(sfx):
			sfx.queue_free()
	)

## Воспроизведение 3D-взрыва с логарифмическим спадом и окклюзией
static func play_explosion_3d(world: Node, pos: Vector3, stream: AudioStream = null, unit_size := 32.0, max_distance := 320.0, volume_db := 0.0) -> AudioStreamPlayer3D:
	if world == null:
		return null
	var tree := world.get_tree() if world.is_inside_tree() else null
	var listener := tree.get_first_node_in_group("player") if tree != null else null
	var has_listener := listener != null and is_instance_valid(listener)
	var listener_pos := get_listener_position(tree) if tree != null else Vector3.ZERO
	if has_listener and listener_pos.distance_to(pos) > max_distance:
		return null
	if not _claim_active_3d_voice(pos, listener_pos, has_listener):
		return null

	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = stream if stream != null else SFX_EXPLOSION
	sfx.unit_size = unit_size
	sfx.max_distance = max_distance
	sfx.volume_db = volume_db
	sfx.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	sfx.position = pos
	sfx.add_to_group("combat_audio_voice")

	if tree != null:
		var world_3d = world.get_viewport().find_world_3d() if world.is_inside_tree() else null
		sfx.bus = route_combat_bus(world_3d, pos, listener_pos)

	world.add_child(sfx)
	sfx.play()
	_active_3d_players.append(sfx)
	sfx.finished.connect(func():
		_active_3d_players.erase(sfx)
		if is_instance_valid(sfx):
			sfx.queue_free()
	)
	return sfx

## Keep chain explosions from creating unbounded inaudible voices. When full,
## replace the farthest active transient so nearby blasts remain audible.
static func _claim_active_3d_voice(pos: Vector3, listener_pos: Vector3, has_listener: bool) -> bool:
	_clean_active_players()
	if _active_3d_players.size() < MAX_ACTIVE_3D_SFX:
		return true
	if not has_listener:
		return false

	var farthest_index := -1
	var farthest_distance_sq := -1.0
	for i in range(_active_3d_players.size()):
		var voice := _active_3d_players[i]
		if voice == null or not is_instance_valid(voice):
			continue
		var distance_sq := voice.global_position.distance_squared_to(listener_pos)
		if distance_sq > farthest_distance_sq:
			farthest_distance_sq = distance_sq
			farthest_index = i

	if farthest_index < 0 or pos.distance_squared_to(listener_pos) >= farthest_distance_sq:
		return false
	var displaced := _active_3d_players[farthest_index]
	_active_3d_players.remove_at(farthest_index)
	if displaced != null and is_instance_valid(displaced):
		displaced.stop()
		displaced.queue_free()
	return true

static func get_active_3d_voice_count() -> int:
	_clean_active_players()
	return _active_3d_players.size()

static func get_active_3d_voice_limit() -> int:
	return MAX_ACTIVE_3D_SFX

static func _clean_active_players() -> void:
	var i := _active_3d_players.size() - 1
	while i >= 0:
		var p = _active_3d_players[i]
		if p == null or not is_instance_valid(p) or not p.playing:
			_active_3d_players.remove_at(i)
		i -= 1
