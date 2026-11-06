extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const DUMMY_SCRIPT = preload("res://scripts/dummy.gd")
var player: CharacterBody3D
var score_kills := 0
var score_deaths := 0
var team_name := "IRON LEGION"
var hud: CanvasLayer
var scoreboard: PanelContainer
var stats_label: Label

func _ready() -> void:
    team_name = str(get_tree().get_meta("selected_team", "IRON LEGION"))
    _build_world()
    _spawn_player()
    _build_hud()

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var inst := MeshInstance3D.new()
    inst.mesh = mesh
    inst.position = pos
    inst.material_override = _mat(color)
    parent.add_child(inst)
    return inst

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.48, 0.58, 0.62)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.75, 0.78, 0.8)
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_energy = 1.15
    add_child(sun)

    # Real static floor collider. The previous version had only a visible mesh,
    # so CharacterBody3D had no physical surface and fell through the map.
    var floor_body := StaticBody3D.new()
    floor_body.position = Vector3(0,-0.35,0)
    add_child(floor_body)
    var floor_mesh := MeshInstance3D.new()
    var floor_box := BoxMesh.new()
    floor_box.size = Vector3(90,0.6,90)
    floor_mesh.mesh = floor_box
    floor_mesh.material_override = _mat(Color(0.27,0.31,0.25))
    floor_body.add_child(floor_mesh)
    var floor_collision := CollisionShape3D.new()
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(90,0.6,90)
    floor_collision.shape = floor_shape
    floor_body.add_child(floor_collision)

    for x in [-18.0, -9.0, 0.0, 9.0, 18.0]:
        _box(self, Vector3(x,0.015,-12), Vector3(0.16,0.03,42), Color(0.65,0.62,0.48))
    for x in [-20.0,-10.0,10.0,20.0]:
        _box(self, Vector3(x,0.8,4), Vector3(5,1.6,1.1), Color(0.48,0.43,0.32))
    for z in [-18.0,-8.0,4.0]:
        _box(self, Vector3(-29,0.7,z), Vector3(1.2,1.4,7), Color(0.43,0.45,0.43))
        _box(self, Vector3(29,0.7,z), Vector3(1.2,1.4,7), Color(0.43,0.45,0.43))
    _box(self, Vector3(0,2,-32), Vector3(52,4,1.5), Color(0.34,0.35,0.32))
    for i in range(7):
        var d = Node3D.new()
        d.set_script(DUMMY_SCRIPT)
        d.position = Vector3(-18 + i * 6, 0.76, -19 - (i % 2) * 5)
        d.team_color = Color(0.25,0.28,0.3) if i % 2 == 0 else Color(0.42,0.29,0.18)
        d.dummy_name = "TARGET-%02d" % (i+1)
        add_child(d)
    _box(self, Vector3(-34,0.1,24), Vector3(5,0.2,5), Color(0.18,0.2,0.22))
    _box(self, Vector3(34,0.1,24), Vector3(5,0.2,5), Color(0.55,0.12,0.12))

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    var spawn: Vector3 = get_tree().get_meta("spawn_position", Vector3(0,0.9,30))
    # Clamp the requested spawn to the playable floor and ray-check the ground.
    spawn.x = clampf(spawn.x, -40.0, 40.0)
    spawn.z = clampf(spawn.z, -40.0, 40.0)
    spawn.y = 0.9
    player.position = spawn
    add_child(player)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.layer = 5
    add_child(hud)

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
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
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
    board_btn.pressed.connect(func(): scoreboard.visible = not scoreboard.visible)
    hud.add_child(board_btn)

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

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
        scoreboard.visible = not scoreboard.visible
