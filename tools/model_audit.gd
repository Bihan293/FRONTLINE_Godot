extends Node

## In-game model audit harness. Captures deterministic before/after shots for
## soldiers, weapons, pickups, the radio drone and map props.
## Run under Xvfb:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --audio-driver Dummy res://tools/model_audit.tscn -- before
## Second argument selects the output folder: before / after.

const OUT_BEFORE := "res://screenshots/model_before"
const OUT_AFTER := "res://screenshots/model_after"
const BATTLEFIELD_SCENE := "res://scenes/Battlefield.tscn"
const POLYGON_SCENE := "res://scenes/Polygon.tscn"
const PICKUP_SCRIPT := preload("res://scripts/field_pickup.gd")
const DRONE_SCRIPT := preload("res://scripts/radio_drone.gd")

var _out_dir := OUT_BEFORE
var _captures := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_out_dir = OUT_AFTER if "after" in OS.get_cmdline_user_args() else OUT_BEFORE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	if "ragdoll" in OS.get_cmdline_user_args():
		await _capture_ragdoll_only()
	elif "intro" in OS.get_cmdline_user_args():
		await _capture_intro_only()
	elif "pickups" in OS.get_cmdline_user_args():
		await _capture_pickups_only()
	elif "vehicles" in OS.get_cmdline_user_args():
		await _capture_vehicles_only()
	else:
		await _capture_battlefield_models()
		await _capture_village_models()
		await _capture_polygon_models()
	print("MODEL_AUDIT_OK: ", _captures)
	get_tree().quit()

func _capture_vehicles_only() -> void:
	var battlefield := await _load_map("BATTLEFIELD", "IRON LEGION")
	_freeze_bots()
	_set_hud_visible(battlefield, false)
	var turret: Node3D = null
	var jeep: Node3D = null
	for node in get_tree().get_nodes_in_group("enterable_vehicles"):
		if turret == null and node.has_method("try_fire"):
			turret = node
		elif jeep == null and "throttle_override" in node:
			jeep = node
	if turret != null:
		var turret_focus: Vector3 = turret.global_position + Vector3(0.0, 0.8, 0.0)
		var turret_cam := _add_free_camera(battlefield, turret_focus + Vector3(2.2, 2.0, 3.4), turret_focus)
		await _wait_frames(5)
		await _capture("turret")
		turret_cam.queue_free()
	if jeep != null:
		var jeep_focus: Vector3 = jeep.global_position + Vector3(0.0, 0.7, 0.0)
		var jeep_cam := _add_free_camera(battlefield, jeep_focus + Vector3(4.0, 2.2, 5.2), jeep_focus)
		await _wait_frames(5)
		await _capture("jeep")
		jeep_cam.queue_free()
	battlefield.queue_free()

func _capture_pickups_only() -> void:
	var battlefield := await _load_map("BATTLEFIELD", "IRON LEGION")
	_freeze_bots()
	_set_hud_visible(battlefield, false)
	var weapon_pickup = PICKUP_SCRIPT.new()
	weapon_pickup.configure_weapon(0, 30, 150)
	weapon_pickup.position = Vector3(-1.0, 0.35, 0.0)
	battlefield.add_child(weapon_pickup)
	var ammo_pickup = PICKUP_SCRIPT.new()
	ammo_pickup.configure_ammo(48, 65.0)
	ammo_pickup.position = Vector3(1.0, 0.35, 0.0)
	battlefield.add_child(ammo_pickup)
	var camera := _add_free_camera(battlefield, Vector3(0.0, 1.4, 4.0), Vector3(0.0, 0.45, 0.0))
	await _wait_frames(5)
	await _capture("pickups")
	camera.queue_free()
	battlefield.queue_free()

func _capture_intro_only() -> void:
	get_tree().set_meta("spawn_position", Vector3(0.0, 0.4, 50.0))
	get_tree().set_meta("deploy_intro", true)
	var battlefield := await _load_map("BATTLEFIELD", "IRON LEGION")
	_set_hud_visible(battlefield, false)
	await _wait_frames(2)
	await _capture("intro_start")
	await get_tree().create_timer(3.2).timeout
	await _capture("intro_end")
	battlefield.queue_free()

