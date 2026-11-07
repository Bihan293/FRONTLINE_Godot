extends Node

## Общие настройки игры: качество графики и громкость.
## Сохраняются в user://frontline_settings.cfg и применяются сразу.

const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")

const CONFIG_PATH := "user://frontline_settings.cfg"
const QUALITY_NAMES := ["НИЗКАЯ", "СРЕДНЯЯ", "ВЫСОКАЯ"]

const MIN_LOOK_SENSITIVITY := 0.30
const MAX_LOOK_SENSITIVITY := 2.50
const MIN_AIM_SENSITIVITY := 0.20
const MAX_AIM_SENSITIVITY := 1.50
const MIN_FOV := 60.0
const MAX_FOV := 100.0

var quality := 1
var master_volume := 0.8
var sfx_volume := 0.90
var ambience_volume := 0.75
var look_sensitivity := 1.0
var aim_sensitivity := 0.70
var invert_y := false
var fov := 78.0

func _ready() -> void:
	COMBAT_AUDIO.ensure_audio_buses()
	load_settings()
	apply_all()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		quality = clampi(int(cfg.get_value("video", "quality", 1)), 0, 2)
		master_volume = clampf(float(cfg.get_value("audio", "master", 0.8)), 0.0, 1.0)
		sfx_volume = clampf(float(cfg.get_value("audio", "sfx", 0.90)), 0.0, 1.0)
		ambience_volume = clampf(float(cfg.get_value("audio", "ambience", 0.75)), 0.0, 1.0)
		look_sensitivity = clampf(float(cfg.get_value("controls", "look_sensitivity", 1.0)), MIN_LOOK_SENSITIVITY, MAX_LOOK_SENSITIVITY)
		aim_sensitivity = clampf(float(cfg.get_value("controls", "aim_sensitivity", 0.70)), MIN_AIM_SENSITIVITY, MAX_AIM_SENSITIVITY)
		invert_y = bool(cfg.get_value("controls", "invert_y", false))
		fov = clampf(float(cfg.get_value("video", "fov", 78.0)), MIN_FOV, MAX_FOV)
	else:
		# На мобилках по умолчанию средний пресет: заметно быстрее High,
		# но без «мыла» низкого разрешения.
		quality = 1
		master_volume = 0.8
		sfx_volume = 0.90
		ambience_volume = 0.75

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "fov", fov)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambience", ambience_volume)
	cfg.set_value("controls", "look_sensitivity", look_sensitivity)
	cfg.set_value("controls", "aim_sensitivity", aim_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.save(CONFIG_PATH)

func quality_name() -> String:
	return QUALITY_NAMES[clampi(quality, 0, 2)]

func cycle_quality() -> void:
	quality = (quality + 1) % 3
	apply_all()
	save_settings()

func set_quality(value: int) -> void:
	quality = clampi(value, 0, 2)
	apply_all()
	save_settings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()

func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()

func set_look_sensitivity(value: float) -> void:
	look_sensitivity = clampf(value, MIN_LOOK_SENSITIVITY, MAX_LOOK_SENSITIVITY)
	save_settings()

func set_aim_sensitivity(value: float) -> void:
	aim_sensitivity = clampf(value, MIN_AIM_SENSITIVITY, MAX_AIM_SENSITIVITY)
	save_settings()

func set_invert_y(value: bool) -> void:
	invert_y = value
	save_settings()

func set_fov(value: float) -> void:
	fov = clampf(value, MIN_FOV, MAX_FOV)
	save_settings()

## Множитель чувствительности: при прицеливании используется отдельная настройка.
func sensitivity_scale(is_aiming: bool) -> float:
	return aim_sensitivity if is_aiming else look_sensitivity

func reset_controls() -> void:
	look_sensitivity = 1.0
	aim_sensitivity = 0.70
	invert_y = false
	fov = 78.0
	save_settings()

func apply_all() -> void:
	apply_audio()
	apply_video()
	apply_frame_limit()

func apply_audio() -> void:
	COMBAT_AUDIO.ensure_audio_buses()
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("Ambience", ambience_volume)

	# На слабом мобильном пресете отключаем тяжелый реверб для 60 FPS
	var rev_bus := AudioServer.get_bus_index("IndoorReverb")
	if rev_bus >= 0 and AudioServer.get_bus_effect_count(rev_bus) > 0:
		AudioServer.set_bus_effect_enabled(rev_bus, 0, quality > 0)

func _apply_bus_volume(bus_name: StringName, linear_val: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(linear_val, 0.001)))
	AudioServer.set_bus_mute(bus, linear_val <= 0.001)

func apply_video() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match quality:
		0:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.70
		1:
			vp.msaa_3d = Viewport.MSAA_2X
			vp.scaling_3d_scale = 0.86
		_:
			vp.msaa_3d = Viewport.MSAA_4X
			vp.scaling_3d_scale = 1.0

func apply_frame_limit() -> void:
	# Низкий пресет ограничивает FPS, чтобы телефон не грелся и не лагал.
	Engine.max_fps = 30 if quality == 0 else 60

func shadows_enabled() -> bool:
	return quality > 0

func shadow_distance() -> float:
	return 45.0 if quality == 1 else 90.0

func fog_enabled() -> bool:
	return quality > 0
