extends Node3D
class_name FRONTLINEPlayerWeaponView

## Визуал оружия от первого лица: модель, дуло, вспышка, покачивание,
## отдача и наклон при перезарядке. Не знает про патроны и урон.

const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")

var root: Node3D
var mount: Node3D
var muzzle: Node3D
var flash: MeshInstance3D
var flash_timer := 0.0
var base_position := Vector3.ZERO
var aim_position := Vector3.ZERO

var _camera: Camera3D
var _view_arms: FRONTLINEPlayerViewArms
var _rotation_smooth := Vector3.ZERO

func setup(camera: Camera3D) -> void:
	_camera = camera
	root = Node3D.new()
	root.name = "ViewModel"
	root.position = Vector3(0.24, -0.23, -0.60)
	root.scale = Vector3.ONE * 0.72
	_camera.add_child(root)
	mount = Node3D.new()
	mount.name = "WeaponMount"
	root.add_child(mount)

func attach_arms(arms: FRONTLINEPlayerViewArms) -> void:
	_view_arms = arms

func equip(weapon_id: String, is_shovel: bool) -> void:
	if mount == null or _view_arms == null:
		return
	for child in mount.get_children():
		child.queue_free()
	flash = null
	muzzle = null

	var model: Node3D = WEAPON_MESHES.make_weapon(weapon_id)
	if model == null:
		push_error("FRONTLINE: cannot build weapon model " + weapon_id)
		return
	mount.add_child(model)

	if is_shovel:
		base_position = Vector3(0.10, -0.13, -0.46)
		aim_position = Vector3(0.02, -0.08, -0.45)
		_view_arms.set_hand_offsets(Vector3(-0.02, -0.04, -0.24), Vector3(0.01, -0.05, 0.03))
		return

	var muzzle_anchor := model.get_node_or_null("Muzzle") as Node3D
	if muzzle_anchor == null:
		push_error("FRONTLINE: weapon has no muzzle marker " + weapon_id)
		return
	muzzle = muzzle_anchor
	_build_flash(muzzle_anchor)

	var hip_pos := Vector3(0.08, -0.17, -0.52)
	var aim_pos := Vector3(0.0, -0.092, -0.52)
	var left_wrist_offset := Vector3(-0.02, -0.03, -0.18)
	var right_wrist_offset := Vector3(0.01, -0.06, 0.02)

	match weapon_id:
		"ak47":
			hip_pos = Vector3(0.08, -0.17, -0.52)
			aim_pos = Vector3(-0.0045, -0.070, -0.52)
			left_wrist_offset = Vector3(-0.02, -0.03, -0.18)
			right_wrist_offset = Vector3(0.01, -0.06, 0.02)
		"mp40":
			hip_pos = Vector3(0.075, -0.16, -0.48)
			aim_pos = Vector3(0.0, -0.0375, -0.48)
			left_wrist_offset = Vector3(-0.02, -0.04, -0.14)
			right_wrist_offset = Vector3(0.01, -0.06, 0.04)
		"mosin":
			hip_pos = Vector3(0.09, -0.17, -0.54)
			aim_pos = Vector3(0.0, -0.030, -0.50)
			left_wrist_offset = Vector3(-0.02, -0.025, -0.24)
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"m1911":
			hip_pos = Vector3(0.05, -0.15, -0.44)
			aim_pos = Vector3(0.0, -0.023, -0.38)
			left_wrist_offset = Vector3(-0.03, -0.055, 0.02)
			right_wrist_offset = Vector3(0.01, -0.055, 0.02)
		"shotgun":
			hip_pos = Vector3(0.09, -0.18, -0.50)
			aim_pos = Vector3(0.0, -0.025, -0.46)
			left_wrist_offset = Vector3(-0.02, -0.04, -0.22)
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"ppsh41":
			hip_pos = Vector3(0.08, -0.17, -0.48)
			aim_pos = Vector3(0.0, -0.026, -0.46)
			left_wrist_offset = Vector3(-0.02, -0.035, -0.16)
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"kar98k":
			hip_pos = Vector3(0.09, -0.17, -0.54)
			aim_pos = Vector3(0.0, -0.0375, -0.44)
			left_wrist_offset = Vector3(-0.02, -0.025, -0.24)
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"panzerfaust":
			hip_pos = Vector3(0.14, -0.09, -0.46)
			aim_pos = Vector3(0.0, -0.044, -0.42)
			left_wrist_offset = Vector3(-0.03, -0.02, -0.28)
			right_wrist_offset = Vector3(0.01, 0.03, -0.08)

	base_position = hip_pos
	aim_position = aim_pos
	_view_arms.set_hand_offsets(left_wrist_offset, right_wrist_offset)

