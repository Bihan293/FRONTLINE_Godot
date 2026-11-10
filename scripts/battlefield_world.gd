extends Node3D
class_name FRONTLINEBattlefieldWorld

## Построение мира: небо, солнце, земля, статическая геометрия и бочки.
## Боевая логика и HUD сюда не входят.

const DIGGABLE_GROUND_SCRIPT = preload("res://scripts/diggable_ground.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")
const VILLAGE_LAYOUT = preload("res://scripts/village_layout.gd")
const BARREL_SCRIPT = preload("res://scripts/explosive_barrel.gd")

var _mat_cache: Dictionary = {}
var _detail_texture: Texture2D
var _environment: Environment
var _merge_vertices := PackedVector3Array()
var _merge_normals := PackedVector3Array()
var _merge_colors := PackedColorArray()
var _merge_uvs := PackedVector2Array()
var _merge_indices := PackedInt32Array()

func _make_detail_texture() -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.55
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.80, 0.80, 0.80), Color(0.92, 0.92, 0.92), Color(1, 1, 1)])
	tex.color_ramp = ramp
	return tex


func material(color: Color, textured := true) -> StandardMaterial3D:
	var key: String = color.to_html() + ("_t" if textured else "")
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.94
	if textured:
		if _detail_texture == null:
			_detail_texture = _make_detail_texture()
		m.albedo_texture = _detail_texture
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.4, 0.4, 0.4)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mat_cache[key] = m
	return m


func build(layout: Script) -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.31, 0.55, 0.82)
	sky_mat.sky_horizon_color = Color(0.74, 0.82, 0.90)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.55, 0.63, 0.70)
	sky_mat.ground_horizon_color = Color(0.72, 0.80, 0.86)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.9
	environment.ambient_light_energy = 0.70

	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.00
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 1.12

	environment.fog_enabled = GameSettings.fog_enabled()
	environment.fog_light_color = Color(0.62, 0.70, 0.78)
	environment.fog_density = 0.0014
	environment.fog_aerial_perspective = 0.35

	env.environment = environment
	_environment = environment
	add_child(env)

	# Солнце
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_energy = 1.10
	sun.shadow_enabled = GameSettings.shadows_enabled()
	sun.directional_shadow_max_distance = GameSettings.shadow_distance()
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits = true
	add_child(sun)

	# Построение природной основы для новой сельской карты.
	var map_name := MatchState.map_name
	if map_name == "COUNTRYSIDE":
		COUNTRYSIDE_LAYOUT.add_world(self, true, true)
	elif map_name == "VILLAGE":
		VILLAGE_LAYOUT.add_tactical_assets(self, true)
	for box in layout.boxes():
		var kind := str(box.get("kind", ""))
		# CountrysideLayout batches its trees, buildings, furniture and street
		# props directly. Its boxes() list is only the bot-navigation obstacle set.
		if map_name == "COUNTRYSIDE":
			continue
		if map_name == "VILLAGE" and kind == "village_asset":
			continue
		if kind == "terrain" or kind == "ground":
			_build_diggable_ground(box)
		else:
			_build_box(box)
	# QA-optimization: слить все неотбрасывающие тень боксы в одну геометрию.
	_flush_merged_boxes()

	# Спавн взрывных тактических бочек с горючим
	for barrel_pos in layout.barrels():
		_spawn_barrel(barrel_pos)


func _spawn_barrel(pos: Vector3) -> void:
	var b := BARREL_SCRIPT.new()
	b.position = pos
	add_child(b)


func _build_box(data: Dictionary) -> void:
	var size: Vector3 = data.size
	var pos: Vector3 = data.pos
	var solid: bool = data.solid
	var kind: String = str(data.get("kind", ""))
	var textured: bool = kind not in ["pad_iron", "pad_red", "duckboard"]
	var parent: Node3D = self
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		add_child(body)
		parent = body
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material(data.color, textured)

	# Оптимизация теней для мобилок (экономия до 260 draw calls в shadow pass)
	const NO_SHADOW_KINDS := [
		"road", "crossroad", "plaza", "crater_dirt", "house_floor", "duckboard",
		"porch_deck", "porch_step", "window_frame", "shutter", "window_sill_board",
		"table", "chest", "altar", "pew", "trench_step", "picket_board", "hedge_beam"
	]
	var is_flat_or_micro: bool = kind in NO_SHADOW_KINDS or size.y <= 0.22 or (size.x < 0.35 and size.z < 0.35)
	var wants_shadow: bool = bool(data.get("cast_shadow", true)) and not is_flat_or_micro
	var shadow_caster: bool = wants_shadow and GameSettings.quality > 0
	if shadow_caster:
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		# QA-optimization: статичные коробки без теней складываем в один меш.
		# 195 боксов BATTLEFIELD / 373 VILLAGE = 1 draw call вместо сотен.
		_append_box_mesh(pos, size, data.color)
		return

	if not solid:
		inst.position = pos
	parent.add_child(inst)

## Складываем все статические боксы карты в один меш: ~87 draw call -> 1.

func _append_box_mesh(center: Vector3, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	var x0 := center.x - h.x
	var x1 := center.x + h.x
	var y0 := center.y - h.y
	var y1 := center.y + h.y
	var z0 := center.z - h.z
	var z1 := center.z + h.z
	_add_merge_quad(Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT, color)
	_add_merge_quad(Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3.RIGHT, color)
	_add_merge_quad(Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3.DOWN, color)
	_add_merge_quad(Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.UP, color)
	_add_merge_quad(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK, color)
	_add_merge_quad(Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3.FORWARD, color)


func _add_merge_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	var base := _merge_vertices.size()
	_merge_vertices.append_array([a, b, c, d])
	_merge_normals.append_array([normal, normal, normal, normal])
	_merge_colors.append_array([color, color, color, color])
	_merge_uvs.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	_merge_indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


func _flush_merged_boxes() -> void:
	if _merge_vertices.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _merge_vertices
	arrays[Mesh.ARRAY_NORMAL] = _merge_normals
	arrays[Mesh.ARRAY_COLOR] = _merge_colors
	arrays[Mesh.ARRAY_TEX_UV] = _merge_uvs
	arrays[Mesh.ARRAY_INDEX] = _merge_indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if GameSettings.quality > 0:
		if _detail_texture == null:
			_detail_texture = _make_detail_texture()
		material.albedo_texture = _detail_texture
		material.uv1_triplanar = true
		material.uv1_scale = Vector3(0.4, 0.4, 0.4)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var instance := MeshInstance3D.new()
	instance.name = "MergedMapGeometry"
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _build_diggable_ground(data: Dictionary) -> void:
	var size: Vector3 = data.size
	var ground = DIGGABLE_GROUND_SCRIPT.new()
	var height_sampler := Callable()
	if MatchState.map_name == "VILLAGE":
		height_sampler = Callable(VILLAGE_LAYOUT, "terrain_height_at")
	ground.configure(Vector2(size.x, size.z), 2.0, material(data.color, true), height_sampler)
	ground.position = data.pos + Vector3(0.0, size.y * 0.5, 0.0)
	add_child(ground)