func _capture_ragdoll_only() -> void:
	var battlefield := await _load_map("BATTLEFIELD", "IRON LEGION")
	var bots := _freeze_bots()
	var target: Node3D = null
	for bot in bots:
		if bot is Node3D:
			target = bot as Node3D
			break
	if target == null:
		return
	target.global_position = Vector3(0.0, 0.1, 0.0)
	target.rotation.y = PI
	target.set("health", 100.0)
	var proc = target.get("_proc")
	if proc != null:
		proc.call("set_motion", 0.0, false)
		proc.call("set_aiming", true)
	_set_hud_visible(battlefield, false)
	var camera := _add_free_camera(battlefield, Vector3(0.0, 1.8, 5.0), Vector3(0.0, 0.9, 0.0))
	await _wait_frames(6)
	await _capture("ragdoll_alive")
	target.call("_die", Vector3(0.0, 1.0, 6.0), "chest", "Audit")
	await _wait_frames(150)
	await _capture("ragdoll_dead")
	camera.queue_free()
	battlefield.queue_free()

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, file_name]
	var error := image.save_png(path)
	if error == OK:
		_captures += 1
		print("CAPTURE ", path)
	else:
		push_error("Cannot save %s: %s" % [path, error_string(error)])

func _load_map(map_name: String, team: String) -> Node3D:
	get_tree().set_meta("selected_map", map_name)
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", team)
	get_tree().set_meta("selected_role", "ASSAULT")
	get_tree().set_meta("selected_loadout", "BALANCED")
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate() as Node3D
	add_child(battlefield)
	await _wait_frames(8)
	return battlefield

func _set_hud_visible(battlefield: Node3D, visible: bool) -> void:
	var hud_layer = battlefield.get("hud")
	if hud_layer is CanvasLayer:
		(hud_layer as CanvasLayer).visible = visible
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		var player_hud = player.get("hud")
		if player_hud is CanvasLayer:
			(player_hud as CanvasLayer).visible = visible

func _freeze_bots() -> Array:
	var bots := get_tree().get_nodes_in_group("bots")
	for bot in bots:
		if bot is Node:
			(bot as Node).set_physics_process(false)
	return bots

func _add_free_camera(parent: Node3D, position: Vector3, target: Vector3) -> Camera3D:
	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 400.0
	parent.add_child(camera)
	camera.look_at_from_position(position, target, Vector3.UP)
	camera.current = true
	return camera

