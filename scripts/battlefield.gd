extends Node3D

## Главный контроллер большой боевой карты (Battlefield: Trenches & No Man's Land).
## Управляет миром, секторами, умными ботами, волнами подкреплений и киллфидом.

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const BOT_SCRIPT = preload("res://scripts/soldier_bot.gd")
const LAYOUT = preload("res://scripts/battlefield_layout.gd")
const SFX_UI = preload("res://assets/audio/ui_click.ogg")
const COMPASS_SCRIPT = preload("res://scripts/compass_bar.gd")
const AMBIENCE_SCRIPT = preload("res://scripts/battlefield_ambience.gd")
const BARREL_SCRIPT = preload("res://scripts/explosive_barrel.gd")

var player: CharacterBody3D
var team_name := "IRON LEGION"
var score_iron := 60
var score_red := 60
var score_kills := 0

var hud: CanvasLayer
var score_label: Label
var killfeed_container: VBoxContainer
var sectors_container: HBoxContainer
var sector_indicators: Dictionary = {}
var sector_data: Array = []
var compass: FRONTLINECompassBar
var ambience: FRONTLINEAmbience
var victory_panel: PanelContainer
var is_game_over := false
var _ticket_bleed_timer := 4.0

var _mat_cache: Dictionary = {}
var _detail_texture: Texture2D
var _environment: Environment
var _active_bots: Array[FRONTLINESoldierBot] = []
var _bot_name_idx := 0

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
	ambience = AMBIENCE_SCRIPT.new()
	add_child(ambience)
	_build_world()
	_spawn_player()
	_build_sectors()
	_build_hud()
	_spawn_initial_squads()

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
	sky_mat.sky_top_color = Color(0.24, 0.38, 0.55)
	sky_mat.sky_horizon_color = Color(0.65, 0.70, 0.75)
	sky_mat.sky_curve = 0.16
	sky_mat.ground_bottom_color = Color(0.12, 0.14, 0.11)
	sky_mat.ground_horizon_color = Color(0.50, 0.55, 0.50)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.9
	environment.ambient_light_energy = 0.85

	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.92
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.10
	environment.adjustment_saturation = 1.15

	environment.fog_enabled = GameSettings.fog_enabled()
	environment.fog_light_color = Color(0.60, 0.66, 0.72)
	environment.fog_density = 0.0032
	environment.fog_aerial_perspective = 0.4

	env.environment = environment
	_environment = environment
	add_child(env)

	# Солнце
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 0.95
	sun.shadow_enabled = GameSettings.shadows_enabled()
	sun.directional_shadow_max_distance = GameSettings.shadow_distance()
	add_child(sun)

	# Построение блоков карты
	for box in LAYOUT.boxes():
		_build_box(box)

	# Спавн взрывных тактических бочек с горючим
	for barrel_pos in LAYOUT.barrels():
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
	inst.material_override = _mat(data.color, textured)
	if not solid:
		inst.position = pos
	parent.add_child(inst)

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	var default_spawn: Vector3 = LAYOUT.spawns_red()[0] if team_name.contains("RED") else LAYOUT.spawns_iron()[0]
	var spawn: Vector3 = get_tree().get_meta("spawn_position", default_spawn)
	player.position = spawn
	add_child(player)

func _build_sectors() -> void:
	sector_data = LAYOUT.sectors()
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

## Создание стартовых отрядов ботов (по 7 бойцов с каждой стороны)
func _spawn_initial_squads() -> void:
	var iron_spawns := LAYOUT.spawns_iron()
	for i in range(7):
		var sp := iron_spawns[i % iron_spawns.size()] + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
		var name := GERMAN_NAMES[i % GERMAN_NAMES.size()]
		_create_bot(sp, "IRON LEGION", name)

	var red_spawns := LAYOUT.spawns_red()
	for i in range(7):
		var sp := red_spawns[i % red_spawns.size()] + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
		var name := SOVIET_NAMES[i % SOVIET_NAMES.size()]
		_create_bot(sp, "RED FRONT", name)

