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
	if "hud_only" in OS.get_cmdline_user_args():
		await _capture_hud_only()
	elif "menu_only" in OS.get_cmdline_user_args():
		await _capture_main_menu()
	elif "deploy_new" in OS.get_cmdline_user_args():
		await _capture_new_deploy()
	elif "village_hud" in OS.get_cmdline_user_args():
		await _capture_village_hud_only()
	else:
		await _capture_main_menu()
		await _capture_battlefield()
		await _capture_village()
	print("SCREENSHOTS_OK: %d" % _captures)
	get_tree().quit()

func _capture_village_hud_only() -> void:
	MatchState.map_name = "VILLAGE"
	MatchState.mode = "CONQUEST"
	MatchState.player_team = "RED FRONT"
	MatchState.skip_deploy_screen = true
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate() as Node3D
	add_child(battlefield)
	await _wait_frames(10)
	var player_node := get_tree().get_first_node_in_group("player")
	_clear_dead_bots()
	_prepare_player(player_node, Vector3(0.0, 0.4, 40.0), 0.0)
	await _wait_frames(4)
	_prepare_player(player_node, Vector3(0.0, 0.4, 40.0), 0.0)
	await _capture("07_village_hud")
	battlefield.queue_free()

func _capture_new_deploy() -> void:
	MatchState.map_name = "BATTLEFIELD"
	MatchState.mode = "CONQUEST"
	MatchState.player_team = "IRON LEGION"
	MatchState.request_deploy_screen(true, false)
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate()
	add_child(battlefield)
	await _wait_frames(40)
	await _capture("10_tactical_deploy")
	var ui := battlefield.get_node_or_null("TacticalDeploy")
	if ui != null:
		ui.call("_open_loadout")
		await _wait_frames(10)
		await _capture("11_loadout")
		var overlay: Control = ui.get("_loadout_overlay")
		if overlay != null:
			overlay.visible = false
		ui.call("_on_deploy_clicked")
		await _wait_frames(80)
		await _capture("12_fp_arms")
	battlefield.queue_free()

func _capture_hud_only() -> void:
	MatchState.map_name = "BATTLEFIELD"
	MatchState.mode = "CONQUEST"
	MatchState.player_team = "IRON LEGION"
	MatchState.skip_deploy_screen = true
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate() as Node3D
	add_child(battlefield)
	await _wait_frames(10)
	var player_node := get_tree().get_first_node_in_group("player")
	_clear_dead_bots()
	_prepare_player(player_node, Vector3(-28.0, 0.4, 22.0), -0.9)
	await _wait_frames(4)
	_prepare_player(player_node, Vector3(-28.0, 0.4, 22.0), -0.9)
	await _capture("04_battlefield_hud")
	battlefield.queue_free()

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
	menu.call("_show_maps")
	await _wait_frames(3)
	await _capture("01b_menu_maps")
	menu.call("_show_settings")
	await _wait_frames(3)
	await _capture("02_settings")
	menu.queue_free()
	await _wait_frames(2)

func _add_overview_camera(parent: Node3D, position: Vector3, target: Vector3) -> Camera3D:
	var overview := Camera3D.new()
	overview.fov = 68.0
	overview.far = 500.0
	parent.add_child(overview)
	overview.look_at_from_position(position, target, Vector3.UP)
	overview.current = true
	return overview

func _set_hud_visible(battlefield: Node3D, is_visible: bool) -> void:
	var hud_layer = battlefield.get("hud")
	if hud_layer is CanvasLayer:
		(hud_layer as CanvasLayer).visible = is_visible

func _set_player_hud_visible(player_node: Node, is_visible: bool) -> void:
	if player_node == null:
		return
	var hud_layer = player_node.get("hud")
	if hud_layer is CanvasLayer:
		(hud_layer as CanvasLayer).visible = is_visible

func _clear_dead_bots() -> void:
	for bot in get_tree().get_nodes_in_group("bots"):
		if bool(bot.get("is_dead")):
			bot.queue_free()

func _prepare_player(player_node: Node, position: Vector3, yaw: float) -> void:
	if not (player_node is Node3D):
		return
	var player_3d := player_node as Node3D
	player_3d.global_position = position
	player_3d.set("yaw", yaw)
	player_3d.set("health", 100.0)
	player_3d.set("blood_vignette_time", 0.0)
	if bool(player_3d.get("is_dead")):
		player_3d.call("respawn")
	var camera = player_3d.get("camera")
	if camera is Camera3D:
		(camera as Camera3D).current = true

func _capture_battlefield() -> void:
	MatchState.map_name = "BATTLEFIELD"
	MatchState.mode = "CONQUEST"
	MatchState.player_team = "IRON LEGION"
	MatchState.skip_deploy_screen = true
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate() as Node3D
	add_child(battlefield)
	await _wait_frames(8)

	var player_node := get_tree().get_first_node_in_group("player")
	_set_hud_visible(battlefield, false)
	_set_player_hud_visible(player_node, false)
	var overview := _add_overview_camera(battlefield, Vector3(0.0, 38.0, 64.0), Vector3(0.0, 0.0, 0.0))
	Engine.time_scale = 3.0
	await _wait_frames(180)
	Engine.time_scale = 1.0
	await _capture("03_battlefield_overview")
	overview.queue_free()

	_set_hud_visible(battlefield, true)
	_set_player_hud_visible(player_node, true)
	_clear_dead_bots()
	_prepare_player(player_node, Vector3(-28.0, 0.4, 22.0), -0.9)
	await _wait_frames(4)
	# Сбрасываем урон прямо перед кадром, чтобы не ловить кровавый оверлей.
	_prepare_player(player_node, Vector3(-28.0, 0.4, 22.0), -0.9)
	await _capture("04_battlefield_hud")

	var pause_menu: Node = player_node.get("pause_menu") if player_node != null else null
	if pause_menu != null:
		pause_menu.call("open")
		await _capture("05_pause_menu")
		pause_menu.call("close")

	battlefield.queue_free()
	await _wait_frames(3)

func _capture_village() -> void:
	MatchState.map_name = "VILLAGE"
	MatchState.mode = "CONQUEST"
	MatchState.player_team = "RED FRONT"
	MatchState.skip_deploy_screen = true
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate() as Node3D
	add_child(battlefield)
	await _wait_frames(8)

	var player_node := get_tree().get_first_node_in_group("player")
	_set_hud_visible(battlefield, false)
	_set_player_hud_visible(player_node, false)
	var overview := _add_overview_camera(battlefield, Vector3(0.0, 32.0, 56.0), Vector3(0.0, 0.0, 0.0))
	Engine.time_scale = 3.0
	await _wait_frames(180)
	Engine.time_scale = 1.0
	await _capture("06_village_overview")
	overview.queue_free()

	_set_hud_visible(battlefield, true)
	_set_player_hud_visible(player_node, true)
	_clear_dead_bots()
	_prepare_player(player_node, Vector3(0.0, 0.4, 40.0), 0.0)
	await _wait_frames(4)
	_prepare_player(player_node, Vector3(0.0, 0.4, 40.0), 0.0)
	await _capture("07_village_hud")

	battlefield.queue_free()
	await _wait_frames(3)
