extends Control
class_name FRONTLINEBattlefieldMapPreview

## A top-down camera looking at the actual box geometry used by Battlefield.
## Spawn markers are drawn as a UI overlay in the same world-to-screen mapping.

signal spawn_selected(index: int)

const LAYOUT = preload("res://scripts/battlefield_layout.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")
const MAP_WIDTH := 240.0
const MAP_DEPTH := 185.0
const MAP_MARGIN := 14.0

var show_spawns := false
var interactive := false
var selected_spawn := -1
var team_name := "IRON LEGION"

var _viewport: SubViewport
var _container: SubViewportContainer
var _camera: Camera3D
var _spawns: Array = []
var _layout: Variant = LAYOUT
var _map_id := "BATTLEFIELD"
var _map_width := MAP_WIDTH
var _map_depth := MAP_DEPTH

func _ready() -> void:
	_set_layout(str(get_tree().get_meta("selected_map", "BATTLEFIELD")))
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_update_spawns()
	_build_world_preview()
	resized.connect(_resize_preview)
	_resize_preview()
	queue_redraw()

func set_map(map_id: String) -> void:
	var changed := map_id != _map_id
	_set_layout(map_id)
	_update_spawns()
	if changed and _container != null and is_instance_valid(_container):
		remove_child(_container)
		_container.queue_free()
		_container = null
		_viewport = null
		_camera = null
		_build_world_preview()
		_resize_preview()
	queue_redraw()

func _set_layout(map_id: String) -> void:
	_map_id = map_id
	if map_id == "COUNTRYSIDE":
		_layout = COUNTRYSIDE_LAYOUT
		var dimensions: Vector2 = COUNTRYSIDE_LAYOUT.map_dimensions()
		_map_width = dimensions.x
		_map_depth = dimensions.y
	else:
		_layout = LAYOUT
		_map_width = MAP_WIDTH
		_map_depth = MAP_DEPTH

func _update_spawns() -> void:
	_spawns = _layout.spawns_red() if team_name.contains("RED") else _layout.spawns_iron()

func set_selected(index: int) -> void:
	selected_spawn = index
	queue_redraw()

func set_team(faction: String) -> void:
	team_name = faction
	_update_spawns()
	selected_spawn = 0
	queue_redraw()

func _build_world_preview() -> void:
	_container = SubViewportContainer.new()
	_container.name = "MapWorldView"
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.stretch = true
	_container.show_behind_parent = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	_viewport = SubViewport.new()
	_viewport.name = "BattlefieldTopDown"
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_container.add_child(_viewport)

	var world_root := Node3D.new()
	world_root.name = "BattlefieldGeometry"
	_viewport.add_child(world_root)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.045, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.80, 0.74)
	env.ambient_light_energy = 0.9
	environment.environment = env
	world_root.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.05
	sun.shadow_enabled = false
	world_root.add_child(sun)

	if _map_id == "COUNTRYSIDE":
		COUNTRYSIDE_LAYOUT.add_world(world_root, false, false)
	else:
		for data in _layout.boxes():
			var mesh_instance := MeshInstance3D.new()
			var box_mesh := BoxMesh.new()
			box_mesh.size = data.size
			mesh_instance.mesh = box_mesh
			mesh_instance.position = data.pos
			var material := StandardMaterial3D.new()
			material.albedo_color = data.color
			material.roughness = 0.95
			material.metallic = 0.0
			mesh_instance.material_override = material
			world_root.add_child(mesh_instance)

	_camera = Camera3D.new()
	_camera.name = "TopDownCamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.position = Vector3(0.0, maxf(180.0, _map_depth * 1.2), 0.0)
	_camera.rotation.x = -PI * 0.5
	_camera.current = true
	world_root.add_child(_camera)

func _resize_preview() -> void:
	if _viewport == null or _camera == null:
		return
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	var aspect := width / height
	_camera.size = maxf(_map_depth, _map_width / maxf(aspect, 0.1)) * 1.08
	queue_redraw()

func world_to_local(point: Vector3) -> Vector2:
	var usable := Vector2(maxf(size.x - MAP_MARGIN * 2.0, 1.0), maxf(size.y - MAP_MARGIN * 2.0, 1.0))
	var scale := minf(usable.x / _map_width, usable.y / _map_depth)
	return size * 0.5 + Vector2(point.x, -point.z) * scale

func _draw() -> void:
	var usable := Vector2(maxf(size.x - MAP_MARGIN * 2.0, 1.0), maxf(size.y - MAP_MARGIN * 2.0, 1.0))
	var scale := minf(usable.x / _map_width, usable.y / _map_depth)
	if scale <= 0.0:
		return
	var map_size := Vector2(_map_width, _map_depth) * scale
	var map_rect := Rect2(size * 0.5 - map_size * 0.5, map_size)
	draw_rect(map_rect, Color(0.68, 0.72, 0.63, 0.82), false, 1.5)
	for sector in _layout.sectors():
		var center := world_to_local(sector.pos)
		draw_arc(center, float(sector.radius) * scale, 0.0, TAU, 48, Color(0.92, 0.81, 0.34, 0.36), 1.5, true)
		var sector_label := str(sector.name)
		draw_string(ThemeDB.fallback_font, center + Vector2(5.0, -6.0), sector_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.9, 0.7, 0.72))

	if not show_spawns:
		return
	var marker_color := Color(0.78, 0.24, 0.18, 0.96) if team_name.contains("RED") else Color(0.28, 0.67, 0.88, 0.96)
	var font := ThemeDB.fallback_font
	for i in range(_spawns.size()):
		var marker := world_to_local(_spawns[i])
		var chosen := i == selected_spawn
		var radius := 11.0 if chosen else 9.0
		draw_circle(marker, radius + 3.0, Color(0.03, 0.04, 0.04, 0.78))
		draw_circle(marker, radius, Color(0.98, 0.77, 0.20, 0.98) if chosen else marker_color)
		draw_arc(marker, radius, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.92), 1.6, true)
		var text := str(i + 1)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string(font, marker - text_size * 0.5 + Vector2(0.0, 4.3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.05, 0.06, 0.06))

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var point := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	if point == Vector2.INF:
		return
	var nearest := -1
	var nearest_distance := 26.0
	for i in range(_spawns.size()):
		var d := point.distance_to(world_to_local(_spawns[i]))
		if d < nearest_distance:
			nearest = i
			nearest_distance = d
	if nearest >= 0:
		set_selected(nearest)
		spawn_selected.emit(nearest)
		accept_event()
