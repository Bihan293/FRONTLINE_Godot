extends Node
class_name FRONTLINEAmbience

## Звуковая атмосфера поля боя в стиле Dummy War.
## Реализует:
## - Свист и щелчок пролетающих рядом пуль (Supersonic Bullet Whiz)
## - Далёкие раскаты артиллерии фронта

const AUDIO_SAMPLE_RATE := 22050

static var instance: FRONTLINEAmbience

var _whiz_players: Array[AudioStreamPlayer] = []
var _artillery_player: AudioStreamPlayer
var _artillery_timer := 0.0

func _ready() -> void:
	instance = self
	_build_audio_players()
	_artillery_timer = randf_range(6.0, 14.0)

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _build_audio_players() -> void:
	var whiz_stream := _make_whiz_stream()
	for i in range(3):
		var p := AudioStreamPlayer.new()
		p.stream = whiz_stream
		p.volume_db = -8.0
		p.bus = &"Ambience"
		add_child(p)
		_whiz_players.append(p)

	_artillery_player = AudioStreamPlayer.new()
	_artillery_player.stream = _make_artillery_stream()
	_artillery_player.volume_db = -11.0
	_artillery_player.bus = &"Ambience"
	add_child(_artillery_player)

func _make_whiz_stream() -> AudioStreamWAV:
	var duration := 0.24
	var frame_count := int(AUDIO_SAMPLE_RATE * duration)
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var filtered_noise := 0.0
	var phase := 0.0
	for i in range(frame_count):
		var t := float(i) / float(AUDIO_SAMPLE_RATE)
		var progress := t / duration
		var noise := rng.randf_range(-1.0, 1.0)
		filtered_noise = lerpf(filtered_noise, noise, 0.34)
		var frequency := lerpf(1850.0, 620.0, progress)
		phase += TAU * frequency / float(AUDIO_SAMPLE_RATE)
		var envelope := pow(maxf(0.0, sin(PI * progress)), 0.7)
		var crack := noise * exp(-t * 85.0) * 0.45
		var sample := (filtered_noise * 0.62 + sin(phase) * 0.30 + crack) * envelope * 0.55
		pcm.encode_s16(i * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	return _make_wav(pcm)

func _make_artillery_stream() -> AudioStreamWAV:
	var duration := 1.4
	var frame_count := int(AUDIO_SAMPLE_RATE * duration)
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var low_noise := 0.0
	var mid_noise := 0.0
	var phase := 0.0
	for i in range(frame_count):
		var t := float(i) / float(AUDIO_SAMPLE_RATE)
		var progress := t / duration
		var noise := rng.randf_range(-1.0, 1.0)
		low_noise = lerpf(low_noise, noise, 0.022)
		mid_noise = lerpf(mid_noise, noise, 0.11)
		var frequency := lerpf(68.0, 34.0, progress)
		phase += TAU * frequency / float(AUDIO_SAMPLE_RATE)
		var tail := exp(-t * 2.4)
		var impact := noise * exp(-t * 95.0) * 0.22
		var sample := (sin(phase) * 0.50 + low_noise * 1.0 + mid_noise * 0.16 + impact) * tail * 0.48
		pcm.encode_s16(i * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	return _make_wav(pcm)

func _make_wav(pcm: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.data = pcm
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = AUDIO_SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav

## Проверяет, пролетела ли пуля рядом с головой игрока, и воспроизводит свист
static func check_bullet_flyby(ray_from: Vector3, ray_to: Vector3, ear_pos: Vector3) -> void:
	if instance == null:
		return
	var world := instance.get_parent()
	if world != null:
		FRONTLINECombatAudio.trigger_bullet_flyby_3d(world, ray_from, ray_to, ear_pos)
		return
	var seg := ray_to - ray_from
	var seg_len := seg.length()
	if seg_len < 0.1:
		return
	var dir := seg / seg_len
	var to_ear := ear_pos - ray_from
	var proj := to_ear.dot(dir)
	if proj < 0.5 or proj > seg_len:
		return
	var closest_pt := ray_from + dir * proj
	var dist := closest_pt.distance_to(ear_pos)
	if dist < 2.8:
		instance.play_whiz()

func play_whiz() -> void:
	for p in _whiz_players:
		if not p.playing:
			p.pitch_scale = randf_range(0.95, 1.25)
			p.play()
			break

func _process(delta: float) -> void:
	_artillery_timer -= delta
	if _artillery_timer <= 0.0:
		_artillery_timer = randf_range(10.0, 22.0)
		_trigger_distant_artillery()

func _trigger_distant_artillery() -> void:
	if _artillery_player != null:
		_artillery_player.pitch_scale = randf_range(0.85, 1.15)
		_artillery_player.play()
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and "recoil" in player:
		# Лёгкая вибрация от далёкого разрыва снаряда
		player.recoil.y += randf_range(0.005, 0.012)
