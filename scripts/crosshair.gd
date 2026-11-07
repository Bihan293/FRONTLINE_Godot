extends Control
class_name Crosshair

var _hit_time := 0.0
var is_sniper_scope := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func set_sniper_scope(active: bool) -> void:
    if is_sniper_scope != active:
        is_sniper_scope = active
        queue_redraw()

func flash_hit() -> void:
    _hit_time = 0.16
    queue_redraw()

func _process(delta: float) -> void:
    if _hit_time > 0.0:
        _hit_time = maxf(0.0, _hit_time - delta)
        queue_redraw()

func _draw() -> void:
    var c := size * 0.5
    if is_sniper_scope:
        var scope_r: float = minf(size.x, size.y) * 0.42
        # Затемнение вне круга прицела
        draw_arc(c, scope_r + 6.0, 0.0, TAU, 64, Color(0.02, 0.02, 0.02, 0.95), 12.0, true)
        draw_circle(c, scope_r, Color(0.05, 0.08, 0.05, 0.10)) # легкий оттенок оптики
        draw_arc(c, scope_r, 0.0, TAU, 64, Color(0.05, 0.05, 0.05, 0.95), 4.0, true)

        # Тонкие нити прицельной сетки
        var reticle_col := Color(0.08, 0.08, 0.08, 0.92)
        draw_line(Vector2(c.x - scope_r, c.y), Vector2(c.x + scope_r, c.y), reticle_col, 1.5, true)
        draw_line(Vector2(c.x, c.y - scope_r), Vector2(c.x, c.y + scope_r), reticle_col, 1.5, true)

        # Мил-дот насечки дальности
        for dist in [40.0, 80.0, 120.0, 160.0]:
            draw_line(Vector2(c.x - 6.0, c.y + dist), Vector2(c.x + 6.0, c.y + dist), reticle_col, 1.5, true)
            draw_line(Vector2(c.x - 6.0, c.y - dist), Vector2(c.x + 6.0, c.y - dist), reticle_col, 1.5, true)
            draw_line(Vector2(c.x + dist, c.y - 6.0), Vector2(c.x + dist, c.y + 6.0), reticle_col, 1.5, true)
            draw_line(Vector2(c.x - dist, c.y - 6.0), Vector2(c.x - dist, c.y + 6.0), reticle_col, 1.5, true)

        draw_circle(c, 2.0, Color(0.9, 0.1, 0.1, 0.85)) # красная точка в центре
        return

    var col := Color(0.96, 1.0, 0.98, 0.88)
    # A single, outlined point stays readable over both bright scenery and muzzle flash.
    draw_circle(c, 3.0, Color(0.01, 0.015, 0.015, 0.9))
    draw_circle(c, 1.7, col)
    if _hit_time > 0.0:
        var hit_col := Color(1.0, 0.28, 0.22, minf(1.0, _hit_time / 0.08))
        var a := 8.0
        var b := 19.0
        draw_line(c + Vector2(-b, -b), c + Vector2(-a, -a), hit_col, 3.0, true)
        draw_line(c + Vector2(b, -b), c + Vector2(a, -a), hit_col, 3.0, true)
        draw_line(c + Vector2(-b, b), c + Vector2(-a, a), hit_col, 3.0, true)
        draw_line(c + Vector2(b, b), c + Vector2(a, a), hit_col, 3.0, true)
