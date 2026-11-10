extends Node

## Headless smoke-test навигации: после смены карты граф должен пересобираться,
## а все спавны обеих фракций — иметь путь до середины карты и друг до друга.
## Запуск:
##   godot --headless --path . res://tests/navigation_smoke.tscn --quit-after 1800

const BATTLEFIELD_LAYOUT = preload("res://scripts/battlefield_layout.gd")
const VILLAGE_LAYOUT = preload("res://scripts/village_layout.gd")

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	var nav := get_node_or_null("/root/BotNavigation")
	_check(nav != null, "BotNavigation autoload is missing")
	if nav == null:
		_report()
		return

	await _test_map(nav, "BATTLEFIELD", BATTLEFIELD_LAYOUT)
	await _test_map(nav, "VILLAGE", VILLAGE_LAYOUT)

	MatchState.map_name = "BATTLEFIELD"
	nav.call("ensure_for_current_map")
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _test_map(nav: Node, map_name: String, layout) -> void:
	MatchState.map_name = map_name
	nav.call("ensure_for_current_map")

	var iron: Array = layout.spawns_iron()
	var red: Array = layout.spawns_red()
	var sectors: Array = layout.sectors()
	_check(not iron.is_empty(), "%s has no iron spawns" % map_name)
	_check(not red.is_empty(), "%s has no red spawns" % map_name)
	_check(not sectors.is_empty(), "%s has no sectors" % map_name)

	for i in range(iron.size()):
		var path: PackedVector3Array = nav.call("find_path", iron[i], red[0])
		_check(path.size() >= 2, "%s: iron spawn %d cannot reach enemy base" % [map_name, i])

	for j in range(red.size()):
		var path: PackedVector3Array = nav.call("find_path", red[j], iron[0])
		_check(path.size() >= 2, "%s: red spawn %d cannot reach enemy base" % [map_name, j])

	if not sectors.is_empty():
		var center: Vector3 = sectors[0].pos
		var spawn: Vector3 = iron[0]
		# Центр сектора может быть внутри руины/окопа — проверяем ближайшие подходы.
		var reachable := false
		for offset in [Vector3.ZERO, Vector3(8, 0, 0), Vector3(-8, 0, 0), Vector3(0, 0, 8), Vector3(0, 0, -8)]:
			var path: PackedVector3Array = nav.call("find_path", spawn, center + offset)
			if path.size() >= 2:
				reachable = true
				break
		_check(reachable, "%s: spawn cannot reach first sector" % map_name)

	await get_tree().process_frame

func _report() -> void:
	if _failures.is_empty():
		print("NAVIGATION_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("NAVIGATION_SMOKE_FAIL: " + failure)
		print("NAVIGATION_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
