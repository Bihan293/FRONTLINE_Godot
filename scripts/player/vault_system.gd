extends RefCounted
class_name FRONTLINEPlayerVault

## Перепрыгивание уступов: поиск кромки, дуга полёта и приземление.
## Компонент владеет таймером и точками траектории, игрок остаётся телом.

const WORLD_LAYER_MASK := 1 << 0
const SFX_FOOTSTEPS = [
	preload("res://assets/audio/footstep_000.ogg"),
	preload("res://assets/audio/footstep_001.ogg"),
	preload("res://assets/audio/footstep_002.ogg"),
]
const VAULT_DURATION := 0.38

var is_vaulting := false

var _player: CharacterBody3D
var _sprint_speed := 7.4
var _timer := 0.0
var _duration := VAULT_DURATION
var _start_pos := Vector3.ZERO
var _peak_pos := Vector3.ZERO
var _land_pos := Vector3.ZERO

func setup(player: CharacterBody3D, sprint_speed: float) -> void:
	_player = player
	_sprint_speed = sprint_speed

func cancel() -> void:
	is_vaulting = false
	_timer = 0.0

## Автоматический шаг на низкий уступ без анимации прыжка.
func try_step_up() -> void:
	if is_vaulting or int(_player.get("stance")) != 0 or not _player.is_on_floor():
		return
	var horizontal := Vector3(_player.velocity.x, 0.0, _player.velocity.z)
	if horizontal.length_squared() < 0.30:
		return
	var dir := horizontal.normalized()
	var feet := _player.global_position
	var space := _player.get_world_3d().direct_space_state
	var low_from := feet + Vector3.UP * 0.08 + dir * 0.28
	var low_q := PhysicsRayQueryParameters3D.create(low_from, low_from + dir * 0.36)
	low_q.collision_mask = WORLD_LAYER_MASK
	low_q.exclude = [_player.get_rid()]
	low_q.collide_with_areas = false
	var low_hit := space.intersect_ray(low_q)
	if low_hit.is_empty():
		return
	var top_from: Vector3 = low_hit.position + Vector3.UP * 0.70
	var top_q := PhysicsRayQueryParameters3D.create(top_from, top_from + Vector3.DOWN * 0.85)
	top_q.collision_mask = WORLD_LAYER_MASK
	top_q.exclude = [_player.get_rid()]
	top_q.collide_with_areas = false
	var top_hit := space.intersect_ray(top_q)
	if top_hit.is_empty():
		return
	var rise: float = float(top_hit.position.y) - feet.y
	if rise < 0.03 or rise > 0.55:
		return
	if float(top_hit.get("normal", Vector3.UP).y) < 0.55:
		return
	var clearance := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.33
	capsule.height = 1.15
	clearance.shape = capsule
	clearance.transform = Transform3D(Basis(), feet + Vector3.UP * (rise + 0.65) + dir * 0.30)
	clearance.collision_mask = WORLD_LAYER_MASK
	clearance.exclude = [_player.get_rid()]
	clearance.collide_with_areas = false
	if not space.intersect_shape(clearance, 1).is_empty():
		return
	_player.global_position = feet + Vector3.UP * (rise + 0.03)
	_player.velocity.y = maxf(_player.velocity.y, 0.0)

