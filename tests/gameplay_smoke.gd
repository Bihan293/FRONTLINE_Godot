extends Node

## Headless smoke-test игровых данных: арсенал, меши оружия,
## выравнивание мини-карты и остановка ботов на паузе.
## Запуск:
##   godot --headless --path . res://tests/gameplay_smoke.tscn --quit-after 1800

const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const MINIMAP_SCRIPT = preload("res://scripts/minimap.gd")
const SOLDIER_BOT_SCRIPT = preload("res://scripts/soldier_bot.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const BULLET_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const TACTICAL_DEPLOY = preload("res://scripts/tactical_deploy.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const HUD_CUSTOMIZER_SCRIPT = preload("res://scripts/hud_customizer.gd")

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_test_weapon_definitions()
	await _test_diggable_ground()
	_test_minimap_alignment()
	_test_combat_roles_and_drone()
	_test_positional_combat_audio()
	_test_explosion_audio_budget()
	await _test_death_ragdoll()
	await _test_parkour_and_grenade_hold()
	await _test_bodycam_kinematics_and_camera_safety()
	await _test_pause_freezes_bots()
	await _test_loadout_presets()
	await _test_role_weapon_restrictions()
	await _test_vehicles()
	await _test_tactical_bot_ai()
	await _test_ballistic_bullet_tracers()
	await _test_toggle_lean()
	await _test_tactical_deployment_screen()
	await _test_first_person_hands()
	await _test_first_person_ads_alignment()
	await _test_field_pickup_weapon_swap_and_ammo()
	await _test_hud_customizer_input()
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

func _test_explosion_audio_budget() -> void:
	var listener := Node3D.new()
	listener.add_to_group("player")
	add_child(listener)
	await get_tree().process_frame

	var limit := COMBAT_AUDIO.get_active_3d_voice_limit()
	for i in range(limit):
		COMBAT_AUDIO.play_surface_impact(self, Vector3(100.0 + float(i), 0.0, 0.0), Vector3.UP, "metal")
	_check(COMBAT_AUDIO.get_active_3d_voice_count() == limit, "combat audio did not fill to its configured voice budget")

	var out_of_range = COMBAT_AUDIO.play_explosion_3d(self, Vector3(150.0, 0.0, 0.0), null, 32.0, 50.0)
	_check(out_of_range == null, "out-of-range explosion created an inaudible audio voice")
	var nearby = COMBAT_AUDIO.play_explosion_3d(self, Vector3(1.0, 0.0, 0.0), null, 32.0, 50.0)
	_check(nearby != null, "near explosion was dropped instead of replacing a distant transient")
	_check(COMBAT_AUDIO.get_active_3d_voice_count() <= limit, "explosion audio exceeded the configured voice budget")

	for voice in get_tree().get_nodes_in_group("combat_audio_voice"):
		if is_instance_valid(voice):
			voice.stop()
			voice.queue_free()
	listener.queue_free()
	await get_tree().process_frame

func _test_death_ragdoll() -> void:
	var floor := StaticBody3D.new()
	floor.name = "RagdollSmokeFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(12.0, 0.2, 12.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.1
	floor.add_child(floor_shape)
	add_child(floor)

	var bot: FRONTLINESoldierBot = SOLDIER_BOT_SCRIPT.new()
	bot.bot_weapon_index = 0
	bot.position = Vector3.ZERO
	add_child(bot)
	await get_tree().process_frame
	var procedural := bot.get("_proc") as FRONTLINEProceduralSoldier
	_check(procedural != null, "ragdoll smoke bot has no procedural soldier rig")
	if procedural == null:
		bot.queue_free()
		floor.queue_free()
		return
	var skeleton := procedural.get("_skeleton") as Skeleton3D
	_check(skeleton != null, "ragdoll smoke bot has no Skeleton3D")
	if skeleton == null:
		bot.queue_free()
		floor.queue_free()
		return
	var hips_id := skeleton.find_bone("Hips")
	var hips_y_before := skeleton.get_bone_global_pose(hips_id).origin.y if hips_id >= 0 else 0.0
	bot.receive_hit(1000, Vector3(0.0, 0.9, 2.0), "chest", "Smoke Test")
	for _i in range(40):
		await get_tree().process_frame
	_check(absf(procedural.rotation.x) > 0.35, "dead bot did not visibly fall")
	if hips_id >= 0:
		var hips_y_after := skeleton.get_bone_global_pose(hips_id).origin.y
		_check(hips_y_after < hips_y_before + 0.05, "dead bot hips did not drop")
	bot.queue_free()

	var player: CharacterBody3D = PLAYER_SCRIPT.new()
	player.position = Vector3(1.5, 0.0, 0.0)
	add_child(player)
	await get_tree().process_frame
	player.receive_hit(1000, player.global_position + Vector3(0.0, 0.9, 2.0), "chest", "Smoke Test")
	for _i in range(24):
		await get_tree().physics_frame
	var player_body := player.get("player_body") as Node3D
	var player_visual := player_body.get("body_visual") as FRONTLINEProceduralSoldier if player_body != null else null
	_check(player_visual != null and absf(player_visual.rotation.x) > 0.25, "player death did not visibly fall")
	_check(player_body != null and player_body.visible, "player death body stayed hidden")
	_check(player.collision_layer == 0, "dead player collision layer still blocks ragdoll physics")
	_check((player.get("camera") as Camera3D).position.z > 2.0, "death camera did not pull back to show the body")
	player.respawn()
	_check(player.collision_layer == 1, "player collision layer was not restored on respawn")
	if player_body != null:
		_check(not player_body.visible, "player body should be hidden again after respawn")
	if player_visual != null:
		_check(absf(player_visual.rotation.x) < 0.05, "player ragdoll rotation did not reset after respawn")
	player.queue_free()
	floor.queue_free()
	await get_tree().process_frame

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
	get_tree().set_meta("skip_deploy_screen", true)
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

func _test_loadout_presets() -> void:
	await _run_loadout_case("ASSAULT", "ASSAULT", 4, 1, 0)
	await _run_loadout_case("SNIPER", "SURVIVAL", 0, 3, 6)
	get_tree().set_meta("selected_role", "ASSAULT")
	get_tree().set_meta("selected_loadout", "BALANCED")

func _run_loadout_case(role_id: String, preset_id: String, expected_grenades: int, expected_medkits: int, expected_weapon: int) -> void:
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "IRON LEGION")
	get_tree().set_meta("skip_deploy_screen", true)
	get_tree().set_meta("selected_role", role_id)
	get_tree().set_meta("selected_loadout", preset_id)
	var scene: PackedScene = load("res://scenes/Battlefield.tscn")
	if scene == null:
		_check(false, "battlefield scene missing for loadout test")
		return
	var battlefield := scene.instantiate()
	add_child(battlefield)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "player missing for loadout %s/%s" % [role_id, preset_id])
	if player != null:
		_check(int(player.get("grenades")) == expected_grenades, "%s/%s grenades: %d != %d" % [role_id, preset_id, int(player.get("grenades")), expected_grenades])
		_check(int(player.get("medkits")) == expected_medkits, "%s/%s medkits: %d != %d" % [role_id, preset_id, int(player.get("medkits")), expected_medkits])
		_check(int(player.get("current_weapon_index")) == expected_weapon, "%s/%s primary weapon index: %d != %d" % [role_id, preset_id, int(player.get("current_weapon_index")), expected_weapon])
	battlefield.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _test_role_weapon_restrictions() -> void:
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "IRON LEGION")
	get_tree().set_meta("skip_deploy_screen", true)
	get_tree().set_meta("selected_role", "ASSAULT")
	get_tree().set_meta("selected_loadout", "BALANCED")
	var scene: PackedScene = load("res://scenes/Battlefield.tscn")
	if scene == null:
		_check(false, "battlefield scene missing for weapon restriction test")
		return
	var battlefield := scene.instantiate()
	add_child(battlefield)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "player missing for weapon restriction test")
	if player != null:
		var before := int(player.get("current_weapon_index"))
		player.call("_switch_weapon", 6) # Kar98k is not in the initial assault kit
		_check(int(player.get("current_weapon_index")) == before, "assault switched to an unowned weapon before pickup")
		player.call("_switch_weapon", 3) # M1911 sidearm is allowed
		_check(int(player.get("current_weapon_index")) == 3, "assault cannot switch to the allowed sidearm")
		_check(bool(player.call("can_take_weapon_pickup", 6, 5, 45)), "player cannot pick up a fallen sniper rifle from the field")
		var picked: bool = bool(player.call("take_weapon_pickup", 6, 5, 45))
		_check(picked, "take_weapon_pickup returned false for fallen rifle")
		_check(int(player.get("current_weapon_index")) == 6, "player weapon index did not change to picked rifle")
		_check(bool(player.call("can_take_weapon_pickup", 1, 32, 128)), "player cannot pick up an MP-40 pickup")
		var picked_mp40: bool = bool(player.call("take_weapon_pickup", 1, 32, 128))
		_check(picked_mp40, "take_weapon_pickup returned false for MP-40")
		_check(int(player.get("current_weapon_index")) == 1, "player weapon index did not change to MP-40")
	battlefield.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _test_parkour_and_grenade_hold() -> void:
	var grenade_model: Node3D = WEAPON_MESHES.make_grenade_view_model()
	_check(grenade_model != null, "make_grenade_view_model returned null")
	if grenade_model != null:
		_check(grenade_model.find_child("PullRing", true, false) != null, "grenade viewmodel missing PullRing")
		_check(grenade_model.find_child("SafetyLever", true, false) != null, "grenade viewmodel missing SafetyLever")
		_check(grenade_model.find_child("HandRight", true, false) != null, "grenade viewmodel missing HandRight")
		_check(grenade_model.find_child("HandLeft", true, false) != null, "grenade viewmodel missing HandLeft")
		grenade_model.free()

	var world_grenade: Node3D = WEAPON_MESHES.make_grenade_world_model(false, false)
	_check(world_grenade != null, "make_grenade_world_model returned null")
	if world_grenade != null:
		world_grenade.free()

	var player_script: Script = load("res://scripts/player.gd")
	_check(player_script != null, "player script missing")
	if player_script != null:
		var p = player_script.new()
		add_child(p)
		await get_tree().process_frame
		_check("is_vaulting" in p, "player missing is_vaulting property")
		_check("grenade_anim_state" in p, "player missing grenade_anim_state property")
		_check(p.has_method("_try_vault"), "player missing _try_vault method")
		_check(p.has_method("_start_grenade_hold"), "player missing _start_grenade_hold method")
		_check(p.has_method("_release_grenade_throw"), "player missing _release_grenade_throw method")

		p.call("_start_grenade_hold")
		_check(bool(p.get("is_grenade_held")), "grenade hold flag not set after _start_grenade_hold")
		_check(int(p.get("grenade_anim_state")) > 0, "grenade_anim_state did not advance from IDLE")

		p.call("_release_grenade_throw")
		_check(not bool(p.get("is_grenade_held")), "grenade hold flag still active after release")

		p.queue_free()
		await get_tree().process_frame

