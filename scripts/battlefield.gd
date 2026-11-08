extends Node3D

## Главный контроллер большой боевой карты (Battlefield: Trenches & No Man's Land).
## Управляет миром, секторами, умными ботами, волнами подкреплений и киллфидом.

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const BOT_SCRIPT = preload("res://scripts/soldier_bot.gd")
const BATTLEFIELD_LAYOUT = preload("res://scripts/battlefield_layout.gd")
const VILLAGE_LAYOUT = preload("res://scripts/village_layout.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")
const SFX_UI = preload("res://assets/audio/ui_click.ogg")
const COMPASS_SCRIPT = preload("res://scripts/compass_bar.gd")
const AMBIENCE_SCRIPT = preload("res://scripts/battlefield_ambience.gd")
const BARREL_SCRIPT = preload("res://scripts/explosive_barrel.gd")
const MINIMAP_SCRIPT = preload("res://scripts/minimap.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const DIGGABLE_GROUND_SCRIPT = preload("res://scripts/diggable_ground.gd")
const TURRET_SCRIPT = preload("res://scripts/static_turret.gd")
const JEEP_SCRIPT = preload("res://scripts/jeep.gd")
const TACTICAL_DEPLOY_SCRIPT = preload("res://scripts/tactical_deploy.gd")

const TDM_TARGET_KILLS := 50
const MAX_ACTIVE_BULLETS := 192

var player: CharacterBody3D
var team_name := "IRON LEGION"
var game_mode := "CONQUEST"
var score_iron := 60
var score_red := 60
var score_kills := 0
var match_elapsed_time := 0.0
var player_deaths := 0
var player_damage := 0
var player_captures := 0

func record_player_death() -> void:
	player_deaths += 1

func record_player_damage(amount: int) -> void:
	if amount > 0:
		player_damage += amount

func _layout():
	var map_name: String = str(get_tree().get_meta("selected_map", "BATTLEFIELD"))
	if map_name == "VILLAGE":
		return VILLAGE_LAYOUT
	if map_name == "COUNTRYSIDE":
		return COUNTRYSIDE_LAYOUT
	return BATTLEFIELD_LAYOUT

var hud: CanvasLayer
var score_label: Label
var killfeed_container: VBoxContainer
var sectors_container: HBoxContainer
var sector_indicators: Dictionary = {}
var sector_data: Array = []
var compass: FRONTLINECompassBar
var ambience: FRONTLINEAmbience
var minimap: FRONTLINEMinimap
var victory_panel: PanelContainer
var is_game_over := false
var _ticket_bleed_timer := 4.0

var _mat_cache: Dictionary = {}
var _detail_texture: Texture2D
var _environment: Environment
var _active_bots: Array[FRONTLINESoldierBot] = []
var _bot_name_idx := 0
var _merge_vertices := PackedVector3Array()
var _merge_normals := PackedVector3Array()
var _merge_colors := PackedColorArray()
var _merge_uvs := PackedVector2Array()
var _merge_indices := PackedInt32Array()

const SOVIET_NAMES := [
	"Ряд. Морозов", "С-нт Васильев", "Ряд. Смирнов", "Ряд. Ковалёв",
	"Ряд. Попов", "Ефр. Новиков", "Ряд. Фёдоров", "С-нт Соколов",
	"Ряд. Михайлов", "Ряд. Лебедев", "Ряд. Кузнецов", "Ряд. Павлов"
]

const GERMAN_NAMES := [
	"Gfr. Weber", "Uffz. Schmidt", "Pte. Richter", "Pte. Wagner",
	"Gfr. Becker", "Pte. Hoffmann", "Uffz. Schulz", "Pte. Koch",
	"Pte. Bauer", "Gfr. Klein", "Pte. Wolf", "Pte. Neumann"
]

func _ready() -> void:
	team_name = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	game_mode = str(get_tree().get_meta("selected_mode", "CONQUEST"))
	if game_mode == "TDM":
		score_iron = 0
		score_red = 0
	else:
		score_iron = 60
		score_red = 60
	ambience = AMBIENCE_SCRIPT.new()
	add_child(ambience)
	_build_world()
	_spawn_supply_caches()
	_spawn_vehicles()
	_spawn_player()
	_build_sectors()
	_build_hud()
	_spawn_initial_squads()
	if bool(get_tree().get_meta("open_tactical_deploy_at_start", false)):
		get_tree().set_meta("open_tactical_deploy_at_start", false)
		get_tree().set_meta("deploy_intro", false)
		open_tactical_deploy()
	elif bool(get_tree().get_meta("deploy_intro", false)):
		_play_deploy_intro()
	elif not OS.has_feature("dedicated_server") and not bool(get_tree().get_meta("skip_deploy_screen", false)) and DisplayServer.get_name() != "headless":
		open_tactical_deploy()

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

func _mat(color: Color, textured := true) -> StandardMaterial3D:
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

func _build_world() -> void:
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
	var layout = _layout()
	var map_name := str(get_tree().get_meta("selected_map", "BATTLEFIELD"))
	if map_name == "COUNTRYSIDE":
		COUNTRYSIDE_LAYOUT.add_world(self, true, true)
	for box in layout.boxes():
		var kind := str(box.get("kind", ""))
		if map_name == "COUNTRYSIDE" and kind == "tree_obstacle":
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

func _spawn_supply_caches() -> void:
	var positions: Array[Vector3]
	var map_name := str(get_tree().get_meta("selected_map", "BATTLEFIELD"))
	if map_name == "COUNTRYSIDE":
		return
	if map_name == "VILLAGE":
		positions = [
			Vector3(-35.0, 0.18, -40.0), Vector3(35.0, 0.18, -40.0),
			Vector3(-35.0, 0.18, 40.0), Vector3(35.0, 0.18, 40.0),
		]
	else:
		positions = [
			Vector3(-72.0, 0.18, 0.0), Vector3(72.0, 0.18, 0.0),
			Vector3(0.0, 0.18, -50.0), Vector3(0.0, 0.18, 50.0),
		]
	for pos in positions:
		var cache = FIELD_PICKUP_SCRIPT.new()
		cache.configure_ammo(48, 65.0)
		cache.position = pos
		add_child(cache)

func _spawn_vehicles() -> void:
	# Задача TASK-0012: стационарные пулемёты по флангам секторов и
	# джип у баз. На дебаг-полигоне техника не создаём.
	var map := str(get_tree().get_meta("selected_map", "BATTLEFIELD"))
	if map == "POLYGON" or map == "COUNTRYSIDE":
		return
	var turrets: Array[Dictionary] = [
		{"pos": Vector3(-64.0, 0.05, 12.0), "toward": Vector3(-40.0, 0.0, 0.0)},
		{"pos": Vector3(-64.0, 0.05, -12.0), "toward": Vector3(-40.0, 0.0, 0.0)},
		{"pos": Vector3(64.0, 0.05, 12.0), "toward": Vector3(40.0, 0.0, 0.0)},
		{"pos": Vector3(64.0, 0.05, -12.0), "toward": Vector3(40.0, 0.0, 0.0)},
	]
	if map == "VILLAGE":
		turrets = [
			{"pos": Vector3(-34.0, 0.05, 6.0), "toward": Vector3(0.0, 0.0, 0.0)},
			{"pos": Vector3(34.0, 0.05, -6.0), "toward": Vector3(0.0, 0.0, 0.0)},
			{"pos": Vector3(0.0, 0.05, 34.0), "toward": Vector3(0.0, 0.0, 0.0)},
		]
	for point in turrets:
		var turret = TURRET_SCRIPT.new()
		add_child(turret)
		var pos: Vector3 = point["pos"]
		turret.global_position = pos
		var td: Vector3 = point["toward"] - pos
		turret.rotation.y = atan2(-td.x, -td.z)
	# Оптимизация отдачи (TASK-0019): два джипа — по одному на базу,
	# чтобы не удваивать draw calls Второго шага меша Antigravity.
	var jeeps: Array[Dictionary] = [
		{"pos": Vector3(-16.0, 0.25, 70.0), "toward": Vector3(0.0, 0.0, 0.0), "team": "IRON LEGION"},
		{"pos": Vector3(16.0, 0.25, -70.0), "toward": Vector3(0.0, 0.0, 0.0), "team": "RED FRONT"},
	]
	if map == "VILLAGE":
		jeeps = [
			{"pos": Vector3(-30.0, 0.25, -42.0), "toward": Vector3(0.0, 0.0, 0.0), "team": "RED FRONT"},
			{"pos": Vector3(30.0, 0.25, 42.0), "toward": Vector3(0.0, 0.0, 0.0), "team": "IRON LEGION"},
		]
	for point in jeeps:
		var jeep = JEEP_SCRIPT.new()
		add_child(jeep)
		var jpos: Vector3 = point["pos"]
		jpos.y = 0.25
		jeep.global_position = jpos
		var jd: Vector3 = point["toward"] - jpos
		jeep.rotation.y = atan2(-jd.x, -jd.z)
		jeep.team_name = str(point["team"])

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
	inst.material_override = _mat(data.color, textured)

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
	ground.configure(Vector2(size.x, size.z), 2.0, _mat(data.color, true))
	ground.position = data.pos + Vector3(0.0, size.y * 0.5, 0.0)
	add_child(ground)

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	var default_spawn: Vector3 = _layout().spawns_red()[0] if team_name.contains("RED") else _layout().spawns_iron()[0]
	var spawn: Vector3 = get_tree().get_meta("spawn_position", default_spawn)
	player.position = spawn
	add_child(player)

## Кинематографичный спуск камеры с верху карты к выбранной точке спавна.
func _play_deploy_intro() -> void:
	get_tree().set_meta("deploy_intro", false)
	if player == null or not is_instance_valid(player):
		return
	var player_camera := player.get("camera") as Camera3D
	if player_camera == null:
		return
	player.call("set_input_locked", true)
	var player_hud = player.get("hud")
	if player_hud is CanvasLayer:
		(player_hud as CanvasLayer).visible = false

	var spawn := player.global_position
	var intro := Camera3D.new()
	intro.fov = 62.0
	intro.far = 500.0
	add_child(intro)
	intro.look_at_from_position(spawn + Vector3(0.0, 46.0, 34.0), spawn + Vector3(0.0, 0.0, -6.0), Vector3.UP)
	intro.current = true
	var final_pos := player_camera.global_position
	var final_rot := player_camera.global_rotation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(intro, "global_position", final_pos, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(intro, "global_rotation", final_rot, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func():
		if is_instance_valid(intro):
			intro.queue_free()
		if is_instance_valid(player):
			var pc := player.get("camera") as Camera3D
			if pc != null:
				pc.current = true
			player.call("set_input_locked", false)
		if player_hud is CanvasLayer:
			(player_hud as CanvasLayer).visible = true
	)

## Открывает интерактивный тактический вид сверху карты для выбора точки деплоя и класса.
func open_tactical_deploy() -> void:
	if player == null or not is_instance_valid(player):
		return
	var player_camera := player.get("camera") as Camera3D
	if player_camera == null:
		return

	player.call("set_input_locked", true)
	var player_hud = player.get("hud")
	if player_hud is CanvasLayer:
		(player_hud as CanvasLayer).visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Создаем тактическую камеру с видом сверху на поле боя
	var overhead_cam := Camera3D.new()
	overhead_cam.name = "TacticalOverheadCamera"
	overhead_cam.fov = 65.0
	overhead_cam.far = 600.0
	add_child(overhead_cam)

	var center_look := Vector3(0.0, 0.0, -10.0)
	var cam_pos := Vector3(0.0, 52.0, 38.0)
	if team_name.contains("RED"):
		cam_pos = Vector3(0.0, 52.0, -38.0)
		center_look = Vector3(0.0, 0.0, 10.0)
	overhead_cam.look_at_from_position(cam_pos, center_look, Vector3.UP)
	overhead_cam.current = true

	# Создаем тактический интерфейс спавна и выбора экипировки
	var deploy_ui = TACTICAL_DEPLOY_SCRIPT.new()
	add_child(deploy_ui)
	var base_spawns: Array = _layout().spawns_red() if team_name.contains("RED") else _layout().spawns_iron()
	deploy_ui.setup(team_name, sector_data, base_spawns)

	deploy_ui.deployed.connect(func(spawn_pos: Vector3, role_name: String, primary_idx: int):
		_on_player_tactical_deployed(spawn_pos, role_name, primary_idx, overhead_cam)
	)

func _on_player_tactical_deployed(spawn_pos: Vector3, role_name: String, primary_idx: int, overhead_cam: Camera3D) -> void:
	if player == null or not is_instance_valid(player):
		if is_instance_valid(overhead_cam):
			overhead_cam.queue_free()
		return

	player.set("player_role", role_name)
	player.set("respawn_position", spawn_pos)
	player.set("current_weapon_index", primary_idx)
	if player.get("is_dead"):
		player.call("respawn")
	else:
		player.global_position = spawn_pos
		player.call("respawn")

	var player_camera := player.get("camera") as Camera3D
	if player_camera == null or not is_instance_valid(overhead_cam):
		if is_instance_valid(overhead_cam):
			overhead_cam.queue_free()
		player.call("set_input_locked", false)
		if not OS.has_feature("mobile"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# Плавная кинематографичная анимация спуска камеры в бой к телу бойца (1.7 секунды)
	var final_pos := player_camera.global_position
	var final_rot := player_camera.global_rotation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overhead_cam, "global_position", final_pos, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(overhead_cam, "global_rotation", final_rot, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func():
		if is_instance_valid(overhead_cam):
			overhead_cam.queue_free()
		if is_instance_valid(player):
			var pc := player.get("camera") as Camera3D
			if pc != null:
				pc.current = true
			player.call("set_input_locked", false)
			var ph = player.get("hud")
			if ph is CanvasLayer:
				(ph as CanvasLayer).visible = true
			if not OS.has_feature("mobile"):
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

func _build_sectors() -> void:
	sector_data = _layout().sectors()
	for sec in sector_data:
		var pos: Vector3 = sec.pos
		var pole := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.10
		cyl.bottom_radius = 0.10
		cyl.height = 7.0
		pole.mesh = cyl
		pole.position = pos + Vector3(0, 3.5, 0)
		pole.material_override = _mat(Color(0.2, 0.2, 0.2), false)
		add_child(pole)

		var flag := MeshInstance3D.new()
		var flag_mesh := BoxMesh.new()
		flag_mesh.size = Vector3(1.8, 1.1, 0.05)
		flag.mesh = flag_mesh
		flag.position = pos + Vector3(0.9, 6.2, 0)
		flag.name = "Flag_" + str(sec.name)
		flag.material_override = _mat(Color(0.7, 0.7, 0.7), false)
		add_child(flag)

## Создание стартовых отрядов ботов (по squad_size бойцов с каждой стороны)
func _spawn_initial_squads() -> void:
	var squad_size: int = clampi(int(get_tree().get_meta("match_squad_size", 7)), 7, 14)
	var iron_spawns: Array = _layout().spawns_iron()
	for i in range(squad_size):
		var sp: Vector3 = iron_spawns[i % iron_spawns.size()] + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
		var name_str: String = GERMAN_NAMES[i % GERMAN_NAMES.size()]
		_create_bot(sp, "IRON LEGION", name_str)

	var red_spawns: Array = _layout().spawns_red()
	for i in range(squad_size):
		var sp: Vector3 = red_spawns[i % red_spawns.size()] + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
		var name_str: String = SOVIET_NAMES[i % SOVIET_NAMES.size()]
		_create_bot(sp, "RED FRONT", name_str)

func _create_bot(pos: Vector3, team: String, bot_name: String) -> FRONTLINESoldierBot:
	var bot := CharacterBody3D.new()
	bot.set_script(BOT_SCRIPT)
	bot.position = pos
	bot.team_name = team
	bot.soldier_name = bot_name
	bot.soldier_killed.connect(_on_soldier_killed)
	bot.soldier_fired.connect(_on_bot_fired)
	bot.tree_exiting.connect(func():
		_active_bots.erase(bot)
	)
	add_child(bot)
	_active_bots.append(bot)
	return bot

func _on_bot_fired(pos: Vector3) -> void:
	if compass != null:
		compass.add_gunfire_ping(pos)

func _on_soldier_killed(victim: FRONTLINESoldierBot, killer_name: String, weapon_name: String) -> void:
	if game_mode == "TDM":
		if victim.team_name.contains("RED"):
			score_iron += 1
		else:
			score_red += 1
		_refresh_score()
		if score_iron >= TDM_TARGET_KILLS:
			_end_match("IRON LEGION")
		elif score_red >= TDM_TARGET_KILLS:
			_end_match("RED FRONT")
	else:
		# Списание билетов в Conquest
		if victim.team_name.contains("RED"):
			score_red = maxi(0, score_red - 1)
		else:
			score_iron = maxi(0, score_iron - 1)
		_refresh_score()
		if score_red <= 0:
			_end_match("IRON LEGION")
		elif score_iron <= 0:
			_end_match("RED FRONT")

	# Добавление в киллфид
	_add_killfeed_entry(killer_name, victim.soldier_name, victim.team_name)

	# Запуск подкрепления через 7 секунд
	var v_team := victim.team_name
	get_tree().create_timer(7.0, false).timeout.connect(func():
		if is_instance_valid(self):
			_spawn_reinforcement(v_team)
	)

func spawn_weapon_pickup(pos: Vector3, index: int, clip: int, reserve: int, initial_velocity: Vector3 = Vector3.ZERO) -> void:
	var active_pickups := get_tree().get_nodes_in_group("field_weapon_pickups")
	if active_pickups.size() >= 16:
		for p in active_pickups:
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()
				break
	var pickup = FIELD_PICKUP_SCRIPT.new()
	pickup.configure_weapon(index, clip, reserve)
	add_child(pickup)
	pickup.global_position = pos
	var velocity := initial_velocity
	if velocity.is_zero_approx():
		velocity = Vector3(randf_range(-0.8, 0.8), 1.1, randf_range(-0.8, 0.8))
	pickup.launch(velocity)

var _active_bullets := 0
var _sector_timer := 0.0

func _on_bullet_exited() -> void:
	_active_bullets = maxi(0, _active_bullets - 1)

func spawn_bullet_projectile(start_pos: Vector3, direction: Vector3, speed: float, damage: int, range_m: float, owner_name: String, owner_team: String, owner: Node, damage_to_player := 0) -> bool:
	if is_game_over:
		return false
	# QA-optimization: счётчик вместо скана группы из ~200 нод на каждый выстрел.
	var cap := 96 if GameSettings.quality == 0 else MAX_ACTIVE_BULLETS
	if _active_bullets >= cap:
		return false
	var bullet = BULLET_PROJECTILE_SCRIPT.new()
	# QA-sweep: configure() выставляет global_position — только после add_child,
	# иначе каждый выстрел пишет ERROR "!is_inside_tree()".
	bullet.tree_exited.connect(_on_bullet_exited)
	add_child(bullet)
	_active_bullets += 1
	bullet.configure(start_pos, direction, speed, damage, range_m, owner_name, owner_team, owner, damage_to_player)
	return true

func _spawn_reinforcement(team: String) -> void:
	var spawns: Array = _layout().spawns_red() if team.contains("RED") else _layout().spawns_iron()
	var sp: Vector3 = spawns[randi() % spawns.size()] + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
	var names_arr := SOVIET_NAMES if team.contains("RED") else GERMAN_NAMES
	_bot_name_idx += 1
	var name_str: String = names_arr[_bot_name_idx % names_arr.size()]
	_create_bot(sp, team, name_str)

func add_kill() -> void:
	score_kills += 1

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)

	# Верхняя панель счета и секторов
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 320
	top_panel.offset_right = -320
	top_panel.offset_top = 16
	top_panel.offset_bottom = 68
	hud.add_child(top_panel)

	var top_box := HBoxContainer.new()
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_box.add_theme_constant_override("separation", 28)
	top_panel.add_child(top_box)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(score_label)

	sectors_container = HBoxContainer.new()
	sectors_container.add_theme_constant_override("separation", 14)
	top_box.add_child(sectors_container)

	for sec in sector_data:
		var lbl := Label.new()
		lbl.text = "[ %s ]" % sec.name
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		sectors_container.add_child(lbl)
		sector_indicators[sec.name] = lbl

	# Киллфид в левой части под миникартой (не перекрывает верхние сенсорные кнопки на мобильных)
	killfeed_container = VBoxContainer.new()
	killfeed_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	killfeed_container.offset_left = 24
	killfeed_container.offset_right = 340
	killfeed_container.offset_top = 320
	killfeed_container.offset_bottom = 470
	killfeed_container.add_theme_constant_override("separation", 4)
	hud.add_child(killfeed_container)

	# Тактический компас
	compass = COMPASS_SCRIPT.new()
	compass.anchor_left = 0.5
	compass.anchor_right = 0.5
	compass.offset_left = -190.0
	compass.offset_right = 190.0
	compass.offset_top = 74.0
	compass.offset_bottom = 110.0
	hud.add_child(compass)
	if player != null and player.camera != null:
		compass.setup(player.camera, sector_data)

	# Круговая мини-карта под здоровьем, слева
	minimap = MINIMAP_SCRIPT.new()
	minimap.offset_left = 24.0
	minimap.offset_top = 124.0
	minimap.offset_right = 212.0
	minimap.offset_bottom = 312.0
	hud.add_child(minimap)
	minimap.setup(player, _active_bots, sector_data, _layout().spawns_iron(), _layout().spawns_red())

	_refresh_score()

func _refresh_score() -> void:
	if score_label != null:
		if game_mode == "TDM":
			score_label.text = "TDM (ДО 50)  •  IRON LEGION: %d   ⚔   RED FRONT: %d" % [score_iron, score_red]
		else:
			score_label.text = "IRON LEGION: %d   ⚔   RED FRONT: %d" % [score_iron, score_red]

func _add_killfeed_entry(killer: String, victim: String, victim_team: String) -> void:
	if killfeed_container == null:
		return
	var entry := Label.new()
	entry.text = "%s  ︻╦╤─  %s" % [killer, victim]
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.add_theme_font_size_override("font_size", 14)
	var color := Color(1.0, 0.45, 0.40) if victim_team.contains("RED") else Color(0.55, 0.75, 1.0)
	entry.add_theme_color_override("font_color", color)
	entry.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	entry.add_theme_constant_override("shadow_offset_x", 1)
	entry.add_theme_constant_override("shadow_offset_y", 1)
	killfeed_container.add_child(entry)

	# Удаление записи через 4.5 секунды
	get_tree().create_timer(4.5, false).timeout.connect(func():
		if is_instance_valid(entry):
			entry.queue_free()
	)

func _process(delta: float) -> void:
	if is_game_over:
		return
	match_elapsed_time += delta
	# QA-optimization: владение сектором не меняется быстрее 4 Гц.
	_sector_timer -= delta
	if _sector_timer <= 0.0:
		_sector_timer = 0.25
		_update_sector_captures()
	_update_ticket_bleed(delta)

func _update_ticket_bleed(delta: float) -> void:
	if game_mode == "TDM":
		return
	_ticket_bleed_timer -= delta
	if _ticket_bleed_timer > 0.0:
		return
	_ticket_bleed_timer = 4.0

	var iron_sec := 0
	var red_sec := 0
	for sec in sector_data:
		if sec.owner == "IRON LEGION":
			iron_sec += 1
		elif sec.owner == "RED FRONT":
			red_sec += 1

	if iron_sec > red_sec:
		score_red = maxi(0, score_red - (iron_sec - red_sec))
	elif red_sec > iron_sec:
		score_iron = maxi(0, score_iron - (red_sec - iron_sec))

	_refresh_score()

	if score_red <= 0:
		_end_match("IRON LEGION")
	elif score_iron <= 0:
		_end_match("RED FRONT")

func _end_match(winner: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", true)
	for bot in get_tree().get_nodes_in_group("bots"):
		if is_instance_valid(bot):
			bot.set_physics_process(false)
			bot.set_process(false)

	var is_player_winner: bool = (team_name == winner)

	victory_panel = PanelContainer.new()
	victory_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	victory_panel.offset_left = -320
	victory_panel.offset_right = 320
	victory_panel.offset_top = -220
	victory_panel.offset_bottom = 220
	hud.add_child(victory_panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	victory_panel.add_child(vb)

	var title := Label.new()
	title.text = "★ ПОБЕДА! ★" if is_player_winner else "ПОРАЖЕНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	var title_col := Color(0.95, 0.82, 0.25) if is_player_winner else Color(0.92, 0.28, 0.22)
	title.add_theme_color_override("font_color", title_col)
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "СЕКТОРЫ ПОД КОНТРОЛЕМ" if is_player_winner else "СИЛЫ ФРОНТА ИСЧЕРПАНЫ"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vb.add_child(sub)

	var mins := int(match_elapsed_time) / 60
	var secs := int(match_elapsed_time) % 60
	var kd_ratio: float = float(score_kills) if player_deaths == 0 else (float(score_kills) / float(player_deaths))
	var map_name := str(get_tree().get_meta("selected_map", "BATTLEFIELD"))

	var stats := Label.new()
	stats.text = "КАРТА: %s   •   РЕЖИМ: %s   •   ВРЕМЯ: %02d:%02d\nСЧЁТ: ЖЕЛЕЗНЫЙ ЛЕГИОН %d : %d КРАСНАЯ ЗВЕЗДА\n\nБОЕВОЙ ОТЧЁТ ИГРОКА:\nФраги: %d   •   Смерти: %d   •   K/D: %.2f\nЗахват секторов: %d   •   Нанесённый урон: %d" % [
		map_name, game_mode, mins, secs,
		score_iron, score_red,
		score_kills, player_deaths, kd_ratio,
		player_captures, player_damage
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	vb.add_child(stats)

	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 24)
	vb.add_child(btn_box)

	var restart_btn := Button.new()
	restart_btn.text = "ПЕРЕИГРАТЬ"
	restart_btn.custom_minimum_size = Vector2(140, 48)
	restart_btn.add_theme_font_size_override("font_size", 16)
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	btn_box.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "ГЛАВНОЕ МЕНЮ"
	menu_btn.custom_minimum_size = Vector2(160, 48)
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_box.add_child(menu_btn)
	get_tree().paused = true

func _update_sector_captures() -> void:
	for sec in sector_data:
		var sec_pos: Vector3 = sec.pos
		var radius: float = sec.radius
		var iron_count := 0
		var red_count := 0

		# Подсчет присутствующих бойцов в секторе
		if player != null and is_instance_valid(player) and not player.is_dead:
			if player.global_position.distance_to(sec_pos) <= radius:
				if team_name.contains("RED"):
					red_count += 1
				else:
					iron_count += 1

		for bot in _active_bots:
			if bot != null and is_instance_valid(bot) and not bot.is_dead:
				if bot.global_position.distance_to(sec_pos) <= radius:
					if bot.team_name.contains("RED"):
						red_count += 1
					else:
						iron_count += 1

		# Определение владельца
		var prev_owner: String = str(sec.owner)
		if iron_count > red_count:
			sec.owner = "IRON LEGION"
		elif red_count > iron_count:
			sec.owner = "RED FRONT"

		if sec.owner != prev_owner:
			_update_sector_visual(sec)
			if player != null and is_instance_valid(player) and not player.is_dead:
				if player.global_position.distance_to(sec_pos) <= radius and sec.owner == team_name:
					player_captures += 1

func _update_sector_visual(sec: Dictionary) -> void:
	var flag = find_child("Flag_" + str(sec.name), true, false) as MeshInstance3D
	var lbl: Label = sector_indicators.get(sec.name, null)
	var flag_color := Color(0.7, 0.7, 0.7)
	if sec.owner == "IRON LEGION":
		flag_color = Color(0.25, 0.45, 0.85)
	elif sec.owner == "RED FRONT":
		flag_color = Color(0.85, 0.22, 0.18)

	if flag != null:
		flag.material_override = _mat(flag_color, false)
	if lbl != null:
		lbl.add_theme_color_override("font_color", flag_color)