## Проверяет уступ перед игроком и запускает дугу перепрыгивания.
func try_vault() -> bool:
	if _player == null or bool(_player.get("is_dead")) or bool(_player.get("input_locked")) or is_vaulting:
		return false
	if _player.get("active_drone") != null:
		return false
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return false
	var space_state := _player.get_world_3d().direct_space_state
	if space_state == null:
		return false

	var camera: Camera3D = _player.get("camera")
	if camera == null:
		return false
	var fwd := -camera.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.01:
		fwd = -_player.global_transform.basis.z
	fwd = fwd.normalized()

	# 1. Луч на уровне пояса (0.65 м)
	var waist_from := _player.global_position + Vector3(0.0, 0.65, 0.0)
	var waist_to := waist_from + fwd * 1.35
	var q_waist := PhysicsRayQueryParameters3D.create(waist_from, waist_to)
	q_waist.collision_mask = WORLD_LAYER_MASK
	q_waist.exclude = [_player.get_rid()]
	q_waist.collide_with_areas = false
	var waist_hit := space_state.intersect_ray(q_waist)
	if waist_hit.is_empty():
		return false

	var hit_pos: Vector3 = waist_hit.position

	# 2. Поиск верхней кромки уступа/подоконника
	var over_pos := hit_pos + fwd * 0.32 + Vector3(0.0, 1.40, 0.0)
	var down_to := over_pos + Vector3(0.0, -1.90, 0.0)
	var q_down := PhysicsRayQueryParameters3D.create(over_pos, down_to)
	q_down.collision_mask = WORLD_LAYER_MASK
	q_down.exclude = [_player.get_rid()]
	q_down.collide_with_areas = false
	var top_hit := space_state.intersect_ray(q_down)
	if top_hit.is_empty():
		return false

	var ledge_y: float = top_hit.position.y
	var ledge_height: float = ledge_y - _player.global_position.y
	if ledge_height < 0.40 or ledge_height > 1.55:
		return false

	# 3. Проверка свободного пространства сверху (для окна/забора)
	var head_from := hit_pos + Vector3(0.0, (ledge_y - hit_pos.y) + 0.15, 0.0)
	var head_to := head_from + Vector3(0.0, 1.15, 0.0)
	var q_head := PhysicsRayQueryParameters3D.create(head_from, head_to)
	q_head.collision_mask = WORLD_LAYER_MASK
	q_head.exclude = [_player.get_rid()]
	var head_hit := space_state.intersect_ray(q_head)
	if not head_hit.is_empty():
		return false

	# 4. Проверка точки приземления
	var land_pos := hit_pos + fwd * 0.95
	var land_from := land_pos + Vector3(0.0, 1.0, 0.0)
	var land_to := land_from + Vector3(0.0, -2.6, 0.0)
	var q_land := PhysicsRayQueryParameters3D.create(land_from, land_to)
	q_land.collision_mask = WORLD_LAYER_MASK
	q_land.exclude = [_player.get_rid()]
	var land_hit := space_state.intersect_ray(q_land)
	if not land_hit.is_empty():
		land_pos.y = land_hit.position.y
	else:
		land_pos.y = _player.global_position.y

	is_vaulting = true
	_timer = 0.0
	_duration = VAULT_DURATION
	_start_pos = _player.global_position
	_peak_pos = Vector3(hit_pos.x, maxf(ledge_y + 0.28, _player.global_position.y + 0.75), hit_pos.z)
	_land_pos = land_pos
	var player_capsule: CapsuleShape3D = _player.get("player_capsule")
	player_capsule.height = 1.15
	_player.call("_play_sfx", _player.get("sfx_footstep"), SFX_FOOTSTEPS[0], -6.0, 1.25)
	return true

func process(delta: float) -> void:
	_timer += delta
	var t := clampf(_timer / maxf(0.01, _duration), 0.0, 1.0)
	var ease_t := smoothstep(0.0, 1.0, t)
	var target_horiz := _start_pos.lerp(_land_pos, ease_t)
	var arc := sin(t * PI) * (_peak_pos.y - minf(_start_pos.y, _land_pos.y) + 0.12)
	var target_y := lerpf(_start_pos.y, _land_pos.y, ease_t) + arc
	_player.global_position = Vector3(target_horiz.x, target_y, target_horiz.z)

	var camera: Camera3D = _player.get("camera")
	var pitch := float(_player.get("pitch"))
	var recoil: Vector2 = _player.get("recoil")
	var cam_dip := -sin(t * PI) * deg_to_rad(6.5)
	camera.rotation.x = clampf(pitch + recoil.y + cam_dip, -1.45, 1.45)
	var weapon_root: Node3D = _player.get("weapon_root")
	if weapon_root != null:
		var weapon_base: Vector3 = _player.get("weapon_base")
		weapon_root.position.y = lerpf(weapon_root.position.y, weapon_base.y - 0.14 * sin(t * PI), delta * 24.0)
		weapon_root.rotation.z = lerpf(weapon_root.rotation.z, -deg_to_rad(15.0) * sin(t * PI), delta * 24.0)

	if t >= 1.0:
		is_vaulting = false
		_player.global_position = _land_pos
		var fwd := (_land_pos - _start_pos)
		fwd.y = 0.0
		_player.velocity = fwd.normalized() * _sprint_speed
		_player.velocity.y = -0.5
		_player.set("landing_anim", 0.5)
		var stance := int(_player.get("stance"))
		var player_capsule: CapsuleShape3D = _player.get("player_capsule")
		player_capsule.height = 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
		_player.move_and_slide()