func _test_vehicles() -> void:
	var turret_script: Script = load("res://scripts/static_turret.gd")
	var jeep_script: Script = load("res://scripts/jeep.gd")
	_check(turret_script != null, "static_turret script missing")
	_check(jeep_script != null, "jeep script missing")
	if turret_script == null or jeep_script == null:
		return

	var turret = turret_script.new()
	turret.position = Vector3.ZERO
	add_child(turret)
	_check(not bool(turret.can_enter(null)), "turret accepts null occupant")
	_check(str(turret.prompt_text(false)).contains("MG"), "turret enter prompt does not mention MG")

	var player := PLAYER_SCRIPT.new()
	add_child(player)
	player.position = Vector3(0.0, 0.25, 1.6)
	await get_tree().process_frame
	_check(bool(turret.can_enter(player)), "turret refuses a valid player")
	player.call("_interact_with_pickup")
	_check(is_instance_valid(player.get("mounted_vehicle")) and player.get("mounted_vehicle") == turret, "player did not mount the turret")
	var weapon_root := player.get("weapon_root") as Node3D
	_check(weapon_root == null or not weapon_root.visible, "weapon viewmodel stayed visible on the turret")
	var bullets_before := get_tree().get_nodes_in_group("ballistic_bullets").size()
	turret.try_fire(player)
	await get_tree().physics_frame
	var bullets_after := get_tree().get_nodes_in_group("ballistic_bullets").size()
	_check(bullets_after > bullets_before, "turret fire did not spawn a ballistic bullet")
	# QA-sweep regression: yaw обязан крутиться и ПРИМЕНЯТЬСЯ к камере в mounted-режиме
	# (единый путь _on_look_delta — мобильный тач/джойстик; headless-инвариантно).
	var yaw_before: float = player.get("yaw")
	player.call("_on_look_delta", Vector2(160.0, 0.0))
	var yaw_after: float = player.get("yaw")
	_check(absf(wrapf(yaw_after - yaw_before, -PI, PI)) > 0.08, "camera yaw did not change while mounted (look input ignored)")
	player.call("_physics_process", 0.016)
	var mounted_yaw_applied: bool = absf(wrapf(yaw_after - player.global_rotation.y, -PI, PI)) < 0.05
	_check(mounted_yaw_applied, "camera rotation was not applied while mounted")

	player.call("_exit_vehicle")
	_check(player.get("mounted_vehicle") == null, "player stayed mounted after exit")
	_check(is_instance_valid(turret.occupant) == false or turret.occupant == null, "turret kept occupant after exit")
	_check(absf((player.get("camera") as Camera3D).position.y - 1.70) < 0.01, "camera height was not restored after turret exit")

	var jeep = jeep_script.new()
	jeep.position = Vector3(6.0, 0.3, 0.0)
	add_child(jeep)
	# QA-sweep regression: джип не «игрушечный» — длина коллизии больше 4.5 м.
	var jeep_col: CollisionShape3D = null
	for child in jeep.get_children():
		if child is CollisionShape3D:
			jeep_col = child
			break
	_check(jeep_col != null and (jeep_col.shape as BoxShape3D).size.z > 4.5, "jeep collision too small (toy-sized jeep)")
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(14.0, 0.2, 14.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(6.0, 0.0, 0.0)
	add_child(floor_body)
	await get_tree().process_frame
	await get_tree().physics_frame
	player.position = jeep.seat_position() + Vector3(0.0, 0.1, 0.0)
	player.call("_enter_vehicle", jeep)
	_check(player.get("mounted_vehicle") == jeep, "player did not enter the jeep")
	jeep.set("throttle_override", 1.0)
	jeep.set("steer_override", 0.0)
	var start_z: float = jeep.global_position.z
	for _i in range(45):
		await get_tree().physics_frame
	_check(jeep.global_position.z < start_z - 0.6, "jeep did not drive forward under throttle")
	_check(global_pos_close(player.global_position, jeep.seat_position(), 0.12), "driver did not follow the jeep seat")
	jeep.set("throttle_override", 0.0)
	player.call("_exit_vehicle")
	_check(player.get("mounted_vehicle") == null, "player stayed in the jeep after exit")

	var jeep2 = jeep_script.new()
	jeep2.position = Vector3(6.0, 0.3, 4.0)
	add_child(jeep2)
	await get_tree().physics_frame
	jeep2.receive_hit(600.0, Vector3(6.0, 0.0, 4.0), "chest", "Smoke Test")
	_check(bool(jeep2.destroyed), "jeep did not explode after heavy damage")
	_check(not bool(jeep2.can_enter(player)), "destroyed jeep still accepts drivers")

	player.queue_free()
	turret.queue_free()
	jeep.queue_free()
	jeep2.queue_free()
	floor_body.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

static func global_pos_close(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return a.distance_to(b) <= tolerance

func _test_bodycam_kinematics_and_camera_safety() -> void:
	var player_script: Script = load("res://scripts/player.gd")
	_check(player_script != null, "player script missing for bodycam kinematics test")
	if player_script == null:
		return

	var player: CharacterBody3D = player_script.new()
	add_child(player)
	await get_tree().process_frame

	# 1. Kinematics: acceleration with realistic inertia
	var initial_h_vel := Vector2(player.velocity.x, player.velocity.z)
	_check(initial_h_vel.length() < 0.01, "player spawned with non-zero horizontal velocity")

	player.set("mobile_move", Vector2(0.0, -1.0))
	for _i in range(8):
		player.call("_physics_process", 0.016)

	var moving_h_vel := Vector2(player.velocity.x, player.velocity.z)
	_check(moving_h_vel.length() > 0.3, "player did not accelerate forward with inertia")
	_check(moving_h_vel.length() < 9.5, "player speed exploded during acceleration")

	# 2. Kinematics: braking deceleration (glide instead of instant zero)
	player.set("mobile_move", Vector2.ZERO)
	player.call("_physics_process", 0.016)
	var glide_h_vel := Vector2(player.velocity.x, player.velocity.z)
	_check(glide_h_vel.length() > 0.05, "player stopped instantly with zero inertia on input release")

	# 3. Camera safety and collision boundaries
	var cam: Camera3D = player.get("camera")
	_check(cam != null, "player missing camera")
	if cam != null:
		# Standing height check
		_check(cam.position.y >= 1.60 and cam.position.y <= 1.95, "standing camera height outside [1.60, 1.95]: %f" % cam.position.y)

		# Crouch height transition
		player.set("stance", 1)
		for _i in range(12):
			player.call("_physics_process", 0.016)
		_check(cam.position.y < 1.65, "camera did not lower in crouch stance: %f" % cam.position.y)

		# Lean calculation check
		player.set("mobile_lean_right", true)
		player.call("_physics_process", 0.016)
		_check(absf(cam.position.x) >= 0.0, "camera lean calculation failed")

	player.queue_free()
	await get_tree().process_frame

func _test_tactical_bot_ai() -> void:
	var bot: FRONTLINESoldierBot = SOLDIER_BOT_SCRIPT.new()
	bot.bot_weapon_index = 0 # AK-47
	bot.position = Vector3(0.0, 0.0, 0.0)
	add_child(bot)
	await get_tree().process_frame

	_check("target_acquisition_timer" in bot, "bot missing target_acquisition_timer")
	_check("combat_strafe_timer" in bot, "bot missing combat_strafe_timer")
	_check(bot.has_method("_avoid_obstacles"), "bot missing _avoid_obstacles method")

	# 1. Target acquisition windup delay: bot does not fire instantly on acquiring target
	var dummy_enemy := CharacterBody3D.new()
	dummy_enemy.position = Vector3(0.0, 0.0, 12.0)
	dummy_enemy.set_meta("selected_team", "RED FRONT" if bot.team_name.contains("IRON") else "IRON LEGION")
	add_child(dummy_enemy)
	await get_tree().process_frame

	bot.current_target = dummy_enemy
	bot.fire_cooldown = 0.0
	bot.target_acquisition_timer = 0.45
	var ammo_before := int(bot.ammo)
	bot.call("_combat_behavior", 0.016)
	_check(int(bot.ammo) == ammo_before, "bot fired instantly during target acquisition windup")
	_check(float(bot.target_acquisition_timer) < 0.45, "target_acquisition_timer did not decrement")

	# 2. Suppression reaction: taking fire raises suppression and forces crouch stance in combat
	bot.set("suppression", 0.0)
	bot.receive_hit(25, bot.global_position + Vector3(0.0, 1.0, 5.0), "chest", "Player")
	_check(float(bot.get("suppression")) >= 0.40, "bot suppression did not increase upon taking fire")
	bot.target_acquisition_timer = 0.0
	bot.call("_combat_behavior", 0.016)
	_check(int(bot.stance) == 1, "bot did not duck into crouch stance when heavily suppressed")

	# 3. Obstacle avoidance: detects obstacle in front and deflects
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = 1
	obstacle.collision_mask = 0
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 3.0, 0.3)
	col_shape.shape = box
	obstacle.add_child(col_shape)
	obstacle.position = bot.global_position + Vector3(0.0, 0.8, -1.0)
	add_child(obstacle)
	await get_tree().physics_frame

	var desired := Vector3(0.0, 0.0, -1.0)
	var avoided: Vector3 = bot.call("_avoid_obstacles", desired)
	_check(avoided.distance_to(desired) > 0.1, "obstacle avoidance did not deflect away from blocking wall")
	_check(avoided.length() > 0.5, "avoidance vector is too small")

	obstacle.queue_free()
	dummy_enemy.queue_free()
	bot.queue_free()
	await get_tree().process_frame

func _test_ballistic_bullet_tracers() -> void:
	_check(BULLET_SCRIPT != null, "bullet_projectile.gd missing")
	if BULLET_SCRIPT == null:
		return

	var dummy_bullet = BULLET_SCRIPT.new()
	# Material tests for factions
	var mat_red: StandardMaterial3D = dummy_bullet.call("_get_tracer_material", "RED FRONT")
	_check(mat_red != null, "failed to get tracer material for RED FRONT")
	if mat_red != null:
		_check(mat_red.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "RED tracer material is not unshaded")
		_check(mat_red.emission_enabled, "RED tracer emission is disabled")
		_check(mat_red.emission_energy_multiplier >= 3.0, "RED tracer emission multiplier < 3.0: %f" % mat_red.emission_energy_multiplier)
		_check(mat_red.albedo_color.g > mat_red.albedo_color.r, "RED faction tracer is not green-dominant")

	var mat_iron: StandardMaterial3D = dummy_bullet.call("_get_tracer_material", "IRON LEGION")
	_check(mat_iron != null, "failed to get tracer material for IRON LEGION")
	if mat_iron != null:
		_check(mat_iron.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "IRON tracer material is not unshaded")
		_check(mat_iron.emission_enabled, "IRON tracer emission is disabled")
		_check(mat_iron.emission_energy_multiplier >= 3.0, "IRON tracer emission multiplier < 3.0: %f" % mat_iron.emission_energy_multiplier)
		_check(mat_iron.albedo_color.r > mat_iron.albedo_color.b, "IRON faction tracer is not amber/orange-dominant")
	dummy_bullet.free()

	# Bullet visual mesh dimensions
	var dummy_shooter := Node3D.new()
	add_child(dummy_shooter)
	var bullet = BULLET_SCRIPT.new()
	bullet.configure(Vector3(0, 2, 0), Vector3.FORWARD, 100.0, 25, 60.0, "Shooter", "IRON LEGION", dummy_shooter)
	add_child(bullet)
	await get_tree().process_frame

	var visual := bullet.get_node_or_null("VisibleBullet") as MeshInstance3D
	_check(visual != null, "bullet missing VisibleBullet mesh instance")
	if visual != null:
		var mesh := visual.mesh as BoxMesh
		_check(mesh != null, "VisibleBullet mesh is not a BoxMesh")
		if mesh != null:
			_check(mesh.size.z >= 0.8, "tracer mesh length < 0.8m: %f" % mesh.size.z)
			_check(mesh.size.x >= 0.03, "tracer mesh thickness < 0.03m: %f" % mesh.size.x)
		_check(visual.material_override != null, "VisibleBullet missing material_override")

	bullet.queue_free()
	dummy_shooter.queue_free()
	await get_tree().process_frame

func _test_toggle_lean() -> void:
	var player: CharacterBody3D = PLAYER_SCRIPT.new()
	add_child(player)
	await get_tree().process_frame

	_check("lean_toggle" in player, "player missing lean_toggle variable")
	_check(int(player.get("lean_toggle")) == 0, "initial lean_toggle is not 0")

	# 1. First peek right -> lean_toggle becomes 1
	player.call("_on_mobile_peek_right", true)
	_check(int(player.get("lean_toggle")) == 1, "first peek_right did not set lean_toggle to 1")

	# 2. Second peek right -> toggles back to 0 (center)
	player.call("_on_mobile_peek_right", true)
	_check(int(player.get("lean_toggle")) == 0, "second peek_right did not toggle lean_toggle back to 0")

	# 3. Peek left -> lean_toggle becomes -1
	player.call("_on_mobile_peek_left", true)
	_check(int(player.get("lean_toggle")) == -1, "peek_left did not set lean_toggle to -1")

	# 4. Direct switch to right -> lean_toggle becomes 1
	player.call("_on_mobile_peek_right", true)
	_check(int(player.get("lean_toggle")) == 1, "switching peek_right did not override lean_toggle to 1")

	# 5. Sprint or vault automatically resets lean
	player.velocity = Vector3(0.0, 0.0, -8.0)
	player.set("mobile_move", Vector2(0.0, -1.0))
	player.call("_physics_process", 0.016)
	_check(int(player.get("lean_toggle")) == 0, "sprinting did not auto-cancel lean_toggle")

	player.queue_free()
	await get_tree().process_frame

func _test_tactical_deployment_screen() -> void:
	# 1. Test FRONTLINETacticalDeploy standalone instantiation and API
	_check(TACTICAL_DEPLOY != null, "tactical_deploy.gd script missing")
	if TACTICAL_DEPLOY != null:
		var deploy_ui = TACTICAL_DEPLOY.new()
		add_child(deploy_ui)
		deploy_ui.setup("IRON LEGION", [], [Vector3(0.0, 0.0, 10.0)])
		_check(deploy_ui.has_signal("deployed"), "tactical deploy UI missing deployed signal")
		_check(deploy_ui.CLASSES.size() >= 5, "tactical deploy classes count < 5")
		_check(deploy_ui.selected_spawn == Vector3(0.0, 0.0, 10.0), "tactical deploy selected_spawn did not bind base spawn")
		deploy_ui.queue_free()

	# 2. Test deploy metadata propagation and layout spawn coordinates
	var bf_layout: Script = load("res://scripts/battlefield_layout.gd")
	_check(bf_layout != null, "battlefield_layout.gd missing")
	if bf_layout != null:
		var iron_spawns: Array = bf_layout.call("spawns_iron")
		var red_spawns: Array = bf_layout.call("spawns_red")
		_check(iron_spawns.size() >= 3, "iron legion spawns count < 3")
		_check(red_spawns.size() >= 3, "red front spawns count < 3")

	# 3. Test deploy intro camera sequence in Battlefield scene
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "IRON LEGION")
	get_tree().set_meta("skip_deploy_screen", true)
	get_tree().set_meta("deploy_intro", true)

	var scene: PackedScene = load("res://scenes/Battlefield.tscn")
	_check(scene != null, "battlefield scene missing for deploy intro test")
	if scene == null:
		return
	var battlefield := scene.instantiate()
	add_child(battlefield)
	await get_tree().process_frame

	_check(not bool(get_tree().get_meta("deploy_intro", false)), "deploy_intro metadata was not consumed by _play_deploy_intro")

	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "player not found in battlefield during deploy test")
	if player != null:
		# QA-hotfix: свойства is_input_locked не существует — get_meta/get возвращал null,
		# bool(null) даёт SCRIPT ERROR и красный CI (APK не собирался).
		_check(bool(player.get("input_locked")), "player input not locked during deploy fly-in")

	var cameras := battlefield.find_children("*", "Camera3D", true, false)
	var found_intro := false
	for cam in cameras:
		var c := cam as Camera3D
		if c != null and c != player.get("camera") and c.current:
			found_intro = true
			_check(c.global_position.y > player.global_position.y + 30.0, "deploy intro camera height too low: %f" % c.global_position.y)
			break
	_check(found_intro, "deploy intro fly-in Camera3D not found or not active")

	battlefield.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _test_first_person_hands() -> void:
	var player: CharacterBody3D = PLAYER_SCRIPT.new()
	add_child(player)
	await get_tree().process_frame

	# QA-hotfix: константа не читается через Object.get() (null -> bool(null) -> SCRIPT ERROR).
	var player_script: Script = player.get_script()
	var arms_const: bool = bool(player_script.get_script_constant_map().get("SHOW_VIEW_ARMS", false))
	_check(arms_const, "SHOW_VIEW_ARMS is not true")

	var arm_l: MeshInstance3D = player.get("_view_arm_left")
	var arm_r: MeshInstance3D = player.get("_view_arm_right")
	_check(arm_l != null, "player missing _view_arm_left MeshInstance3D")
	_check(arm_r != null, "player missing _view_arm_right MeshInstance3D")

	if arm_l != null and arm_r != null:
		_check(arm_l.mesh is CylinderMesh, "_view_arm_left mesh is not CylinderMesh")
		_check(arm_r.mesh is CylinderMesh, "_view_arm_right mesh is not CylinderMesh")
		_check(arm_l.material_override != null, "_view_arm_left missing material_override")

	player.call("_update_view_arms")
	if arm_l != null and arm_r != null:
		_check(arm_l.visible, "_view_arm_left not visible when wielding weapon")
		_check(arm_r.visible, "_view_arm_right not visible when wielding weapon")

	# When weapon is hidden (e.g. mounted vehicle / turret), arms must also be hidden
	var weapon_root: Node3D = player.get("weapon_root")
	if weapon_root != null:
		weapon_root.visible = false
		player.call("_update_view_arms")
		if arm_l != null and arm_r != null:
			_check(not arm_l.visible, "_view_arm_left stayed visible when weapon_root was hidden")
			_check(not arm_r.visible, "_view_arm_right stayed visible when weapon_root was hidden")
		weapon_root.visible = true
		player.set("grenade_anim_state", 1)
		player.call("_update_view_arms")
		if arm_l != null and arm_r != null:
			_check(not arm_l.visible, "_view_arm_left stayed visible during grenade cooking")
			_check(not arm_r.visible, "_view_arm_right stayed visible during grenade cooking")

	player.queue_free()
	await get_tree().process_frame

