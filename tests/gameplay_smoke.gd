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
	_test_minimap_alignment()
	await _test_pause_freezes_bots()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _test_weapon_definitions() -> void:
	var player_script: Script = load("res://scripts/player.gd")
	_check(player_script != null, "player script missing")
	if player_script == null:
		return
	var constants: Dictionary = player_script.get_script_constant_map()
	var definitions: Array = constants.get("WEAPON_DEFS", [])
	_check(definitions.size() >= 5, "arsenal has fewer than five weapons")
	var seen: Dictionary = {}
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
