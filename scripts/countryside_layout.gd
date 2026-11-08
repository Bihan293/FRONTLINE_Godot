extends RefCounted
class_name FRONTLINECountrysideLayout

## Проработанная основа новой карты: рельеф, грунтовые улицы, поля,
## лесополосы и размеченные места будущих домов. Зданий и уличных props нет.

const MAP_WIDTH := 216.0
const MAP_DEPTH := 168.0
const TERRAIN_CELLS_X := 72
const TERRAIN_CELLS_Z := 56
const TREE_SEED := 260911
const PLOT_SIZE := Vector2(18.0, 18.0)
const PLOT_X := [-44.0, -16.0, 12.0, 40.0]
const PLOT_Z := [-42.0, -14.0, 14.0, 42.0]
const STREET_X := [-58.0, -30.0, -2.0, 26.0, 54.0]
const STREET_Z := [-56.0, -28.0, 0.0, 28.0, 56.0]
static var _height_noise_cache: Array[FastNoiseLite] = []

static func map_dimensions() -> Vector2:
	return Vector2(MAP_WIDTH, MAP_DEPTH)

static func get_building_plots() -> Array[Dictionary]:
	var plots: Array[Dictionary] = []
	var index := 1
	for z in PLOT_Z:
		for x in PLOT_X:
			plots.append({
				"name": "PLOT_%02d" % index,
				"position": Vector3(x, height_at(x, z), z),
				"size": Vector3(PLOT_SIZE.x, 0.0, PLOT_SIZE.y)
			})
			index += 1
	return plots

static func spawns_iron() -> Array[Vector3]:
	return _spawn_row(74.0)

static func spawns_red() -> Array[Vector3]:
	return _spawn_row(-74.0)

