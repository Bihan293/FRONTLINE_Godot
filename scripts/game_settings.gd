extends Node

## Общие настройки игры: качество графики и громкость.
## Сохраняются в user://frontline_settings.cfg и применяются сразу.

const CONFIG_PATH := "user://frontline_settings.cfg"
const QUALITY_NAMES := ["НИЗКАЯ", "СРЕДНЯЯ", "ВЫСОКАЯ"]

var quality := 1
var master_volume := 0.8

func _ready() -> void:
	load_settings()
	apply_all()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		quality = clampi(int(cfg.get_value("video", "quality", 1)), 0, 2)
		master_volume = clampf(float(cfg.get_value("audio", "master", 0.8)), 0.0, 1.0)
	else:
		# На мобилках по умолчанию средний пресет: заметно быстрее High,
		# но без «мыла» низкого разрешения.
		quality = 1
		master_volume = 0.8

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", quality)
	cfg.set_value("audio", "master", master_volume)
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

func apply_all() -> void:
	apply_audio()
	apply_video()
	apply_frame_limit()

func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.001)))
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)

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
