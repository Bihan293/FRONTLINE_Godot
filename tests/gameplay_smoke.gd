extends Node

## Headless smoke-test игровых данных: арсенал, меши оружия,
## выравнивание мини-карты и остановка ботов на паузе.
## Запуск:
##   godot --headless --path . res://tests/gameplay_smoke.tscn --quit-after 1800

const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const MINIMAP_SCRIPT = preload("res://scripts/minimap.gd")

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_test_weapon_definitions()
	await _test_diggable_ground()
	_test_minimap_alignment()
	_test_combat_roles_and_drone()
	_test_positional_combat_audio()
	await _test_pause_freezes_bots()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _test_combat_roles_and_drone() -> void:
	# 1. Drone controller mesh
	var controller: Node3D = WEAPON_MESHES.make_weapon("drone_controller")
	_check(controller != null, "drone_controller mesh missing")
	if controller != null:
		controller.free()

	# 2. Minimap sniper range and drone rendering
	var minimap = MINIMAP_SCRIPT.new()
	add_child(minimap)
	var dummy_player := CharacterBody3D.new()
	dummy_player.set_meta("player_role", "SNIPER")
	minimap.player = dummy_player
	_check(minimap._get_enemy_visible_range() == 70.0, "sniper radar range != 70.0")
	dummy_player.set_meta("player_role", "ASSAULT")
	_check(minimap._get_enemy_visible_range() == 38.0, "assault radar range != 38.0")
	minimap.queue_free()
	dummy_player.queue_free()

	# 3. Radio drone instantiation, collision, and tether limit
	var drone_script: Script = load("res://scripts/radio_drone.gd")
	_check(drone_script != null, "radio_drone script missing")
	if drone_script != null:
		var drone = drone_script.new()
		add_child(drone)
		_check(drone.get_node_or_null("DroneCollision") != null, "drone missing DroneCollision shape")
		_check(drone.get_node_or_null("DroneCamera") != null, "drone missing DroneCamera")
		_check(drone.get_node_or_null("TetherLine") != null, "drone missing TetherLine")

		# Test launch and tether limit
		var op := CharacterBody3D.new()
		add_child(op)
		drone.launch(Vector3(0, 2, 0), 0.0, op, 80.0)
		_check(drone.max_tether == 80.0, "drone tether length was not set correctly")
		_check(drone.operator == op, "drone operator was not assigned")

		# Move drone past tether
		drone.global_position = Vector3(0, 2, 100.0)
		drone.clamp_to_tether()
		var op_anchor: Vector3 = drone.call("_operator_anchor_position")
		_check(drone.global_position.distance_to(op_anchor) <= 80.05, "drone exceeded tether limit: %f > 80.05" % drone.global_position.distance_to(op_anchor))

		drone.return_to_operator()
		op.queue_free()

func _test_positional_combat_audio() -> void:
	var combat_audio_script: Script = load("res://scripts/combat_audio.gd")
	_check(combat_audio_script != null, "combat_audio.gd missing")
	if combat_audio_script != null:
		_check(AudioServer.get_bus_index("SFX") >= 0, "SFX audio bus missing")
		_check(AudioServer.get_bus_index("Ambience") >= 0, "Ambience audio bus missing")
		_check(AudioServer.get_bus_index("CombatDirect") >= 0, "CombatDirect audio bus missing")
		_check(AudioServer.get_bus_index("CombatOccluded") >= 0, "CombatOccluded audio bus missing")
		_check(AudioServer.get_bus_index("IndoorReverb") >= 0, "IndoorReverb audio bus missing")

		var constants: Dictionary = combat_audio_script.get_script_constant_map()
		var profiles: Dictionary = constants.get("WEAPON_PROFILES", {})
		_check(profiles.size() >= 8, "weapon audio profiles count < 8")
		_check(profiles.has("ak47") and profiles.has("kar98k") and profiles.has("panzerfaust"), "missing key weapon profiles")

	# GameSettings audio persistence test
	GameSettings.set_sfx_volume(0.68)
	GameSettings.set_ambience_volume(0.42)
	_check(absf(GameSettings.sfx_volume - 0.68) < 0.01, "sfx volume setter failed")
	_check(absf(GameSettings.ambience_volume - 0.42) < 0.01, "ambience volume setter failed")
	GameSettings.load_settings()
	_check(absf(GameSettings.sfx_volume - 0.68) < 0.01, "sfx volume did not persist to ConfigFile")
	_check(absf(GameSettings.ambience_volume - 0.42) < 0.01, "ambience volume did not persist to ConfigFile")
	# Restore standard defaults
	GameSettings.set_sfx_volume(0.90)
	GameSettings.set_ambience_volume(0.75)

	# AudioListener on Player
	var player_script: Script = load("res://scripts/player.gd")
	if player_script != null:
		var dummy_p: CharacterBody3D = player_script.new()
		add_child(dummy_p)
		var listener = dummy_p.get_node_or_null("Camera3D/PlayerAudioListener")
		if listener == null and dummy_p.camera != null:
			listener = dummy_p.camera.get_node_or_null("PlayerAudioListener")
		_check(listener != null and listener is AudioListener3D, "Player missing PlayerAudioListener under camera")
		dummy_p.queue_free()

	# AudioListener on Radio Drone
	var drone_script: Script = load("res://scripts/radio_drone.gd")
	if drone_script != null:
		var dummy_d = drone_script.new()
		add_child(dummy_d)
		var drone_listener = dummy_d.get_node_or_null("DroneCamera/DroneListener")
		_check(drone_listener != null and drone_listener is AudioListener3D, "Drone missing DroneListener under DroneCamera")
		dummy_d.queue_free()