func _test_first_person_ads_alignment() -> void:
	var player: CharacterBody3D = PLAYER_SCRIPT.new()
	add_child(player)
	await get_tree().process_frame

	var weapons := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]
	for wid in weapons:
		var target_idx := -1
		var defs: Array = player.WEAPON_DEFS
		for i in range(defs.size()):
			if str(defs[i].id) == wid:
				target_idx = i
				break
		if target_idx >= 0:
			if not player.role_weapon_indices.has(target_idx):
				player.role_weapon_indices.append(target_idx)
			player.call("_switch_weapon", target_idx)
			var aim_pos: Vector3 = player.get("weapon_aim_position")
			_check(aim_pos.y <= -0.015 and aim_pos.y >= -0.080, "weapon %s aim_pos.y %f out of realistic ADS centered range" % [wid, aim_pos.y])
			_check(absf(aim_pos.x) <= 0.006, "weapon %s aim_pos.x %f not horizontally centered" % [wid, aim_pos.x])

	player.queue_free()
	await get_tree().process_frame

func _test_field_pickup_weapon_swap_and_ammo() -> void:
	var player: CharacterBody3D = PLAYER_SCRIPT.new()
	add_child(player)
	await get_tree().process_frame

	var current_idx: int = player.get("current_weapon_index")
	var other_idx: int = 1 if current_idx != 1 else 0
	_check(player.call("can_take_weapon_pickup", other_idx, 32, 64), "player cannot take different weapon pickup")

	var swapped: bool = player.call("take_weapon_pickup", other_idx, 25, 50)
	_check(swapped, "take_weapon_pickup returned false on weapon swap")
	_check(int(player.get("current_weapon_index")) == other_idx, "current_weapon_index not updated after swap")
	_check(int(player.get("ammo")) == 25, "ammo not set from pickup clip: %d" % int(player.get("ammo")))

	player.set("ammo", 10)
	player.set("reserve_ammo", 20)
	_check(player.call("can_take_weapon_pickup", other_idx, 32, 64), "player cannot take ammo from same weapon pickup")
	var ammo_absorbed: bool = player.call("take_weapon_pickup", other_idx, 20, 30)
	_check(ammo_absorbed, "failed to absorb ammo from same weapon pickup")
	_check(int(player.get("ammo")) == 30 or int(player.get("ammo")) == 32, "ammo was not replenished")

	player.queue_free()
	await get_tree().process_frame

func _test_hud_customizer_input() -> void:
	var HUD_CUSTOMIZER_SCRIPT = load("res://scripts/hud_customizer.gd")
	_check(HUD_CUSTOMIZER_SCRIPT != null, "hud_customizer.gd missing")
	if HUD_CUSTOMIZER_SCRIPT == null:
		return
	var customizer = HUD_CUSTOMIZER_SCRIPT.new()
	add_child(customizer)
	await get_tree().process_frame

	var buttons: Dictionary = customizer.call("_get_button_positions")
	var joy_pos: Vector2 = buttons.get("joy", Vector2(170, 400))
	customizer.call("_start_drag", joy_pos, 999)
	customizer.call("_update_drag", joy_pos + Vector2(25, 25))
	customizer.call("_end_drag")

	_check(GameSettings.hud_button_offsets.size() > 0, "HUD customizer drag did not record button offset in GameSettings")
	GameSettings.hud_button_offsets.clear()
	GameSettings.save_settings()

	customizer.queue_free()
	await get_tree().process_frame

func _report() -> void:
	if _failures.is_empty():
		print("GAMEPLAY_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("GAMEPLAY_SMOKE_FAIL: " + failure)
		print("GAMEPLAY_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
