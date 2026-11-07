extends Control

const MAP_PREVIEW_SCRIPT = preload("res://scripts/map_preview.gd")
const LAYOUT = preload("res://scripts/map_layout.gd")
var map_selected := false
var selected_team := "IRON LEGION"

func _ready() -> void:
    _show_main()

func _clear() -> void:
    for child in get_children():
        child.queue_free()

func _background() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.035, 0.047, 0.052, 1.0)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

func _label(parent: Control, text: String, size: int = 22, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = align
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func _button(parent: Control, text: String, callback: Callable, min_size := Vector2(0, 54)) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.add_theme_font_size_override("font_size", 20)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _make_shell(title: String) -> VBoxContainer:
    _clear()
    _background()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 44
    root.offset_top = 28
    root.offset_right = -44
    root.offset_bottom = -28
    root.add_theme_constant_override("separation", 18)
    add_child(root)
    _label(root, "FRONTLINE     /     " + title, 30, Color(0.88,0.9,0.88))
    var line := ColorRect.new()
    line.custom_minimum_size.y = 2
    line.color = Color(0.48,0.52,0.48)
    root.add_child(line)
    return root

func _show_main() -> void:
    var root := _make_shell("MAIN MENU")
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)
    var center := VBoxContainer.new()
    center.custom_minimum_size = Vector2(430,0)
    center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    center.add_theme_constant_override("separation", 14)
    root.add_child(center)
    _label(center, "FRONTLINE", 54, Color(0.93,0.94,0.9), HORIZONTAL_ALIGNMENT_CENTER)
    _label(center, "LOW-POLY TACTICAL FPS  •  PROTOTYPE 0.3", 15, Color(0.62,0.68,0.67), HORIZONTAL_ALIGNMENT_CENTER)
    _button(center, "ИГРАТЬ", _show_maps, Vector2(0,62))
    _button(center, "НАСТРОЙКИ", _show_settings, Vector2(0,54))
    _button(center, "ВЫХОД", _quit, Vector2(0,54))
    var spacer2 := Control.new()
    spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer2)
    _label(root, "ANDROID  •  GODOT 4  •  BUILD 0.3.0", 12, Color(0.5,0.56,0.55), HORIZONTAL_ALIGNMENT_CENTER)

func _show_maps() -> void:
    map_selected = false
    var root := _make_shell("ВЫБОР КАРТЫ")
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 24)
    root.add_child(body)

    var list := VBoxContainer.new()
    list.custom_minimum_size = Vector2(300,0)
    list.add_theme_constant_override("separation", 12)
    body.add_child(list)
    _label(list, "ДОСТУПНЫЕ КАРТЫ", 17, Color(0.68,0.73,0.7))
    var card := Button.new()
    card.text = "POLYGON\nТренировочный полигон"
    card.custom_minimum_size = Vector2(290,105)
    card.add_theme_font_size_override("font_size", 21)
    card.pressed.connect(_select_polygon)
    list.add_child(card)
    var hint := _label(list, "Выбери карту, чтобы открыть её обзор.", 14, Color(0.55,0.61,0.6))
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _button(list, "НАЗАД", _show_main, Vector2(0,50))

    var preview_panel := PanelContainer.new()
    preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(preview_panel)
    var preview := VBoxContainer.new()
    preview.add_theme_constant_override("separation", 12)
    preview_panel.add_child(preview)
    var placeholder := CenterContainer.new()
    placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview.add_child(placeholder)
    _label(placeholder, "ВЫБЕРИ POLYGON СЛЕВА", 22, Color(0.58,0.64,0.62), HORIZONTAL_ALIGNMENT_CENTER)
    var details := VBoxContainer.new()
    details.name = "MapDetails"
    details.visible = false
    preview.add_child(details)
    var image = MAP_PREVIEW_SCRIPT.new()
    image.custom_minimum_size = Vector2(560, 290)
    image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    image.size_flags_vertical = Control.SIZE_EXPAND_FILL
    details.add_child(image)
    _label(details, "POLYGON  /  TRAINING RANGE", 24)
    _label(details, "Большой тренировочный полигон: стрельбище с мишенями, бетонные укрытия, мешки с песком, движущиеся, сидящие, лежащие и стреляющие манекены. Схема совпадает с картой в игре.", 16, Color(0.72,0.77,0.74))
    _button(details, "ИГРАТЬ НА ЭТОЙ КАРТЕ", _show_teams, Vector2(0,58))
    set_meta("map_details", details)
    set_meta("map_placeholder", placeholder)

func _select_polygon() -> void:
    var details = get_meta("map_details")
    var placeholder = get_meta("map_placeholder")
    details.visible = true
    placeholder.visible = false

func _show_teams() -> void:
    var root := _make_shell("ВЫБОР СТОРОНЫ")
    _label(root, "Выбери фракцию. После выбора откроется тактическая схема карты.", 17, Color(0.68,0.73,0.7))
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 28)
    root.add_child(row)
    _team_card(row, "IRON LEGION", "ЧЁРНЫЕ", Color(0.28,0.32,0.35), "Серо-графитовая форма и тёмное снаряжение.")
    _team_card(row, "RED FRONT", "КРАСНЫЕ", Color(0.48,0.25,0.17), "Коричневая и хаки форма, советский визуальный стиль.")
    var spacer2 := Control.new()
    spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer2)
    _button(root, "НАЗАД К КАРТЕ", _show_maps, Vector2(0,48))

func _team_card(parent: Control, faction: String, subtitle: String, tint: Color, description: String) -> void:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    panel.add_child(box)
    var swatch := ColorRect.new()
    swatch.color = tint
    swatch.custom_minimum_size = Vector2(0,110)
    box.add_child(swatch)
    _label(box, faction, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, subtitle, 16, tint.lightened(0.4), HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, description, 15, Color(0.7,0.74,0.72), HORIZONTAL_ALIGNMENT_CENTER)
    var choose := _button(box, "ВЫБРАТЬ", func(): _choose_team(faction), Vector2(0,58))
    choose.size_flags_vertical = Control.SIZE_SHRINK_END

func _choose_team(faction: String) -> void:
    selected_team = faction
    get_tree().set_meta("selected_team", faction)
    get_tree().set_meta("selected_map", "POLYGON")
    _show_deployment()

func _show_deployment() -> void:
    var root := _make_shell("DEPLOYMENT  /  POLYGON")
    _label(root, "СТОРОНА: " + selected_team + "     •     Выбери точку появления на карте", 16, Color(0.75,0.79,0.76))
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 18)
    root.add_child(body)
    var map_holder := PanelContainer.new()
    map_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_holder.custom_minimum_size = Vector2(480, 300)
    body.add_child(map_holder)
    var map_overlay := Control.new()
    map_holder.add_child(map_overlay)
    map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var image = MAP_PREVIEW_SCRIPT.new()
    image.show_spawns = true
    image.interactive = true
    image.custom_minimum_size = Vector2(460, 300)
    image.spawn_selected.connect(_select_spawn)
    map_overlay.add_child(image)
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var side := VBoxContainer.new()
    side.custom_minimum_size = Vector2(250,0)
    side.add_theme_constant_override("separation", 12)
    body.add_child(side)
    _label(side, "ТОЧКА ПОЯВЛЕНИЯ", 19)
    var selected := Label.new()
    selected.name = "SpawnLabel"
    selected.text = "Точка не выбрана"
    selected.add_theme_font_size_override("font_size", 18)
    side.add_child(selected)
    _label(side, "Нажми на один из четырёх маркеров на схеме. После DEPLOY ты появишься в выбранной точке.", 14, Color(0.67,0.72,0.69))
    var deploy := _button(side, "DEPLOY", _deploy, Vector2(0,66))
    deploy.disabled = true
    set_meta("spawn_label", selected)
    set_meta("deploy_button", deploy)
    set_meta("map_preview", image)
    set_meta("selected_spawn", -1)
    _button(side, "НАЗАД", _show_teams, Vector2(0,48))

func _select_spawn(index: int) -> void:
    set_meta("selected_spawn", index)
    var label: Label = get_meta("spawn_label")
    label.text = "ТОЧКА %d  •  ГОТОВА" % (index + 1)
    var deploy: Button = get_meta("deploy_button")
    deploy.disabled = false
    var preview = get_meta("map_preview", null)
    if preview != null:
        preview.set_selected(index)

func _deploy() -> void:
    var index: int = int(get_meta("selected_spawn", -1))
    if index < 0:
        return
    var spawn_positions: Array = LAYOUT.spawns()
    get_tree().set_meta("spawn_position", spawn_positions[index])
    get_tree().change_scene_to_file("res://scenes/Polygon.tscn")

func _show_settings() -> void:
    var root := _make_shell("НАСТРОЙКИ")
    _label(root, "ГРАФИКА", 20, Color(0.85, 0.88, 0.84))
    var quality_button := _button(root, "КАЧЕСТВО: " + GameSettings.quality_name(), func(): pass, Vector2(0, 56))
    quality_button.pressed.connect(func():
        GameSettings.cycle_quality()
        quality_button.text = "КАЧЕСТВО: " + GameSettings.quality_name()
    )
    _label(root, "НИЗКОЕ — максимум FPS, без теней и сглаживания. СРЕДНЕЕ — баланс. ВЫСОКОЕ — тени, MSAA 4x и полное разрешение.", 15, Color(0.66, 0.71, 0.68))
    var gap := Control.new()
    gap.custom_minimum_size.y = 12
    root.add_child(gap)
    _label(root, "ЗВУК", 20, Color(0.85, 0.88, 0.84))
    var volume_row := HBoxContainer.new()
    volume_row.add_theme_constant_override("separation", 18)
    root.add_child(volume_row)
    var volume_label := _label(volume_row, "ГРОМКОСТЬ: %d%%" % int(round(GameSettings.master_volume * 100.0)), 16)
    volume_label.custom_minimum_size.x = 190
    var slider := HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 0.05
    slider.value = GameSettings.master_volume
    slider.custom_minimum_size = Vector2(360, 45)
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.value_changed.connect(func(value: float):
        GameSettings.set_master_volume(value)
        volume_label.text = "ГРОМКОСТЬ: %d%%" % int(round(value * 100.0))
    )
    volume_row.add_child(slider)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)
    _button(root, "НАЗАД", _show_main, Vector2(0, 52))

func _quit() -> void:
    get_tree().quit()
