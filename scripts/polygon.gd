extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const DUMMY_SCRIPT = preload("res://scripts/dummy.gd")
const LAYOUT = preload("res://scripts/map_layout.gd")
const SFX_UI = preload("res://assets/audio/ui_click.ogg")

var player: CharacterBody3D
var score_kills := 0
var score_deaths := 0
var team_name := "IRON LEGION"
var hud: CanvasLayer
var scoreboard: PanelContainer
var stats_label: Label
var ui_click: AudioStreamPlayer
var _mat_cache: Dictionary = {}
var _detail_texture: Texture2D
var _environment: Environment

func _ready() -> void:
    team_name = str(get_tree().get_meta("selected_team", "IRON LEGION"))
    _build_world()
    _spawn_player()
    _build_hud()

func _make_detail_texture() -> Texture2D:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.06
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
        Color(0.82, 0.82, 0.82), Color(0.93, 0.93, 0.93), Color(1, 1, 1)])
    tex.color_ramp = ramp
    return tex

func _mat(color: Color, textured := false) -> StandardMaterial3D:
    var key: String = color.to_html() + ("_t" if textured else "")
    if _mat_cache.has(key):
        return _mat_cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.96
    if textured:
        if _detail_texture == null:
            _detail_texture = _make_detail_texture()
        m.albedo_texture = _detail_texture
        m.uv1_triplanar = true
        m.uv1_scale = Vector3(0.55, 0.55, 0.55)
        m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _mat_cache[key] = m
    return m

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()

    # Небо с градиентом вместо плоской заливки: даёт мягкий ambient и глубину.
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.20, 0.36, 0.60)
    sky_mat.sky_horizon_color = Color(0.68, 0.76, 0.82)
    sky_mat.sky_curve = 0.15
    sky_mat.ground_bottom_color = Color(0.10, 0.12, 0.10)
    sky_mat.ground_horizon_color = Color(0.55, 0.60, 0.55)
    sky_mat.sun_angle_max = 1.5
    sky_mat.sun_curve = 0.04
    var sky := Sky.new()
    sky.sky_material = sky_mat
    environment.background_mode = Environment.BG_SKY
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_sky_contribution = 1.0
    environment.ambient_light_energy = 0.82

    # Кинематографичный тонмаппинг и лёгкая цветокоррекция.
    environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    environment.tonemap_exposure = 0.90
    environment.tonemap_white = 6.0
    environment.adjustment_enabled = true
    environment.adjustment_brightness = 1.0
    environment.adjustment_contrast = 1.08
    environment.adjustment_saturation = 1.16

    # Дальняя дымка смягчает полигон и скрывает границу карты.
    environment.fog_enabled = GameSettings.fog_enabled()
    environment.fog_light_color = Color(0.62, 0.70, 0.76)
    environment.fog_light_energy = 0.9
    environment.fog_density = 0.0045
    environment.fog_sky_affect = 0.25
    environment.fog_aerial_perspective = 0.35

    env.environment = environment
    _environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_color = Color(1.0, 0.94, 0.84)
    sun.light_energy = 0.98
    sun.shadow_enabled = GameSettings.shadows_enabled()
    sun.directional_shadow_max_distance = GameSettings.shadow_distance()
    sun.shadow_bias = 0.035
    sun.shadow_normal_bias = 1.2
    add_child(sun)

    # Холодный заполняющий свет, чтобы теневые стороны не были чёрными.
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25, 148, 0)
    fill.light_color = Color(0.62, 0.72, 0.88)
    fill.light_energy = 0.22 if GameSettings.quality > 0 else 0.16
    fill.shadow_enabled = false
    add_child(fill)

    for box in LAYOUT.boxes():
        _build_box(box)

    for board in LAYOUT.target_boards():
        _build_target_center(board)

    _spawn_dummies()

    # Простые деревянные сиденья под сидящими манекенами, чтобы они не
    # выглядели парящими в воздухе.
    for seat in [Vector3(24, 0.18, -14.0), Vector3(-4, 0.18, -4.0)]:
        _build_box({
            "pos": seat,
            "size": Vector3(0.95, 0.36, 0.78),
            "color": Color(0.34, 0.27, 0.18),
            "solid": true,
            "kind": "crate",
        })

func _build_box(data: Dictionary) -> void:
    var size: Vector3 = data.size
    var pos: Vector3 = data.pos
    var solid: bool = data.solid
    var kind: String = str(data.get("kind", ""))
    var textured: bool = kind not in ["lane", "pad", "spawn_pad", "target"]
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

