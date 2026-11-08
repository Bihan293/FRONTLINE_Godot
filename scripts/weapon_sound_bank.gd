extends RefCounted
class_name FRONTLINEWeaponSoundBank

## QA-fix TASK-0022: реалистичные выстрелы на основе записанного сэмпла
## assets/audio/shot.wav. Раньше каждый ствол был процедурным синтезом и
## звучал как «пиу» из 8-битной игры. Теперь: реальная запись + низкочастотный
## удар для веса + ресемплинг под характер оружия (глубокий бас у винтовок,
## звонкий треск у пистолета).

const BASE_SHOT = preload("res://assets/audio/shot.wav")

const PROFILES := {
	"ak47":       {"ratio": 1.00, "length": 0.34, "body_hz": 95.0,  "body_decay": 15.0, "body_gain": 0.34, "gain": 1.00},
	"mp40":       {"ratio": 1.14, "length": 0.27, "body_hz": 120.0, "body_decay": 22.0, "body_gain": 0.28, "gain": 0.92},
	"mosin":      {"ratio": 0.84, "length": 0.58, "body_hz": 66.0,  "body_decay": 8.0,  "body_gain": 0.46, "gain": 1.05},
	"m1911":      {"ratio": 1.30, "length": 0.22, "body_hz": 155.0, "body_decay": 28.0, "body_gain": 0.22, "gain": 0.88},
	"shotgun":    {"ratio": 0.78, "length": 0.48, "body_hz": 60.0,  "body_decay": 11.0, "body_gain": 0.52, "gain": 1.05},
	"ppsh41":     {"ratio": 1.18, "length": 0.24, "body_hz": 126.0, "body_decay": 24.0, "body_gain": 0.26, "gain": 0.90},
	"kar98k":     {"ratio": 0.86, "length": 0.62, "body_hz": 70.0,  "body_decay": 9.0,  "body_gain": 0.44, "gain": 1.05},
	"panzerfaust": {"ratio": 0.70, "length": 0.75, "body_hz": 46.0, "body_decay": 6.0,  "body_gain": 0.60, "gain": 1.10},
}

static var _cache: Dictionary = {}

static func get_shot(weapon_id: String) -> AudioStreamWAV:
	var key := weapon_id if PROFILES.has(weapon_id) else "ak47"
	if _cache.has(key):
		return _cache[key]
	var base: AudioStreamWAV = BASE_SHOT
	var stream := _build_variant(base, PROFILES[key])
	if stream == null:
		stream = base
	_cache[key] = stream
	return stream

static func _build_variant(base: AudioStreamWAV, profile: Dictionary) -> AudioStreamWAV:
	if base == null or base.format != AudioStreamWAV.FORMAT_16_BITS or base.data.is_empty():
		return null
	var ratio := float(profile["ratio"])
	var length := float(profile["length"])
	var body_hz := float(profile["body_hz"])
	var body_decay := float(profile["body_decay"])
	var body_gain := float(profile["body_gain"])
	var gain := float(profile["gain"])
	var rate := base.mix_rate
	var stereo := base.stereo
	var bytes_per_frame := 4 if stereo else 2
	var in_frames := base.data.size() / bytes_per_frame
	var out_frames := mini(int(rate * length), int(float(in_frames) / ratio))
	if out_frames <= 16:
		return null

	var out := PackedByteArray()
	out.resize(out_frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(profile))
	for i in range(out_frames):
		var t := float(i) / float(rate)
		var pos := float(i) * ratio
		var i0 := int(pos)
		var frac := pos - float(i0)
		var i1 := mini(i0 + 1, in_frames - 1)
		var sample := 0.0
		if stereo:
			var l0 := _read_i16(base.data, i0 * 4)
			var l1 := _read_i16(base.data, i1 * 4)
			var r0 := _read_i16(base.data, i0 * 4 + 2)
			var r1 := _read_i16(base.data, i1 * 4 + 2)
			var left := lerpf(float(l0), float(l1), frac)
			var right := lerpf(float(r0), float(r1), frac)
			sample = (left + right) * 0.5 / 32768.0
		else:
			var s0 := _read_i16(base.data, i0 * 2)
			var s1 := _read_i16(base.data, i1 * 2)
			sample = lerpf(float(s0), float(s1), frac) / 32768.0
		# Низкочастотный «удар» для веса и объёма.
		var thump := sin(TAU * body_hz * t) * exp(-t * body_decay) * body_gain
		# Короткий шумовой транзиент, чтобы атака читалась резче.
		var transient := rng.randf_range(-1.0, 1.0) * exp(-t * 120.0) * 0.10
		var value := (sample + thump + transient) * gain
		# Мягкий лимитер вместо клиппинга.
		value = tanh(value * 1.15)
		# Плавное затухание в конце фрагмента (без щелчка).
		var fade := clampf((length - t) / (length * 0.18), 0.0, 1.0)
		value *= fade
		var out_i := int(clampf(value, -1.0, 1.0) * 32767.0)
		out[i * 2] = out_i & 0xFF
		out[i * 2 + 1] = (out_i >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = out
	return stream

static func _read_i16(data: PackedByteArray, offset: int) -> int:
	if offset < 0 or offset + 1 >= data.size():
		return 0
	var value := int(data[offset]) | (int(data[offset + 1]) << 8)
	if value >= 32768:
		value -= 65536
	return value
