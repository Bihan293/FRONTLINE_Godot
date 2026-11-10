extends StaticBody3D
class_name FRONTLINEDiggableGround

## Runtime grid terrain for the entrenching shovel. Only the touched terrain
## chunk and its seam neighbor are rebuilt, keeping digging affordable on mobile.

const MAX_TRENCH_LEVEL := -2
const MAX_BERM_LEVEL := 4
const DIG_STEP := 0.18
const BERM_STEP := 0.18
const CHUNK_CELLS := 16

var terrain_size := Vector2(90.0, 90.0)
var cell_size := 2.0
var surface_material: Material
var height_sampler := Callable()
var _terrain_material: Material
var _cells_x := 0
var _cells_z := 0
var _cell_width := 0.0
var _cell_depth := 0.0
var _levels := PackedInt32Array()
var _base_heights := PackedFloat32Array()
var _chunks: Dictionary = {}
var _pending_chunks: Dictionary = {}
var _rebuild_queued := false

func configure(size: Vector2, tile_size: float, material: Material, sampler: Callable = Callable()) -> void:
	terrain_size = size
	cell_size = maxf(1.0, tile_size)
	surface_material = material
	height_sampler = sampler

func _ready() -> void:
	add_to_group("diggable_ground")
	collision_layer = 1
	collision_mask = 0
	_cells_x = maxi(1, ceili(terrain_size.x / cell_size))
	_cells_z = maxi(1, ceili(terrain_size.y / cell_size))
	_cell_width = terrain_size.x / float(_cells_x)
	_cell_depth = terrain_size.y / float(_cells_z)
	_levels.resize(_cells_x * _cells_z)
	_levels.fill(0)
	_base_heights.resize((_cells_x + 1) * (_cells_z + 1))
	for z in range(_cells_z + 1):
		for x in range(_cells_x + 1):
			var local_x := -terrain_size.x * 0.5 + float(x) * _cell_width
			var local_z := -terrain_size.y * 0.5 + float(z) * _cell_depth
			var base_height := float(height_sampler.call(local_x, local_z)) if height_sampler.is_valid() else 0.0
			_base_heights[_base_index(x, z)] = base_height
	if surface_material != null:
		_terrain_material = surface_material.duplicate() as Material
		var base_material := _terrain_material as BaseMaterial3D
		if base_material != null:
			base_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chunks_x := ceili(float(_cells_x) / float(CHUNK_CELLS))
	var chunks_z := ceili(float(_cells_z) / float(CHUNK_CELLS))
	for z in range(chunks_z):
		for x in range(chunks_x):
			_create_chunk(Vector2i(x, z))
			_rebuild_chunk(Vector2i(x, z))

func dig_at(world_position: Vector3) -> bool:
	var cell := _cell_at(world_position)
	if cell.x < 0 or cell.y < 0:
		return false
	var idx := _index(cell.x, cell.y)
	if _levels[idx] <= MAX_TRENCH_LEVEL:
		return false
	_levels[idx] -= 1
	_queue_cell_chunks(cell.x, cell.y)
	return true

func place_soil_at(world_position: Vector3) -> bool:
	var cell := _cell_at(world_position)
	if cell.x < 0 or cell.y < 0:
		return false
	var idx := _index(cell.x, cell.y)
	if _levels[idx] >= MAX_BERM_LEVEL:
		return false
	_levels[idx] += 1
	_queue_cell_chunks(cell.x, cell.y)
	return true

func cell_level_at(world_position: Vector3) -> int:
	var cell := _cell_at(world_position)
	if cell.x < 0 or cell.y < 0:
		return 0
	return _levels[_index(cell.x, cell.y)]

func surface_height_at(world_position: Vector3) -> float:
	var cell := _cell_at(world_position)
	if cell.x < 0 or cell.y < 0:
		return global_position.y
	return global_position.y + _base_height_for_cell(cell.x, cell.y) + _height_for_level(_levels[_index(cell.x, cell.y)])

func clamp_to_map(world_position: Vector3, margin := 0.35) -> Vector3:
	var local := to_local(world_position)
	local.x = clampf(local.x, -terrain_size.x * 0.5 + margin, terrain_size.x * 0.5 - margin)
	local.z = clampf(local.z, -terrain_size.y * 0.5 + margin, terrain_size.y * 0.5 - margin)
	return to_global(local)

func _cell_at(world_position: Vector3) -> Vector2i:
	if _cells_x <= 0 or _cells_z <= 0:
		return Vector2i(-1, -1)
	var local := to_local(world_position)
	var ix := floori((local.x + terrain_size.x * 0.5) / _cell_width)
	var iz := floori((local.z + terrain_size.y * 0.5) / _cell_depth)
	if ix < 0 or iz < 0 or ix >= _cells_x or iz >= _cells_z:
		return Vector2i(-1, -1)
	return Vector2i(ix, iz)