func _build_target_center(pos: Vector3) -> void:
    var disc := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = 0.36
    cyl.bottom_radius = 0.36
    cyl.height = 0.06
    cyl.radial_segments = 20
    disc.mesh = cyl
    disc.rotation.x = PI * 0.5
    disc.position = pos + Vector3(0, 0, 0.1)
    disc.material_override = _mat(Color(0.75, 0.12, 0.10))
    add_child(disc)

func _spawn_dummies() -> void:
    # Статичные мишени.
    _add_dummy("TARGET-01", Vector3(-18, 0, -19), "IRON LEGION", "stand")
    _add_dummy("TARGET-02", Vector3(-6, 0, -19), "RED FRONT", "stand")
    _add_dummy("TARGET-03", Vector3(6, 0, -19), "IRON LEGION", "stand")
    _add_dummy("TARGET-04", Vector3(18, 0, -19), "RED FRONT", "stand")

    # Движущиеся: вперёд-назад и боком.
    _add_dummy("WALK-FWD-01", Vector3(-12, 0, -14), "RED FRONT", "stand", Vector3(0, 0, 1), 3.5, 0.80)
    _add_dummy("WALK-FWD-02", Vector3(12, 0, -14), "IRON LEGION", "stand", Vector3(0, 0, 1), 3.5, 0.65)
    _add_dummy("STRAFE-01", Vector3(0, 0, -8), "RED FRONT", "stand", Vector3(1, 0, 0), 4.5, 0.90)
    _add_dummy("STRAFE-02", Vector3(0, 0, -24), "IRON LEGION", "stand", Vector3(1, 0, 0), 4.5, 0.60)
    _add_dummy("CROUCH-WALK-01", Vector3(-24, 0, -14), "IRON LEGION", "crouch", Vector3(1, 0, 0), 2.5, 0.50)

    # Сидящие и лежащие.
    _add_dummy("SIT-01", Vector3(24, 0, -14), "RED FRONT", "sit")
    _add_dummy("PRONE-01", Vector3(27, 0, -18), "IRON LEGION", "prone")
    _add_dummy("PRONE-02", Vector3(-27, 0, -18), "RED FRONT", "prone")

    # Стреляющие по неподвижной точке: стоя, сидя, лёжа и в приседе.
    var boards: Array = LAYOUT.target_boards()
    _add_dummy("SHOOT-STAND-01", Vector3(-12, 0, -4), "RED FRONT", "stand", Vector3.ZERO, 0.0, 1.0, true, boards[0])
    _add_dummy("SHOOT-SIT-01", Vector3(-4, 0, -4), "IRON LEGION", "sit", Vector3.ZERO, 0.0, 1.0, true, boards[0])
    _add_dummy("SHOOT-CROUCH-01", Vector3(4, 0, -4), "RED FRONT", "crouch", Vector3.ZERO, 0.0, 1.0, true, boards[1])
    _add_dummy("SHOOT-PRONE-01", Vector3(12, 0, -4), "IRON LEGION", "prone", Vector3.ZERO, 0.0, 1.0, true, boards[2])

