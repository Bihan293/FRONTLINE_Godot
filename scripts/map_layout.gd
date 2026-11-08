extends RefCounted
class_name FRONTLINEMapLayout

## Единая схема полигона. Используется и для 3D-сцены, и для превью в меню,
## поэтому карта в меню и карта в игре всегда совпадают.

const HALF_SIZE := 45.0
const PREVIEW_EXTENT := 40.0
const SPAWN_Y := 0.25

static func spawns() -> Array:
    return [
        Vector3(-30, SPAWN_Y, 30),
        Vector3(-10, SPAWN_Y, 30),
        Vector3(10, SPAWN_Y, 30),
        Vector3(30, SPAWN_Y, 30),
    ]

static func target_boards() -> Array:
    return [
        Vector3(-8, 1.3, -30.4),
        Vector3(0, 1.3, -30.4),
        Vector3(8, 1.3, -30.4),
    ]

static func boxes() -> Array:
    var out: Array = []
    # Пол и разметка.
    _push(out, Vector3(0, -0.35, 0), Vector3(90, 0.6, 90), Color(0.27, 0.31, 0.25), true, "floor")
    for x in [-18.0, -9.0, 0.0, 9.0, 18.0]:
        _push(out, Vector3(x, 0.015, -12), Vector3(0.16, 0.03, 42), Color(0.65, 0.62, 0.48), false, "lane")
    _push(out, Vector3(0, 0.02, 24), Vector3(64, 0.04, 5), Color(0.19, 0.21, 0.19), false, "pad")
    for x in [-30.0, -10.0, 10.0, 30.0]:
        _push(out, Vector3(x, 0.025, 30), Vector3(5.4, 0.05, 5.4), Color(0.16, 0.20, 0.23), false, "spawn_pad")

    # Бетонные укрытия и стены.
    for x in [-20.0, -10.0, 10.0, 20.0]:
        _push(out, Vector3(x, 0.8, 4), Vector3(5, 1.6, 1.1), Color(0.48, 0.43, 0.32), true, "cover")
    for z in [-18.0, -8.0, 4.0]:
        _push(out, Vector3(-29, 0.7, z), Vector3(1.2, 1.4, 7), Color(0.43, 0.45, 0.43), true, "wall")
        _push(out, Vector3(29, 0.7, z), Vector3(1.2, 1.4, 7), Color(0.43, 0.45, 0.43), true, "wall")
    _push(out, Vector3(0, 2, -32), Vector3(52, 4, 1.5), Color(0.34, 0.35, 0.32), true, "backstop")

    # Мешки с песком.
    for p in [Vector3(-14, 0.35, -8), Vector3(14, 0.35, -8), Vector3(-14, 0.35, 12), Vector3(14, 0.35, 12)]:
        _push(out, p, Vector3(4.2, 0.7, 0.9), Color(0.46, 0.41, 0.3), true, "sandbag")

    # Ящики.
    for p in [
        Vector3(-24, 0.6, -26), Vector3(-22.8, 0.6, -26), Vector3(-24, 1.8, -26),
        Vector3(24, 0.6, -26), Vector3(25.2, 0.6, -26), Vector3(24, 1.8, -26),
    ]:
        _push(out, p, Vector3(1.2, 1.2, 1.2), Color(0.38, 0.3, 0.2), true, "crate")

    # Низкие барьеры на огневом рубеже и полоса паркура.
    for p in [Vector3(-10, 0.5, 14), Vector3(10, 0.5, 14)]:
        _push(out, p, Vector3(5, 1.0, 0.7), Color(0.4, 0.38, 0.33), true, "barrier")
    # Тренировочный забор (1.05 м) и оконный проём для отработки паркура
    _push(out, Vector3(-18.0, 0.52, 20.0), Vector3(6.0, 1.05, 0.25), Color(0.42, 0.32, 0.22), true, "training_fence")
    _push(out, Vector3(18.0, 0.44, 20.0), Vector3(2.4, 0.88, 0.40), Color(0.48, 0.43, 0.32), true, "window_sill")
    _push(out, Vector3(18.0, 2.20, 20.0), Vector3(2.4, 0.80, 0.40), Color(0.48, 0.43, 0.32), true, "window_lintel")
    _push(out, Vector3(15.6, 1.30, 20.0), Vector3(1.4, 2.60, 0.40), Color(0.48, 0.43, 0.32), true, "wall")
    _push(out, Vector3(20.4, 1.30, 20.0), Vector3(1.4, 2.60, 0.40), Color(0.48, 0.43, 0.32), true, "wall")

    # Тренировочный противотанковый ёж (1.10 м) и траншейный настил
    _push(out, Vector3(0.0, 0.55, 18.0), Vector3(2.2, 0.22, 0.22), Color(0.26, 0.27, 0.29), true, "hedgehog")
    _push(out, Vector3(0.0, 0.55, 18.0), Vector3(0.22, 0.22, 2.2), Color(0.26, 0.27, 0.29), true, "hedgehog")
    _push(out, Vector3(0.0, 0.55, 18.0), Vector3(0.22, 1.10, 0.22), Color(0.26, 0.27, 0.29), true, "hedgehog")
    _push(out, Vector3(0.0, 0.02, 14.0), Vector3(8.0, 0.04, 2.4), Color(0.36, 0.28, 0.18), false, "duckboard")

    # Мишени (белые щиты с красным центром).
    for p in target_boards():
        _push(out, p + Vector3(0, -1.3, 0), Vector3(0.18, 2.6, 0.18), Color(0.22, 0.2, 0.18), true, "post")
        _push(out, p, Vector3(1.6, 2.0, 0.12), Color(0.86, 0.85, 0.8), true, "target")
    return out

## Крупные несущие конструкции полигона, отбрасывающие тени.
## Декорации, полосы препятствий, мишени, ящики и мешки с песком отключают тени.
const SHADOW_KINDS := {
    "backstop": true,
    "wall": true,
    "window_lintel": true,
}

static func _push(out: Array, pos: Vector3, size: Vector3, color: Color, solid: bool, kind: String, cast_shadow: Variant = null) -> void:
    var shadow: bool = (cast_shadow as bool) if cast_shadow != null else SHADOW_KINDS.get(kind, false)
    out.append({
        "pos": pos,
        "size": size,
        "color": color,
        "solid": solid,
        "kind": kind,
        "cast_shadow": shadow,
    })