func _capture_battlefield_models() -> void:
	var battlefield := await _load_map("BATTLEFIELD", "IRON LEGION")
	var player = get_tree().get_first_node_in_group("player")
	_freeze_bots()
	if player is Node3D:
		(player as Node3D).global_position = Vector3(0.0, 0.4, 52.0)
		(player as Node3D).set("yaw", 0.0)
		(player as Node3D).set("health", 100.0)
		(player as Node3D).set("blood_vignette_time", 0.0)
		var camera = player.get("camera")
		if camera is Camera3D:
			(camera as Camera3D).current = true
	_set_hud_visible(battlefield, false)
	await _wait_frames(4)

	# First-person weapons and hands.
	if player != null:
		for index in [0, 1, 6, 7]:
			player.call("_switch_weapon", index)
			await _wait_frames(3)
			await _capture("weapon_%02d" % index)

	# Bots: squad silhouette and close-up.
	var bots := get_tree().get_nodes_in_group("bots")
	var shown := 0
	for bot in bots:
		if shown >= 3:
			break
		if bot == null or not is_instance_valid(bot):
			continue
		var bot_3d := bot as Node3D
		if bot_3d == null:
			continue
		bot_3d.global_position = Vector3(-1.7 + shown * 1.7, 0.1, 0.0)
		bot_3d.rotation.y = 0.0
		bot_3d.set("health", 100.0)
		var proc = bot_3d.get("_proc")
		if proc != null:
			proc.call("set_motion", 0.0, false)
			proc.call("set_aiming", true)
		var label = bot_3d.get("_label")
		if label is Node3D:
			(label as Node3D).visible = false
		elif label is CanvasItem:
			(label as CanvasItem).visible = false
		shown += 1
	var squad_camera := _add_free_camera(battlefield, Vector3(0.0, 1.7, 6.5), Vector3(0.0, 1.1, 0.0))
	await _wait_frames(10)
	await _capture("bots_squad")
	squad_camera.queue_free()
	var close_camera := _add_free_camera(battlefield, Vector3(0.0, 1.7, 2.8), Vector3(0.0, 1.1, 0.0))
	await _wait_frames(6)
	await _capture("bots_closeup")
	close_camera.queue_free()

	# Pickups and ammo crate.
	var weapon_pickup = PICKUP_SCRIPT.new()
	weapon_pickup.configure_weapon(0, 30, 150)
	weapon_pickup.position = Vector3(-1.0, 0.35, 0.0)
	battlefield.add_child(weapon_pickup)
	var ammo_pickup = PICKUP_SCRIPT.new()
	ammo_pickup.configure_ammo(48, 65.0)
	ammo_pickup.position = Vector3(1.0, 0.35, 0.0)
	battlefield.add_child(ammo_pickup)
	var pickup_camera := _add_free_camera(battlefield, Vector3(0.0, 1.4, 4.0), Vector3(0.0, 0.55, 0.0))
	await _wait_frames(4)
	await _capture("pickups")
	pickup_camera.queue_free()

	# Radio drone model.
	var drone = DRONE_SCRIPT.new()
	battlefield.add_child(drone)
	drone.call("launch", Vector3(0.0, 1.8, 0.0), 0.0, player, 120.0)
	drone.set_physics_process(false)
	var drone_camera := _add_free_camera(battlefield, Vector3(0.0, 1.6, 3.6), Vector3(0.0, 1.7, 0.0))
	await _wait_frames(4)
	await _capture("drone")
	drone_camera.queue_free()

	# Bunker / cover geometry.
	var bunker_camera := _add_free_camera(battlefield, Vector3(0.0, 5.0, 88.0), Vector3(0.0, 2.0, 78.0))
	await _wait_frames(3)
	await _capture("battlefield_bunker")
	bunker_camera.queue_free()

	battlefield.queue_free()
	await _wait_frames(3)

func _capture_village_models() -> void:
	var battlefield := await _load_map("VILLAGE", "RED FRONT")
	_freeze_bots()
	_set_hud_visible(battlefield, false)
	var overview := _add_free_camera(battlefield, Vector3(0.0, 26.0, 52.0), Vector3(0.0, 0.0, 0.0))
	await _wait_frames(4)
	await _capture("village_overview")
	overview.queue_free()
	var house := _add_free_camera(battlefield, Vector3(-28.0, 3.5, 34.0), Vector3(-28.0, 1.2, 22.0))
	await _wait_frames(3)
	await _capture("village_house")
	house.queue_free()
	battlefield.queue_free()
	await _wait_frames(3)

func _capture_polygon_models() -> void:
	get_tree().set_meta("selected_map", "POLYGON")
	get_tree().set_meta("selected_team", "IRON LEGION")
	get_tree().set_meta("selected_role", "ASSAULT")
	var packed: PackedScene = load(POLYGON_SCENE)
	var polygon := packed.instantiate() as Node3D
	add_child(polygon)
	await _wait_frames(8)
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		var hud = player.get("hud")
		if hud is CanvasLayer:
			(hud as CanvasLayer).visible = false
	var camera := _add_free_camera(polygon, Vector3(0.0, 2.0, 9.0), Vector3(0.0, 1.2, 0.0))
	await _wait_frames(4)
	await _capture("polygon_targets")
	camera.queue_free()
	polygon.queue_free()
	await _wait_frames(3)