static func _spawn_row(z: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x in [-18.0, -9.0, 0.0, 9.0, 18.0]:
		points.append(Vector3(x, height_at(x, z) + 0.12, z))
	return points

static func sectors() -> Array[Dictionary]:
	return [
		{"name": "A", "label": "КВАРТАЛ", "pos": Vector3(-37.0, height_at(-37.0, 0.0), 0.0), "radius": 14.0, "owner": "NEUTRAL"},
		{"name": "B", "label": "ПЕРЕКРЁСТОК", "pos": Vector3(-2.0, height_at(-2.0, 0.0), 0.0), "radius": 14.0, "owner": "NEUTRAL"},
		{"name": "C", "label": "ПОЛЯНА", "pos": Vector3(72.0, height_at(72.0, 0.0), 0.0), "radius": 16.0, "owner": "NEUTRAL"},
	]

## Возвращает деревья также как навигационные препятствия для ботов.
## battlefield.gd создаёт визуализацию и физику пачкой через add_world().
static func boxes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for tree in _tree_locations():
		var x: float = tree.x
		var z: float = tree.z
		var scale: float = tree.scale
		var trunk_height := 4.8 * scale
		out.append({
			"pos": Vector3(x, trunk_height * 0.5, z),
			"size": Vector3(0.70 * scale, trunk_height, 0.70 * scale),
			"color": Color(0.22, 0.18, 0.12),
			"solid": true,
			"kind": "tree_obstacle",
			"cast_shadow": false
		})
	return out

static func height_at(x: float, z: float) -> float:
	var noises := _make_height_noises()
	return _height_at(x, z, noises[0], noises[1])

static func _make_height_noises() -> Array[FastNoiseLite]:
	if not _height_noise_cache.is_empty():
		return _height_noise_cache
	var rolling := FastNoiseLite.new()
	rolling.seed = 1947
	rolling.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	rolling.frequency = 0.010
	rolling.fractal_octaves = 4
	rolling.fractal_lacunarity = 2.0
	rolling.fractal_gain = 0.48
	var detail := FastNoiseLite.new()
	detail.seed = 81
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail.frequency = 0.038
	detail.fractal_octaves = 2
	_height_noise_cache = [rolling, detail]
	return _height_noise_cache

static func _height_at(x: float, z: float, rolling: FastNoiseLite, detail: FastNoiseLite) -> float:
	var broad := rolling.get_noise_2d(x, z) * 3.0
	var small := detail.get_noise_2d(x, z) * 0.42
	var ridge := sin(x * 0.023 + z * 0.012) * cos(z * 0.027 - x * 0.008) * 0.55
	var hill_a := _hill(x, z, 77.0, -48.0, 22.0, 2.2)
	var hill_b := _hill(x, z, 83.0, 48.0, 25.0, 2.7)
	var hill_c := _hill(x, z, -76.0, 4.0, 30.0, 1.8)
	var ground := broad + small + ridge + hill_a + hill_b + hill_c

	# Плавно снижаем шум в городе, оставляя участок с небольшим естественным уклоном.
	var town_edge := minf(62.0 - absf(x), 60.0 - absf(z))
	var town_blend := clampf((town_edge + 4.0) / 16.0, 0.0, 0.94)
	ground = lerpf(ground, 0.28, town_blend)

	# Дороги и будущие площадки под здания лежат на более ровном грунте.
	var road_distance := _street_distance(x, z)
	if road_distance < 5.5:
		var road_blend := 1.0 - _smoothstep(3.4, 5.5, road_distance)
		ground = lerpf(ground, 0.28, road_blend * 0.92)
	var plot_distance := _plot_distance(x, z)
	if plot_distance < 2.2:
		var plot_blend := 1.0 - _smoothstep(1.0, 2.2, plot_distance)
		ground = lerpf(ground, 0.28, plot_blend * 0.94)

	# Обе стартовые линии выровнены для появления бойцов на одной высоте.
	if absf(x) < 28.0 and absf(absf(z) - 74.0) < 5.0:
		ground = lerpf(ground, 0.28, 0.95)
	return ground

static func _smoothstep(edge0: float, edge1: float, value: float) -> float:
	var t := clampf((value - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _hill(x: float, z: float, center_x: float, center_z: float, radius: float, amplitude: float) -> float:
	var dx := (x - center_x) / radius
	var dz := (z - center_z) / (radius * 0.72)
	return amplitude * exp(-2.0 * (dx * dx + dz * dz))

static func _street_distance(x: float, z: float) -> float:
	var best := INF
	if absf(z) < 61.0:
		for road_x in STREET_X:
			best = minf(best, absf(x - road_x))
	if absf(x) < 67.0:
		for road_z in STREET_Z:
			best = minf(best, absf(z - road_z))
	# Две грунтовые дороги связывают восточный край города с открытым полем.
	best = minf(best, _distance_to_segment(x, z, Vector2(44.0, -22.0), Vector2(101.0, -55.0)))
	best = minf(best, _distance_to_segment(x, z, Vector2(44.0, 22.0), Vector2(101.0, 55.0)))
	return best

static func _distance_to_segment(x: float, z: float, a: Vector2, b: Vector2) -> float:
	var point := Vector2(x, z)
	var segment := b - a
	var length_sq := segment.length_squared()
	if is_zero_approx(length_sq):
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(a + segment * t)

static func _plot_distance(x: float, z: float) -> float:
	var best := INF
	for plot_z in PLOT_Z:
		for plot_x in PLOT_X:
			var dx := maxf(absf(x - plot_x) - PLOT_SIZE.x * 0.5, 0.0)
			var dz := maxf(absf(z - plot_z) - PLOT_SIZE.y * 0.5, 0.0)
			best = minf(best, Vector2(dx, dz).length())
	return best

## Создаёт один низкополигональный рельеф с коллизией, травой,
## лесополосами и 16 пустыми размеченными участками.
static func add_world(parent: Node3D, with_collision: bool = true, detailed: bool = true) -> void:
	var root := Node3D.new()
	root.name = "CountrysideLandscape"
	parent.add_child(root)
	var noises := _make_height_noises()
	var terrain_mesh := _make_terrain_mesh(noises[0], noises[1], TERRAIN_CELLS_X if detailed else 48, TERRAIN_CELLS_Z if detailed else 36)
	var terrain_instance := MeshInstance3D.new()
	terrain_instance.name = "RollingGround"
	terrain_instance.mesh = terrain_mesh
	terrain_instance.material_override = _terrain_material()
	terrain_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(terrain_instance)

	if with_collision:
		var terrain_body := StaticBody3D.new()
		terrain_body.name = "LandscapeCollision"
		var terrain_collision := CollisionShape3D.new()
		var terrain_shape := ConcavePolygonShape3D.new()
		terrain_shape.set_faces(terrain_mesh.get_faces())
		terrain_collision.shape = terrain_shape
		terrain_body.add_child(terrain_collision)
		root.add_child(terrain_body)
		_add_world_bounds(terrain_body)

	_add_forest(root, noises[0], noises[1], with_collision)
	_add_grass(root, noises[0], noises[1], detailed)
	_add_building_plot_marks(root, noises[0], noises[1])

static func _make_terrain_mesh(rolling: FastNoiseLite, detail: FastNoiseLite, cells_x: int, cells_z: int) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stride := cells_x + 1
	for z_index in range(cells_z + 1):
		var z := -MAP_DEPTH * 0.5 + MAP_DEPTH * float(z_index) / float(cells_z)
		for x_index in range(cells_x + 1):
			var x := -MAP_WIDTH * 0.5 + MAP_WIDTH * float(x_index) / float(cells_x)
			var y := _height_at(x, z, rolling, detail)
			tool.set_color(_terrain_vertex_color(x, z, y, rolling))
			tool.set_uv(Vector2((x + MAP_WIDTH * 0.5) * 0.16, (z + MAP_DEPTH * 0.5) * 0.16))
			tool.add_vertex(Vector3(x, y, z))
	for z_index in range(cells_z):
		for x_index in range(cells_x):
			var a := z_index * stride + x_index
			var b := a + 1
			var c := a + stride
			var d := c + 1
			tool.add_index(a)
			tool.add_index(c)
			tool.add_index(d)
			tool.add_index(a)
			tool.add_index(d)
			tool.add_index(b)
	tool.generate_normals()
	return tool.commit()

static func _terrain_vertex_color(x: float, z: float, height: float, noise: FastNoiseLite) -> Color:
	var variation := noise.get_noise_2d(x * 1.8, z * 1.8) * 0.055
	var grass := _color_offset(Color(0.39, 0.42, 0.29), variation)
	if absf(x) < 62.0 and absf(z) < 60.0:
		grass = _color_offset(Color(0.37, 0.36, 0.29), variation)
	if x > 50.0 and z > 3.0:
		grass = _color_offset(Color(0.44, 0.46, 0.30), variation)
	if height < -1.2:
		grass = grass.darkened(0.08)
	if height > 2.3:
		grass = grass.lightened(0.07)
	var road := _street_distance(x, z)
	if road < 3.6:
		return Color(0.32, 0.29, 0.23).lightened(variation)
	if road < 5.4:
		return grass.lerp(Color(0.32, 0.29, 0.23), 1.0 - (road - 3.6) / 1.8)
	var plot := _plot_distance(x, z)
	if plot < 1.1:
		return Color(0.43, 0.40, 0.32).lightened(variation)
	return grass

static func _color_offset(color: Color, amount: float) -> Color:
	return Color(
		clampf(color.r + amount, 0.0, 1.0),
		clampf(color.g + amount, 0.0, 1.0),
		clampf(color.b + amount, 0.0, 1.0),
		color.a
	)

static func _terrain_material() -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.seed = 411
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([Color(0.76, 0.76, 0.76), Color(0.90, 0.90, 0.90), Color(1.0, 1.0, 1.0)])
	texture.color_ramp = ramp
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

static func _tree_locations() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED
	# Северная и южная краевые лесополосы. Оставляем чистые коридоры для спавнов.
	for row in range(2):
		for x_step in range(22):
			var x := -98.0 + float(x_step) * 9.0 + float(row) * 4.2 + rng.randf_range(-1.4, 1.4)
			if absf(x) < 25.0:
				continue
			for side_value in [-1.0, 1.0]:
				var side: float = side_value
				var z := side * (69.0 + float(row) * 5.5 + rng.randf_range(-1.4, 1.4))
				out.append(_tree_data(x, z, rng))
	# Боковые полосы закрывают границы, не перекрывая пространство города.
	for row in range(2):
		for z_step in range(16):
			var z := -62.0 + float(z_step) * 8.2 + float(row) * 3.8 + rng.randf_range(-1.2, 1.2)
			for side_value in [-1.0, 1.0]:
				var side: float = side_value
				var x := side * (94.0 + float(row) * 5.0 + rng.randf_range(-1.4, 1.4))
				out.append(_tree_data(x, z, rng))
	# Внутренняя полоса отделяет город от открытых полей; в центре оставлен проезд.
	for z_step in range(15):
		var z := -58.0 + float(z_step) * 8.0 + rng.randf_range(-1.3, 1.3)
		if absf(z) < 10.0:
			continue
		out.append(_tree_data(77.0 + rng.randf_range(-1.7, 1.7), z, rng))
	# Небольшие группы на краях поля, оставляющие широкую чистую поляну на востоке.
	for center in [Vector2(-80.0, -52.0), Vector2(-80.0, 52.0), Vector2(86.0, -48.0)]:
		for i in range(7):
			var angle := TAU * float(i) / 7.0
			var radius := rng.randf_range(4.5, 9.0)
			out.append(_tree_data(center.x + cos(angle) * radius, center.y + sin(angle) * radius, rng))
	return out

static func _tree_data(x: float, z: float, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"x": x,
		"z": z,
		"scale": rng.randf_range(0.84, 1.20),
		"species": "deciduous" if rng.randf() < 0.22 else "pine"
	}

static func _add_forest(parent: Node3D, rolling: FastNoiseLite, detail: FastNoiseLite, with_collision: bool) -> void:
	var trees := _tree_locations()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.09
	trunk_mesh.bottom_radius = 0.18
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 6
	var pine_mesh := CylinderMesh.new()
	pine_mesh.top_radius = 0.0
	pine_mesh.bottom_radius = 0.5
	pine_mesh.height = 1.0
	pine_mesh.radial_segments = 7
	var deciduous_mesh := SphereMesh.new()
	deciduous_mesh.radius = 0.5
	deciduous_mesh.height = 1.0
	deciduous_mesh.radial_segments = 7
	deciduous_mesh.rings = 4
	var trunks := _new_multimesh(parent, "ForestTrunks", trunk_mesh, Color(0.27, 0.20, 0.13))
	var pines := _new_multimesh(parent, "PineCanopies", pine_mesh, Color(0.19, 0.27, 0.19))
	var leaves := _new_multimesh(parent, "DeciduousCanopies", deciduous_mesh, Color(0.31, 0.36, 0.22))
	var pine_count := 0
	var deciduous_count := 0
	for tree in trees:
		if tree.species == "pine":
			pine_count += 3
		else:
			deciduous_count += 3
	trunks.multimesh.instance_count = trees.size()
	pines.multimesh.instance_count = pine_count
	leaves.multimesh.instance_count = deciduous_count
	var pine_index := 0
	var deciduous_index := 0
	for tree_index in range(trees.size()):
		var tree: Dictionary = trees[tree_index]
		var x: float = tree.x
		var z: float = tree.z
		var scale: float = tree.scale
		var ground_y := _height_at(x, z, rolling, detail)
		var trunk_height := 4.8 * scale
		trunks.multimesh.set_instance_transform(tree_index, _scaled_transform(Vector3(0.33 * scale, trunk_height, 0.33 * scale), Vector3(x, ground_y + trunk_height * 0.5, z)))
		if with_collision:
			var collision := CollisionShape3D.new()
			var collider := CylinderShape3D.new()
			collider.radius = 0.34 * scale
			collider.height = trunk_height
			collision.shape = collider
			collision.position = Vector3(x, ground_y + trunk_height * 0.5, z)
			var body := parent.get_node_or_null("LandscapeCollision") as StaticBody3D
			if body != null:
				body.add_child(collision)
		if tree.species == "pine":
			for canopy in [Vector3(2.35, 3.7, 2.35), Vector3(1.95, 3.5, 1.95), Vector3(1.55, 3.1, 1.55)]:
				var center_y := ground_y + (4.0 + float(pine_index % 3) * 1.35) * scale
				var shape_scale := Vector3(canopy.x * scale, canopy.y * scale, canopy.z * scale)
				pines.multimesh.set_instance_transform(pine_index, _scaled_transform(shape_scale, Vector3(x, center_y, z)))
				pine_index += 1
		else:
			var clumps := [Vector3(-0.85, 0.0, 0.0), Vector3(0.85, 0.0, 0.05), Vector3(0.0, 0.3, -0.4)]
			for clump in clumps:
				var center := Vector3(x + clump.x * scale, ground_y + (5.0 + clump.y) * scale, z + clump.z * scale)
				leaves.multimesh.set_instance_transform(deciduous_index, _scaled_transform(Vector3(2.05, 1.75, 2.0) * scale, center))
				deciduous_index += 1
	leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trunks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	leaves.custom_aabb = AABB(Vector3(-110.0, -2.0, -86.0), Vector3(220.0, 18.0, 172.0))
	pines.custom_aabb = leaves.custom_aabb
	trunks.custom_aabb = leaves.custom_aabb

static func _new_multimesh(parent: Node3D, node_name: String, mesh: Mesh, color: Color) -> MultiMeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _scaled_transform(scale: Vector3, position: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY.scaled(scale), position)

static func _add_grass(parent: Node3D, rolling: FastNoiseLite, detail: FastNoiseLite, detailed: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED + 910
	var requested_count := 2300 if detailed else 720
	var blade_mesh := _make_grass_mesh()
	var grass := _new_multimesh(parent, "MeadowGrass", blade_mesh, Color(0.39, 0.43, 0.25))
	(grass.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grass.custom_aabb = AABB(Vector3(-106.0, -1.0, -82.0), Vector3(212.0, 12.0, 164.0))
	var transforms: Array[Transform3D] = []
	var attempts := 0
	while transforms.size() < requested_count and attempts < requested_count * 5:
		attempts += 1
		var x := rng.randf_range(-104.0, 104.0)
		var z := rng.randf_range(-80.0, 80.0)
		if absf(x) < 63.0 and absf(z) < 60.0:
			continue
		if _street_distance(x, z) < 5.8 or _plot_distance(x, z) < 3.0:
			continue
		var ground_y := _height_at(x, z, rolling, detail)
		var scale := rng.randf_range(0.72, 1.28)
		var rotation := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale, scale, scale))
		transforms.append(Transform3D(rotation, Vector3(x, ground_y + 0.015, z)))
	grass.multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		grass.multimesh.set_instance_transform(index, transforms[index])

static func _make_grass_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0, PI * 0.5, PI * 0.25]:
		var axis := Vector3(cos(angle), 0.0, sin(angle))
		var side := axis * 0.10
		var center := Vector3.ZERO
		var tip := Vector3(axis.x * 0.035, 0.54, axis.z * 0.035)
		tool.add_vertex(center - side)
		tool.add_vertex(center + side)
		tool.add_vertex(tip)
	tool.generate_normals()
	return tool.commit()

static func _add_building_plot_marks(parent: Node3D, rolling: FastNoiseLite, detail: FastNoiseLite) -> void:
	var outline_mesh := BoxMesh.new()
	outline_mesh.size = Vector3(1.0, 1.0, 1.0)
	var outlines := _new_multimesh(parent, "FutureHousePlotOutlines", outline_mesh, Color(0.63, 0.52, 0.33))
	var stakes := _new_multimesh(parent, "FutureHousePlotStakes", outline_mesh, Color(0.37, 0.26, 0.16))
	var outline_transforms: Array[Transform3D] = []
	var stake_transforms: Array[Transform3D] = []
	for plot in get_building_plots():
		var x: float = plot.position.x
		var z: float = plot.position.z
		var y := _height_at(x, z, rolling, detail)
		var width := PLOT_SIZE.x
		var depth := PLOT_SIZE.y
		for side in [-1.0, 1.0]:
			outline_transforms.append(_scaled_transform(Vector3(width, 0.035, 0.11), Vector3(x, y + 0.045, z + side * depth * 0.5)))
			outline_transforms.append(_scaled_transform(Vector3(0.11, 0.035, depth), Vector3(x + side * width * 0.5, y + 0.045, z)))
			for end in [-1.0, 1.0]:
				var corner := Vector3(x + side * width * 0.5, y + 0.33, z + end * depth * 0.5)
				stake_transforms.append(_scaled_transform(Vector3(0.09, 0.66, 0.09), corner))
	outlines.multimesh.instance_count = outline_transforms.size()
	for index in range(outline_transforms.size()):
		outlines.multimesh.set_instance_transform(index, outline_transforms[index])
	stakes.multimesh.instance_count = stake_transforms.size()
	for index in range(stake_transforms.size()):
		stakes.multimesh.set_instance_transform(index, stake_transforms[index])
	for instance in [outlines, stakes]:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.custom_aabb = AABB(Vector3(-65.0, -1.0, -62.0), Vector3(130.0, 5.0, 124.0))

static func _add_world_bounds(parent: StaticBody3D) -> void:
	var wall_height := 14.0
	var bounds := [
		{"pos": Vector3(-MAP_WIDTH * 0.5 - 0.5, 4.0, 0.0), "size": Vector3(1.0, wall_height, MAP_DEPTH)},
		{"pos": Vector3(MAP_WIDTH * 0.5 + 0.5, 4.0, 0.0), "size": Vector3(1.0, wall_height, MAP_DEPTH)},
		{"pos": Vector3(0.0, 4.0, -MAP_DEPTH * 0.5 - 0.5), "size": Vector3(MAP_WIDTH, wall_height, 1.0)},
		{"pos": Vector3(0.0, 4.0, MAP_DEPTH * 0.5 + 0.5), "size": Vector3(MAP_WIDTH, wall_height, 1.0)}
	]
	for bound in bounds:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = bound.size
		collision.shape = shape
		collision.position = bound.pos
		parent.add_child(collision)
