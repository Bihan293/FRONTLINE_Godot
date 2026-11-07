extends Node

## Рендерит реальные кадры игры через Xvfb и сохраняет их в res://screenshots/.
## Запуск (нужен Xvfb и OpenGL-совместимый драйвер):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --audio-driver Dummy res://tools/screenshot_harness.tscn

const OUTPUT_DIR := "res://screenshots"
const BATTLEFIELD_SCENE := "res://scenes/Battlefield.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

var _captures := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture_main_menu()
	await _capture_battlefield()
	await _capture_village()
	print("SCREENSHOTS_OK: %d" % _captures)
	get_tree().quit()

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, file_name]
	var error := image.save_png(path)
	if error == OK:
		_captures += 1
		print("CAPTURE %s" % path)
	else:
		push_error("Cannot save screenshot %s: %s" % [path, error_string(error)])

func _capture_main_menu() -> void:
	var packed: PackedScene = load(MAIN_MENU_SCENE)
	var menu: Control = packed.instantiate()
	add_child(menu)
	await _wait_frames(3)
	await _capture("01_main_menu")
	menu.call("_show_settings")
	await _wait_frames(3)
	await _capture("02_settings")
	menu.queue_free()
	await _wait_frames(2)

func _capture_battlefield() -> void:
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "IRON LEGION")
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate()
	add_child(battlefield)
	await _wait_frames(8)
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node is Node3D:
		var player_3d := player_node as Node3D
		player_3d.global_position = Vector3(0.0, 0.4, 42.0)
		player_3d.set("yaw", 0.0)
		player_3d.set("health", 100.0)
	await _wait_frames(90)
	await _capture("03_battlefield")

	var pause_menu: Node = player_node.get("pause_menu") if player_node != null else null
	if pause_menu != null:
		pause_menu.call("open")
		await _capture("04_pause_menu")
		pause_menu.call("close")

	battlefield.queue_free()
	await _wait_frames(3)

func _capture_village() -> void:
	get_tree().set_meta("selected_map", "VILLAGE")
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "RED FRONT")
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate()
	add_child(battlefield)
	await _wait_frames(8)
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node is Node3D:
		var player_3d := player_node as Node3D
		player_3d.global_position = Vector3(0.0, 0.4, 48.0)
		player_3d.set("yaw", 0.0)
		player_3d.set("health", 100.0)
	await _wait_frames(90)
	await _capture("05_village")

	battlefield.queue_free()
	await _wait_frames(3)