func _create_bot(pos: Vector3, team: String, bot_name: String) -> FRONTLINESoldierBot:
	var bot := CharacterBody3D.new()
	bot.set_script(BOT_SCRIPT)
	bot.position = pos
	bot.team_name = team
	bot.soldier_name = bot_name
	bot.soldier_killed.connect(_on_soldier_killed)
	bot.soldier_fired.connect(_on_bot_fired)
	add_child(bot)
	_active_bots.append(bot)
	return bot

func _on_bot_fired(pos: Vector3) -> void:
	if compass != null:
		compass.add_gunfire_ping(pos)

func _on_soldier_killed(victim: FRONTLINESoldierBot, killer_name: String, weapon_name: String) -> void:
	# Списание билетов
	if victim.team_name.contains("RED"):
		score_red = maxi(0, score_red - 1)
	else:
		score_iron = maxi(0, score_iron - 1)

	_refresh_score()

	# Добавление в киллфид
	_add_killfeed_entry(killer_name, victim.soldier_name, victim.team_name)

	# Запуск подкрепления через 7 секунд
	var v_team := victim.team_name
	get_tree().create_timer(7.0).timeout.connect(func():
		if is_instance_valid(self):
			_spawn_reinforcement(v_team)
	)

func _spawn_reinforcement(team: String) -> void:
	var spawns := LAYOUT.spawns_red() if team.contains("RED") else LAYOUT.spawns_iron()
	var sp := spawns[randi() % spawns.size()] + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
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

	# Киллфид в правом верхнем углу
	killfeed_container = VBoxContainer.new()
	killfeed_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	killfeed_container.offset_left = -340
	killfeed_container.offset_right = -20
	killfeed_container.offset_top = 80
	killfeed_container.offset_bottom = 260
	killfeed_container.add_theme_constant_override("separation", 6)
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

	# Кнопка меню
	var menu_btn := Button.new()
	menu_btn.text = "МЕНЮ"
	menu_btn.offset_left = 28
	menu_btn.offset_top = 70
	menu_btn.offset_right = 115
	menu_btn.offset_bottom = 112
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	hud.add_child(menu_btn)

	_refresh_score()

func _refresh_score() -> void:
	if score_label != null:
		score_label.text = "IRON LEGION: %d   ⚔   RED FRONT: %d" % [score_iron, score_red]

func _add_killfeed_entry(killer: String, victim: String, victim_team: String) -> void:
	if killfeed_container == null:
		return
	var entry := Label.new()
	entry.text = "%s  ︻╦╤─  %s" % [killer, victim]
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry.add_theme_font_size_override("font_size", 15)
	var color := Color(1.0, 0.45, 0.40) if victim_team.contains("RED") else Color(0.55, 0.75, 1.0)
	entry.add_theme_color_override("font_color", color)
	entry.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	entry.add_theme_constant_override("shadow_offset_x", 1)
	entry.add_theme_constant_override("shadow_offset_y", 1)
	killfeed_container.add_child(entry)

	# Удаление записи через 4.5 секунды
	get_tree().create_timer(4.5).timeout.connect(func():
		if is_instance_valid(entry):
			entry.queue_free()
	)

func _process(delta: float) -> void:
	if is_game_over:
		return
	_update_sector_captures()
	_update_ticket_bleed(delta)

func _update_ticket_bleed(delta: float) -> void:
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

	var is_player_winner: bool = (team_name == winner)

	victory_panel = PanelContainer.new()
	victory_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	victory_panel.offset_left = -280
	victory_panel.offset_right = 280
	victory_panel.offset_top = -180
	victory_panel.offset_bottom = 180
	hud.add_child(victory_panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
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
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vb.add_child(sub)

	var stats := Label.new()
	stats.text = "Победитель: %s\nИтоговый счёт: %d : %d   •   Ваши фраги: %d" % [winner, score_iron, score_red, score_kills]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 16)
	stats.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
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
		get_tree().reload_current_scene()
	)
	btn_box.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "ГЛАВНОЕ МЕНЮ"
	menu_btn.custom_minimum_size = Vector2(160, 48)
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_box.add_child(menu_btn)

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