func trigger_flash(duration: float = 0.045) -> void:
	if flash == null:
		return
	flash.visible = true
	flash_timer = duration

func muzzle_position() -> Vector3:
	if muzzle != null and is_instance_valid(muzzle):
		return muzzle.global_position
	return _camera.global_position if _camera != null else Vector3.ZERO

func set_view_visible(value: bool) -> void:
	if root != null:
		root.visible = value

func update(state: FRONTLINEWeaponViewState) -> void:
	if root == null or mount == null:
		return
	var delta := state.delta
	var run_boost := 1.0 + state.sprint_anim * 0.9
	var bob_factor := 0.20 if state.aiming else 1.0
	var bob_offset := Vector3(
		sin(state.bob_time) * 0.010 * run_boost * bob_factor,
		absf(cos(state.bob_time)) * 0.009 * run_boost * bob_factor,
		0.0
	)
	var breath_offset := Vector3(0.0, sin(state.breathing_time * 1.8) * 0.002, 0.0)
	var kick_offset := Vector3(0.0, 0.020, 0.05) * state.weapon_kick

	var sway_mult := 1.0 - state.aim_blend * 0.90
	var sway_pos := Vector3(-state.look_sway.x * 0.85, state.look_sway.y * 0.85, 0.0) * sway_mult
	var sway_rot := Vector3(state.look_sway.y * 1.8, -state.look_sway.x * 2.2, state.look_sway.x * 1.5) * sway_mult

	var stance_offset := Vector3.ZERO
	if state.stance == 1:
		stance_offset = Vector3(0.0, -0.015, 0.02)
	elif state.stance == 2:
		stance_offset = Vector3(0.0, -0.06, 0.05)

	var sprint_offset := Vector3(0.06, -0.11, 0.04) * state.sprint_anim
	var sprint_rot := Vector3(state.sprint_anim * 0.20, state.sprint_anim * 0.12, -state.sprint_anim * 0.35)
	var landing_offset := Vector3(0.0, -0.05, 0.03) * state.landing_anim
	var landing_rot := Vector3(state.landing_anim * 0.10, 0.0, 0.0)

	var target_pos := base_position.lerp(aim_position, state.aim_blend) + kick_offset + bob_offset + breath_offset + sway_pos + stance_offset + sprint_offset + landing_offset
	root.position = root.position.lerp(target_pos, clampf(delta * 22.0, 0.0, 1.0))

	var strafe_roll := -state.strafe_x * deg_to_rad(2.2) if not state.aiming else 0.0
	var target_rot := Vector3(
		-state.weapon_kick * 0.22 + sway_rot.x + sprint_rot.x + landing_rot.x,
		sway_rot.y + sprint_rot.y,
		sway_rot.z + sprint_rot.z - strafe_roll * 0.40
	)
	_rotation_smooth = _rotation_smooth.lerp(target_rot, clampf(delta * 16.0, 0.0, 1.0))
	root.rotation = _rotation_smooth

	var reload_progress := state.reload_progress if state.is_reloading else 0.0
	mount.rotation.z = sin(reload_progress * PI) * 0.14
	mount.rotation.x = -sin(reload_progress * PI) * 0.08
	if _view_arms != null:
		_view_arms.set_reload_progress(reload_progress)
		_view_arms.update(state.allow_arms and root.visible)

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash != null:
			flash.visible = false

func _build_flash(muzzle_anchor: Node3D) -> void:
	flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.055
	flash_mesh.height = 0.11
	flash.mesh = flash_mesh
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.75, 0.25)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.55, 0.12)
	flash_mat.emission_energy_multiplier = 5.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = flash_mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.visible = false
	flash.name = "MuzzleFlash"
	muzzle_anchor.add_child(flash)