func _test_weapon_definitions() -> void:
	var player_script: Script = load("res://scripts/player.gd")
	_check(player_script != null, "player script missing")
	if player_script == null:
		return
	var constants: Dictionary = player_script.get_script_constant_map()
	var definitions: Array = constants.get("WEAPON_DEFS", [])
	_check(definitions.size() >= 5, "arsenal has fewer than five weapons")
	var seen: Dictionary = {}
	var sidearm_index := int(constants.get("SIDEARM_INDEX", -1))
	_check(sidearm_index >= 0 and sidearm_index < definitions.size(), "backup sidearm index is invalid")
	if sidearm_index >= 0 and sidearm_index < definitions.size():
		_check(str(definitions[sidearm_index].get("id", "")) == "m1911", "backup sidearm is not the M1911")
	for definition in definitions:
		var weapon_id := str(definition["id"])
		_check(not weapon_id.is_empty(), "weapon with empty id")
		_check(not seen.has(weapon_id), "duplicate weapon id: " + weapon_id)
		seen[weapon_id] = true
		_check(int(definition["mag"]) > 0, weapon_id + " has invalid magazine")
		_check(int(definition["reserve"]) > 0, weapon_id + " has invalid reserve ammo")
		_check(float(definition["damage"]) > 0.0, weapon_id + " has invalid damage")
		_check(float(definition["range"]) > 0.0, weapon_id + " has invalid range")
		_check(int(definition["pellets"]) > 0, weapon_id + " has invalid pellet count")
		var model: Node3D = WEAPON_MESHES.make_weapon(weapon_id)
		_check(model != null, weapon_id + " has no weapon mesh")
		if model != null:
			model.free()
	_check(seen.size() == definitions.size(), "weapon ids are not unique")
	var shovel: Node3D = WEAPON_MESHES.make_weapon("entrenching_shovel")
	_check(shovel != null, "entrenching shovel mesh missing")
	if shovel != null:
		_check(shovel.get_node_or_null("Muzzle") == null, "shovel model has a weapon muzzle")
		shovel.free()