func _index(x: int, z: int) -> int:
	return z * _cells_x + x

func _base_index(x: int, z: int) -> int:
	return z * (_cells_x + 1) + x

func _base_height_for_cell(x: int, z: int) -> float:
	return (
		_base_heights[_base_index(x, z)]
		+ _base_heights[_base_index(x + 1, z)]
		+ _base_heights[_base_index(x, z + 1)]
		+ _base_heights[_base_index(x + 1, z + 1)]
	) * 0.25

func _height_for_level(level: int) -> float:
	return float(level) * (DIG_STEP if level < 0 else BERM_STEP)

func _create_chunk(chunk: Vector2i) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainChunk_%d_%d" % [chunk.x, chunk.y]
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.material_override = _terrain_material
	add_child(mesh_instance)
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "TerrainCollision_%d_%d" % [chunk.x, chunk.y]
	add_child(collision_shape)
	_chunks[chunk] = {"mesh": mesh_instance, "collision": collision_shape}

func _queue_cell_chunks(x: int, z: int) -> void:
	var chunk := Vector2i(
		floori(float(x) / float(CHUNK_CELLS)),
		floori(float(z) / float(CHUNK_CELLS))
	)
	_pending_chunks[chunk] = true
	# Vertical faces are owned by the cell on their west/north side. Refresh the
	# adjacent chunk when this cell is the first one across a chunk seam.
	if x > 0 and x % CHUNK_CELLS == 0:
		_pending_chunks[Vector2i(chunk.x - 1, chunk.y)] = true
	if z > 0 and z % CHUNK_CELLS == 0:
		_pending_chunks[Vector2i(chunk.x, chunk.y - 1)] = true
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_pending_chunks")

func _rebuild_pending_chunks() -> void:
	_rebuild_queued = false
	var pending := _pending_chunks.keys()
	_pending_chunks.clear()
	for chunk in pending:
		_rebuild_chunk(chunk)

func _rebuild_chunk(chunk: Vector2i) -> void:
	if not _chunks.has(chunk):
		return
	var chunk_data: Dictionary = _chunks[chunk]
	var mesh_instance := chunk_data["mesh"] as MeshInstance3D
	var collision_shape := chunk_data["collision"] as CollisionShape3D
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start_x := chunk.x * CHUNK_CELLS
	var start_z := chunk.y * CHUNK_CELLS
	var end_x := mini(_cells_x, start_x + CHUNK_CELLS)
	var end_z := mini(_cells_z, start_z + CHUNK_CELLS)
	for z in range(start_z, end_z):
		for x in range(start_x, end_x):
			var level := _levels[_index(x, z)]
			var level_offset := _height_for_level(level)
			var x0 := -terrain_size.x * 0.5 + float(x) * _cell_width
			var x1 := x0 + _cell_width
			var z0 := -terrain_size.y * 0.5 + float(z) * _cell_depth
			var z1 := z0 + _cell_depth
			var base00 := _base_heights[_base_index(x, z)]
			var base10 := _base_heights[_base_index(x + 1, z)]
			var base01 := _base_heights[_base_index(x, z + 1)]
			var base11 := _base_heights[_base_index(x + 1, z + 1)]
			var p00 := Vector3(x0, base00 + level_offset, z0)
			var p10 := Vector3(x1, base10 + level_offset, z0)
			var p01 := Vector3(x0, base01 + level_offset, z1)
			var p11 := Vector3(x1, base11 + level_offset, z1)
			_add_triangle(surface, p00, p01, p11)
			_add_triangle(surface, p00, p11, p10)
			if x + 1 < _cells_x:
				var right_level := _levels[_index(x + 1, z)]
				if right_level != level:
					var right_offset := _height_for_level(right_level)
					_add_wall(surface, p10, p11, Vector3(x1, base11 + right_offset, z1), Vector3(x1, base10 + right_offset, z0))
			if z + 1 < _cells_z:
				var far_level := _levels[_index(x, z + 1)]
				if far_level != level:
					var far_offset := _height_for_level(far_level)
					_add_wall(surface, p01, p11, Vector3(x1, base11 + far_offset, z1), Vector3(x0, base01 + far_offset, z1))
	surface.generate_normals()
	var terrain_mesh := surface.commit()
	mesh_instance.mesh = terrain_mesh
	var concave := ConcavePolygonShape3D.new()
	concave.set_backface_collision_enabled(true)
	concave.set_faces(terrain_mesh.get_faces())
	collision_shape.shape = concave

func _add_wall(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_triangle(surface, a, b, c)
	_add_triangle(surface, a, c, d)

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.set_uv(Vector2(a.x, a.z) * 0.12)
	surface.add_vertex(a)
	surface.set_uv(Vector2(b.x, b.z) * 0.12)
	surface.add_vertex(b)
	surface.set_uv(Vector2(c.x, c.z) * 0.12)
	surface.add_vertex(c)