func _add_dummy(
    dummy_name: String,
    pos: Vector3,
    team: String,
    stance: String,
    patrol_axis: Vector3 = Vector3.ZERO,
    patrol_range: float = 0.0,
    patrol_speed: float = 1.0,
    shooting: bool = false,
    shoot_target: Vector3 = Vector3.ZERO
) -> void:
    var d = Node3D.new()
    d.set_script(DUMMY_SCRIPT)
    d.position = pos
    d.team_name = team
    d.dummy_name = dummy_name
    d.stance = stance
    d.patrol_axis = patrol_axis
    d.patrol_range = patrol_range
    d.patrol_speed = patrol_speed
    d.shooting = shooting
    d.shoot_target = shoot_target
    add_child(d)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    var spawn: Vector3 = get_tree().get_meta("spawn_position", Vector3(0, LAYOUT.SPAWN_Y, 30))
    spawn.x = clampf(spawn.x, -40.0, 40.0)
    spawn.z = clampf(spawn.z, -40.0, 40.0)
    spawn.y = LAYOUT.SPAWN_Y
    player.position = spawn
    add_child(player)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.layer = 5
    add_child(hud)

    ui_click = AudioStreamPlayer.new()
    ui_click.stream = SFX_UI
    ui_click.volume_db = -8.0
    add_child(ui_click)

    var top := Label.new()
    top.text = "FRONTLINE  |  POLYGON  |  " + team_name
    top.position = Vector2(18, 10)
    top.add_theme_font_size_override("font_size", 16)
    top.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    top.add_theme_constant_override("shadow_offset_x", 2)
    top.add_theme_constant_override("shadow_offset_y", 2)
    hud.add_child(top)

    stats_label = Label.new()
    stats_label.text = "УБИЙСТВА: 0   СМЕРТИ: 0"
    stats_label.position = Vector2(18, 34)
    stats_label.add_theme_font_size_override("font_size", 15)
    stats_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    stats_label.add_theme_constant_override("shadow_offset_x", 2)
    stats_label.add_theme_constant_override("shadow_offset_y", 2)
    hud.add_child(stats_label)

    var back := Button.new()
    back.text = "МЕНЮ"
    back.anchor_left = 1.0
    back.anchor_right = 1.0
    back.offset_left = -152.0
    back.offset_right = -22.0
    back.offset_top = 12.0
    back.offset_bottom = 56.0
    back.add_theme_font_size_override("font_size", 16)
    back.pressed.connect(func():
        _play_ui()
        get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
    )
    hud.add_child(back)

    var board_btn := Button.new()
    board_btn.text = "ТАБЛО"
    board_btn.anchor_left = 1.0
    board_btn.anchor_right = 1.0
    board_btn.offset_left = -152.0
    board_btn.offset_right = -22.0
    board_btn.offset_top = 62.0
    board_btn.offset_bottom = 102.0
    board_btn.add_theme_font_size_override("font_size", 14)
    board_btn.pressed.connect(func():
        _play_ui()
        scoreboard.visible = not scoreboard.visible
    )
    hud.add_child(board_btn)

    var gfx_btn := Button.new()
    gfx_btn.text = "ГРАФИКА: " + GameSettings.quality_name()
    gfx_btn.anchor_left = 1.0
    gfx_btn.anchor_right = 1.0
    gfx_btn.offset_left = -152.0
    gfx_btn.offset_right = -22.0
    gfx_btn.offset_top = 112.0
    gfx_btn.offset_bottom = 152.0
    gfx_btn.add_theme_font_size_override("font_size", 13)
    gfx_btn.pressed.connect(func():
        _play_ui()
        GameSettings.cycle_quality()
        gfx_btn.text = "ГРАФИКА: " + GameSettings.quality_name()
        var sun := get_node_or_null("Sun")
        if sun != null:
            sun.shadow_enabled = GameSettings.shadows_enabled()
            sun.directional_shadow_max_distance = GameSettings.shadow_distance()
        if _environment != null:
            _environment.fog_enabled = GameSettings.fog_enabled()
    )
    hud.add_child(gfx_btn)

    scoreboard = PanelContainer.new()
    scoreboard.anchor_left = 0.5
    scoreboard.anchor_right = 0.5
    scoreboard.anchor_top = 0.5
    scoreboard.anchor_bottom = 0.5
    scoreboard.offset_left = -290.0
    scoreboard.offset_right = 290.0
    scoreboard.offset_top = -180.0
    scoreboard.offset_bottom = 180.0
    scoreboard.visible = false
    hud.add_child(scoreboard)
    var sb := VBoxContainer.new()
    scoreboard.add_child(sb)
    var title := Label.new()
    title.text = "ТАБЛИЦА ИГРОКОВ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 26)
    sb.add_child(title)
    var info := Label.new()
    info.text = "ЛОКАЛЬНЫЙ ТЕСТ  •  ОНЛАЙН БУДЕТ ДОБАВЛЕН ПОЗЖЕ"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sb.add_child(info)
    var row := Label.new()
    row.text = "ИГРОК                         СТОРОНА                 УБИЙСТВА     СМЕРТИ\nYOU                            %s                         %d                 %d" % [team_name, score_kills, score_deaths]
    row.add_theme_font_size_override("font_size", 17)
    sb.add_child(row)

func add_kill() -> void:
    score_kills += 1
    stats_label.text = "УБИЙСТВА: %d   СМЕРТИ: %d" % [score_kills, score_deaths]

func _play_ui() -> void:
    if ui_click != null:
        ui_click.play()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
        _play_ui()
        scoreboard.visible = not scoreboard.visible
