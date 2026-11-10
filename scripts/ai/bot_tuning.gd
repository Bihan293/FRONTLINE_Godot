extends RefCounted
class_name FRONTLINEBotTuning

## Единые параметры ИИ пехоты. Все дальности в метрах, интервалы в секундах.
## Держим их здесь, чтобы поведение не расползалось по магическим числам.

# Восприятие
const SCAN_INTERVAL_IDLE := 0.22
const SCAN_INTERVAL_TRACKING := 0.55
const SCAN_INTERVAL_VISIBLE := 1.00
const LOS_INTERVAL := 0.18
const TARGET_MEMORY := 4.0
const ALERT_MEMORY := 9.0
const PROXIMITY_AWARENESS := 7.0
const HEARING_RADIUS := 55.0
const FOV_DOT := 0.25            # ~75° в каждую сторону; вблизи обзор круговой
const FOV_NEAR_RADIUS := 10.0
const MAX_CANDIDATES := 2        # сколько ближайших врагов проверяем лучом за скан

# Слои столкновений
const WORLD_LAYER := 1 << 0
const HITBOX_LAYER := 1 << 1
const SOLDIER_LAYER := 1 << 2
const LOS_MASK := WORLD_LAYER | HITBOX_LAYER | SOLDIER_LAYER

# Дальность ведения огня по индексу оружия (ak, mp40, mosin, m1911, shotgun, ppsh, kar98k, panzerfaust)
const ENGAGE_RANGE := [60.0, 30.0, 85.0, 25.0, 20.0, 35.0, 85.0, 40.0]

static func engage_range(weapon_index: int) -> float:
	return float(ENGAGE_RANGE[clampi(weapon_index, 0, ENGAGE_RANGE.size() - 1)])

## Высота глаз бойца с учётом стойки: 0 — стоя, 1 — присед, 2 — лёжа.
static func eye_height(stance_value: int) -> float:
	match stance_value:
		1:
			return 1.15
		2:
			return 0.55
		_:
			return 1.55

## Точка прицеливания по росту цели. Для игрока учитываем реальную стойку,
## у ботов хитбоксы пока фиксированные, поэтому используем их высоты.
static func aim_height(target: Node3D) -> float:
	if target.has_method("get_projectile_rids"):
		return 1.20
	var stance_value := 0
	if "stance" in target:
		stance_value = int(target.get("stance"))
	match stance_value:
		1:
			return 0.95
		2:
			return 0.45
		_:
			return 1.25