func _test_diggable_ground() -> void:
	var ground_script: Script = load("res://scripts/diggable_ground.gd")
	_check(ground_script != null, "diggable ground script missing")
	if ground_script == null:
		return
	var ground = ground_script.new()
	ground.configure(Vector2(32.0, 32.0), 2.0, StandardMaterial3D.new())
	add_child(ground)
	await get_tree().physics_frame
	var center := Vector3.ZERO
	_check(ground.dig_at(center), "shovel could not dig a fresh ground cell")
	_check(ground.cell_level_at(center) == -1, "dug cell did not lower by one level")
	_check(is_equal_approx(ground.surface_height_at(center), -0.18), "dug surface height is incorrect")
	_check(ground.dig_at(center), "shovel could not deepen an existing trench")
	_check(not ground.dig_at(center), "trench exceeded the configured depth")
	_check(ground.place_soil_at(center), "collected soil could not form a berm")
	_check(ground.cell_level_at(center) == -1, "berm did not restore the expected ground level")
	_check(ground.place_soil_at(center), "berm could not be raised above original terrain")
	for _i in range(4):
		_check(ground.place_soil_at(center), "berm could not be raised with another soil layer")
	_check(not ground.place_soil_at(center), "berm exceeded its configured height")
	await get_tree().process_frame
	await get_tree().physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(0.0, 2.0, 0.0), Vector3(0.0, -2.0, 0.0))
	query.collision_mask = 1
	var space_state: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var hit: Dictionary = space_state.intersect_ray(query)
	_check(not hit.is_empty() and hit.get("collider") == ground, "edited terrain is missing from physics collision")
	if not hit.is_empty():
		_check(absf(float(hit.position.y) - 0.72) < 0.02, "terrain collision did not follow the berm height")
	ground.queue_free()
	await get_tree().process_frame

func _test_minimap_alignment() -> void:
	var player := Node3D.new()
	player.position = Vector3(10.0, 0.0, 20.0)
	add_child(player)

	var minimap = MINIMAP_SCRIPT.new()
	add_child(minimap)
	minimap.size = Vector2(200.0, 200.0)
	minimap.player = player

	var center := Vector2(100.0, 100.0)
	var scale := 0.8
	var north: Vector2 = minimap._world_to_map(player.global_position + Vector3(0.0, 0.0, -10.0), center, scale)
	var east: Vector2 = minimap._world_to_map(player.global_position + Vector3(10.0, 0.0, 0.0), center, scale)
	_check(north.y < center.y, "minimap: north is not up")
	_check(east.x > center.x, "minimap: east is not right")
	_check(is_equal_approx(north.distance_to(center), 8.0), "minimap: north scale is wrong")
	_check(is_equal_approx(east.distance_to(center), 8.0), "minimap: east scale is wrong")

	minimap.queue_free()
	player.queue_free()
	await get_tree().process_frame

func _test_pause_freezes_bots() -> void:
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")
	var scene: PackedScene = load("res://scenes/Battlefield.tscn")
	_check(scene != null, "battlefield scene missing")
	if scene == null:
		return
	var battlefield := scene.instantiate()
	add_child(battlefield)
	await get_tree().process_frame
	await get_tree().process_frame

	var bots := get_tree().get_nodes_in_group("bots")
	_check(bots.size() >= 14, "expected at least 14 bots, got %d" % bots.size())
	var positions: Array[Vector3] = []
	for bot in bots:
		var bot_3d := bot as Node3D
		if bot_3d != null:
			positions.append(bot_3d.global_position)

	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "player missing")
	if player == null:
		battlefield.queue_free()
		return
	var original_weapon := int(player.get("current_weapon_index"))
	player.call("_toggle_sidearm")
	_check(int(player.get("current_weapon_index")) == 3, "quick sidearm toggle did not equip the M1911")
	player.call("_toggle_sidearm")
	_check(int(player.get("current_weapon_index")) == original_weapon, "quick sidearm toggle did not restore the primary weapon")
	player.call("_toggle_shovel")
	_check(bool(player.get("is_shovel_equipped")), "shovel toggle did not equip the shovel")
	player.call("_use_shovel_action", false)
	_check(int(player.get("carried_soil")) == 1, "equipped shovel did not dig soil from the map")
	player.call("_toggle_shovel")
	_check(not bool(player.get("is_shovel_equipped")), "shovel toggle did not restore the firearm")
	player.call("open_pause_menu")
	_check(get_tree().paused, "pause did not engage")

	# process_always=true — таймер идёт даже при paused tree.
	await get_tree().create_timer(0.35, true).timeout
	for i in range(mini(bots.size(), positions.size())):
		var bot_3d := bots[i] as Node3D
		if bot_3d != null:
			_check(bot_3d.global_position.distance_to(positions[i]) < 0.01, "bot %d moved while paused" % i)

	var pause_menu: Node = player.get("pause_menu")
	if pause_menu != null:
		pause_menu.call("close")
	_check(not get_tree().paused, "resume did not restore the tree")

	battlefield.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _report() -> void:
	if _failures.is_empty():
		print("GAMEPLAY_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("GAMEPLAY_SMOKE_FAIL: " + failure)
		print("GAMEPLAY_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
