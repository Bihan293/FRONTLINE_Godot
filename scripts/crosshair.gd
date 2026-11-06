extends Control
class_name Crosshair

var _hit_time := 0.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func flash_hit() -> void:
    _hit_time = 0.16
    queue_redraw()

func _process(delta: float) -> void:
    if _hit_time > 0.0:
        _hit_time = maxf(0.0, _hit_time - delta)
        queue_redraw()

func _draw() -> void:
    var c := size * 0.5
    var gap := 7.0
    var length := 11.0
    var col := Color(0.96, 1.0, 0.98, 0.88)
    draw_line(c + Vector2(-gap - length, 0), c + Vector2(-gap, 0), col, 2.0, true)
    draw_line(c + Vector2(gap, 0), c + Vector2(gap + length, 0), col, 2.0, true)
    draw_line(c + Vector2(0, -gap - length), c + Vector2(0, -gap), col, 2.0, true)
    draw_line(c + Vector2(0, gap), c + Vector2(0, gap + length), col, 2.0, true)
    draw_circle(c, 1.6, col)
    if _hit_time > 0.0:
        var hit_col := Color(1.0, 0.28, 0.22, minf(1.0, _hit_time / 0.08))
        var a := 8.0
        var b := 19.0
        draw_line(c + Vector2(-b, -b), c + Vector2(-a, -a), hit_col, 3.0, true)
        draw_line(c + Vector2(b, -b), c + Vector2(a, -a), hit_col, 3.0, true)
        draw_line(c + Vector2(-b, b), c + Vector2(-a, a), hit_col, 3.0, true)
        draw_line(c + Vector2(b, b), c + Vector2(a, a), hit_col, 3.0, true)
