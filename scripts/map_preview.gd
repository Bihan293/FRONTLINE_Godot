extends Control
class_name FRONTLINEMapPreview

## Рисует вид сверху из той же схемы, что и 3D-полигон.
## В режиме deploy по маркерам можно выбирать точку появления.

signal spawn_selected(index: int)

const LAYOUT = preload("res://scripts/map_layout.gd")

var show_spawns := false
var interactive := false
var selected_spawn := -1

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
    queue_redraw()

func set_selected(index: int) -> void:
    selected_spawn = index
    queue_redraw()

func _map_data() -> Dictionary:
    var pad := 14.0
    var extent: float = LAYOUT.PREVIEW_EXTENT
    var usable: Vector2 = size - Vector2(pad * 2.0, pad * 2.0)
    var s: float = minf(usable.x / (extent * 2.0), usable.y / (extent * 2.0))
    return {"s": s, "o": size * 0.5}

func world_to_local(p: Vector3) -> Vector2:
    var d := _map_data()
    return d.o + Vector2(p.x, p.z) * d.s

func _draw() -> void:
    var d := _map_data()
    var s: float = d.s
    var o: Vector2 = d.o
    if s <= 0.0:
        return
    var extent: float = LAYOUT.PREVIEW_EXTENT
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.065, 0.08, 0.075))
    var world_rect := Rect2(o - Vector2(extent, extent) * s, Vector2(extent, extent) * 2.0 * s)
    draw_rect(world_rect, Color(0.15, 0.17, 0.14))

    # Сетка каждые 10 метров.
    for i in range(-4, 5):
        var gx: float = o.x + i * 10.0 * s
        draw_line(Vector2(gx, world_rect.position.y), Vector2(gx, world_rect.end.y), Color(0.24, 0.27, 0.23, 0.55), 1.0)
        var gz: float = o.y + i * 10.0 * s
        draw_line(Vector2(world_rect.position.x, gz), Vector2(world_rect.end.x, gz), Color(0.24, 0.27, 0.23, 0.55), 1.0)

    # Объекты карты сверху.
    for b in LAYOUT.boxes():
        var kind: String = b.kind
        if kind == "floor" or kind == "spawn_pad" or kind == "pad":
            continue
        var pos: Vector3 = b.pos
        var box_size: Vector3 = b.size
        var center: Vector2 = o + Vector2(pos.x, pos.z) * s
        var rect_size := Vector2(maxf(box_size.x * s, 1.5), maxf(box_size.z * s, 1.5))
        var color: Color = b.color
        match kind:
            "lane":
                color = Color(0.72, 0.68, 0.5, 0.75)
            "target":
                color = Color(0.9, 0.88, 0.82)
            "post":
                color = Color(0.3, 0.28, 0.25)
            "crate":
                color = Color(0.5, 0.38, 0.24)
            "sandbag":
                color = Color(0.56, 0.5, 0.36)
        draw_rect(Rect2(center - rect_size * 0.5, rect_size), color.darkened(0.08))

    draw_rect(world_rect, Color(0.5, 0.55, 0.5, 0.85), false, 2.0)

    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(12.0, size.y - 20.0), "FRONTLINE  /  POLYGON", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.76, 0.81, 0.76))
    draw_string(font, Vector2(size.x - 62.0, 24.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.76, 0.81, 0.76))
    draw_line(Vector2(size.x - 30.0, 34.0), Vector2(size.x - 30.0, 14.0), Color(0.76, 0.81, 0.76), 2.0)
    draw_line(Vector2(size.x - 34.0, 20.0), Vector2(size.x - 30.0, 14.0), Color(0.76, 0.81, 0.76), 2.0)
    draw_line(Vector2(size.x - 26.0, 20.0), Vector2(size.x - 30.0, 14.0), Color(0.76, 0.81, 0.76), 2.0)

    if not show_spawns:
        return
    var spawns: Array = LAYOUT.spawns()
    for i in range(spawns.size()):
        var p: Vector2 = world_to_local(spawns[i])
        var chosen := i == selected_spawn
        var radius := 19.0 if chosen else 16.0
        var fill := Color(0.95, 0.78, 0.25, 0.95) if chosen else Color(0.18, 0.42, 0.72, 0.92)
        draw_circle(p, radius, fill)
        draw_arc(p, radius, 0.0, TAU, 40, Color(1, 1, 1, 0.85), 2.5, true)
        var text := str(i + 1)
        var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
        draw_string(font, p - text_size * 0.5 + Vector2(0.0, 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1))

func _gui_input(event: InputEvent) -> void:
    if not interactive:
        return
    var pos := Vector2.INF
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pos = event.position
    elif event is InputEventScreenTouch and event.pressed:
        pos = event.position
    if pos == Vector2.INF:
        return
    var spawns: Array = LAYOUT.spawns()
    for i in range(spawns.size()):
        if pos.distance_to(world_to_local(spawns[i])) <= 30.0:
            set_selected(i)
            spawn_selected.emit(i)
            accept_event()
            return
