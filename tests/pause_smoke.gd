extends Node

## Headless smoke-test для TASK-0004: настройки, пауза и мини-карта.
## Запуск:
##   godot --headless --path . res://tests/pause_smoke.tscn --quit-after 600

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_test_settings()
	_test_pause_menu()
	await _test_settings_screen()
	await _test_battlefield_integration()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _test_settings() -> void:
	GameSettings.set_look_sensitivity(1.55)
	GameSettings.set_aim_sensitivity(0.45)
	GameSettings.set_fov(92.0)
	GameSettings.set_invert_y(true)
	GameSettings.load_settings()
	_check(is_equal_approx(GameSettings.look_sensitivity, 1.55), "look sensitivity did not persist")
	_check(is_equal_approx(GameSettings.aim_sensitivity, 0.45), "aim sensitivity did not persist")
	_check(is_equal_approx(GameSettings.fov, 92.0), "FOV did not persist")
	_check(GameSettings.invert_y, "invert Y did not persist")
	GameSettings.reset_controls()
	_check(is_equal_approx(GameSettings.look_sensitivity, 1.0), "reset controls failed")

func _test_pause_menu() -> void:
	var menu := FRONTLINEPauseMenu.new()
	add_child(menu)
	_check(not menu.visible, "pause menu must start hidden")
	menu.open()
	_check(menu.visible, "pause menu did not open")
	_check(get_tree().paused, "tree was not paused")
	menu.close()
	_check(not menu.visible, "pause menu did not close")
	_check(not get_tree().paused, "tree stayed paused")
	menu.queue_free()

func _test_settings_screen() -> void:
	var scene: PackedScene = load("res://scenes/MainMenu.tscn")
	_check(scene != null, "main menu scene missing")
	if scene == null:
		return
	var menu := scene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	menu.call("_show_settings")
	await get_tree().process_frame
	_check(menu.get_child_count() > 0, "settings screen is empty")
	menu.queue_free()
	await get_tree().process_frame

func _test_battlefield_integration() -> void:
	var configs := [
		["BATTLEFIELD", "CONQUEST"],
		["VILLAGE", "CONQUEST"],
		["BATTLEFIELD", "TDM"],
	]
	for config in configs:
		get_tree().set_meta("selected_map", config[0])
		get_tree().set_meta("selected_mode", config[1])
		await _run_battlefield_case(str(config[0]), str(config[1]))
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")

func _run_battlefield_case(map_name: String, mode_name: String) -> void:
	var scene: PackedScene = load("res://scenes/Battlefield.tscn")
	_check(scene != null, "%s scene missing" % map_name)
	if scene == null:
		return
	var battlefield := scene.instantiate()
	add_child(battlefield)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "player not found on %s/%s" % [map_name, mode_name])
	if player == null:
		battlefield.queue_free()
		return
	_check(player.has_method("open_pause_menu"), "player has no pause entry point")
	player.call("open_pause_menu")
	_check(get_tree().paused, "pause did not stop %s/%s" % [map_name, mode_name])
	var minimap: Node = battlefield.get("minimap")
	_check(minimap != null, "minimap not created on %s" % map_name)
	if minimap != null:
		_check(minimap is FRONTLINEMinimap, "minimap has wrong type")
	var pause_menu: Node = player.get("pause_menu")
	_check(pause_menu != null, "player pause menu missing")
	if pause_menu != null:
		pause_menu.call("close")
	_check(not get_tree().paused, "resume did not restore %s/%s" % [map_name, mode_name])
	battlefield.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _report() -> void:
	if _failures.is_empty():
		print("PAUSE_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("PAUSE_SMOKE_FAIL: " + failure)
		print("PAUSE_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
