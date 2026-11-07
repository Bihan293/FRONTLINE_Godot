extends RefCounted
class_name FRONTLINEWeaponSoundBank

## Синтезированные выстрелы для каждого оружия. Один и тот же washed-out
## sample на все стволы звучал «игрушечно», поэтому здесь есть низкий удар,
## шумовой хлопок и отдельный треск для каждого профиля.

const SAMPLE_RATE := 22050
const MAX_AMP := 0.92

const PROFILES := {
	"ak47": {"length": 0.34, "body_hz": 92.0, "body_decay": 17.0, "noise_decay": 32.0, "crack": 0.55, "drive": 1.0},
	"mp40": {"length": 0.24, "body_hz": 118.0, "body_decay": 24.0, "noise_decay": 40.0, "crack": 0.45, "drive": 0.85},
	"mosin": {"length": 0.62, "body_hz": 68.0, "body_decay": 9.0, "noise_decay": 22.0, "crack": 0.85, "drive": 1.15},
	"m1911": {"length": 0.20, "body_hz": 150.0, "body_decay": 30.0, "noise_decay": 50.0, "crack": 0.40, "drive": 0.75},
	"shotgun": {"length": 0.46, "body_hz": 62.0, "body_decay": 13.0, "noise_decay": 25.0, "crack": 0.70, "drive": 1.10},
	"ppsh41": {"length": 0.22, "body_hz": 128.0, "body_decay": 25.0, "noise_decay": 42.0, "crack": 0.42, "drive": 0.82},
	"kar98k": {"length": 0.58, "body_hz": 72.0, "body_decay": 10.0, "noise_decay": 23.0, "crack": 0.80, "drive": 1.12},
	"panzerfaust": {"length": 0.75, "body_hz": 48.0, "body_decay": 7.0, "noise_decay": 16.0, "crack": 0.95, "drive": 1.25},
}

static var _cache: Dictionary = {}

static func get_shot(weapon_id: String) -> AudioStreamWAV:
	var key := weapon_id if PROFILES.has(weapon_id) else "ak47"
	if _cache.has(key):
		return _cache[key]
	var stream := _synthesize(key, PROFILES[key])
	_cache[key] = stream
	return stream

static func _synthesize(weapon_id: String, profile: Dictionary) -> AudioStreamWAV:
	var length := float(profile["length"])
	var count := int(SAMPLE_RATE * length)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(weapon_id)
	var body_hz := float(profile["body_hz"])
	var body_decay := float(profile["body_decay"])
	var noise_decay := float(profile["noise_decay"])
	var crack := float(profile["crack"])
	var drive := float(profile["drive"])
	var peak := 0.0
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var body_env := exp(-t * body_decay)
		var noise_env := exp(-t * noise_decay)
		var body := sin(TAU * body_hz * t) * body_env
		var sub := sin(TAU * body_hz * 0.53 * t + 0.4) * exp(-t * body_decay * 0.55) * 0.45
		var noise := rng.randf_range(-1.0, 1.0) * noise_env
		var transient := rng.randf_range(-1.0, 1.0) * exp(-t * 140.0) * crack
		var sample := (body * 0.72 + sub + noise * 0.62 + transient) * drive
		# Лёгкое мягкое ограничение вместо жёсткого клиппинга.
		sample = tanh(sample * 1.25)
		samples[i] = sample
		peak = maxf(peak, absf(sample))

	var gain := MAX_AMP / maxf(peak, 0.001)
	for i in range(count):
		var value := int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream
