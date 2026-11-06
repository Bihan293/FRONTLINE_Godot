extends Control

var selected_map := "POLYGON"
var selected_team := "IRON LEGION"

func _ready() -> void:
    _show_main()

func _clear() -> void:
    for child in get_children():
        child.queue_free()

func _panel() -> VBoxContainer:
    var bg := ColorRect.new()
    bg.color = Color(0.035, 0.045, 0.055, 0.96)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var panel := VBoxContainer.new()
    panel.custom_minimum_size = Vector2(440, 0)
    panel.add_theme_constant_override("separation", 14)
    center.add_child(panel)
    return panel

func _label(parent: Control, text: String, size: int = 22, color: Color = Color.WHITE) -> void:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    parent.add_child(l)

func _button(parent: Control, text: String, callback: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 56)
    b.add_theme_font_size_override("font_size", 22)
    b.pressed.connect(callback)
    parent.add_child(b)

func _show_main() -> void:
    _clear()
    var p := _panel()
    _label(p, "FRONTLINE", 48)
    _label(p, "LOW-POLY MILITARY FPS  •  PROTOTYPE 0.1.0", 13, Color(0.65,0.7,0.73))
    _button(p, "ИГРАТЬ", _show_maps)
    _button(p, "НАСТРОЙКИ", _show_settings)
    _button(p, "ВЫХОД", _quit)

func _show_maps() -> void:
    _clear()
    var p := _panel()
    _label(p, "ВЫБОР КАРТЫ", 34)
    _label(p, "POLYGON  •  ТРЕНИРОВОЧНЫЙ ПОЛИГОН", 19, Color(0.8,0.82,0.84))
    _label(p, "Открытая площадка, укрытия и манекены для проверки стрельбы.", 15, Color(0.65,0.7,0.73))
    _button(p, "ВЫБРАТЬ POLYGON", _show_teams)
    _button(p, "НАЗАД", _show_main)

func _show_teams() -> void:
    _clear()
    var p := _panel()
    _label(p, "ВЫБОР СТОРОНЫ", 34)
    _label(p, "КОЛИЧЕСТВО ИГРОКОВ ПОКА ДОСТУПНО ТОЛЬКО В ОНЛАЙНЕ", 12, Color(0.65,0.7,0.73))
    _button(p, "IRON LEGION  •  ЧЁРНЫЕ", func(): _start_game("IRON LEGION"))
    _button(p, "RED FRONT  •  КРАСНЫЕ", func(): _start_game("RED FRONT"))
    _button(p, "НАЗАД", _show_maps)

func _show_settings() -> void:
    _clear()
    var p := _panel()
    _label(p, "НАСТРОЙКИ", 34)
    _label(p, "Прототип: управление и графика используют настройки устройства.", 16, Color(0.7,0.74,0.77))
    _button(p, "НАЗАД", _show_main)

func _start_game(team: String) -> void:
    get_tree().set_meta("selected_team", team)
    get_tree().change_scene_to_file("res://scenes/Polygon.tscn")

func _quit() -> void:
    get_tree().quit()
