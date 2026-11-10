extends Node3D
class_name FRONTLINEBotVisuals

## Визуал бота: модель, оружие, вспышка, подпись, звук и процедурная анимация.
## Не принимает решений и не стреляет — только показывает состояние бота.

const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")
const BLOCK_RIG_BUILDER = preload("res://scripts/block_rig_builder.gd")
const TACTICAL_GEAR = preload("res://scripts/tactical_gear.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")

const IRON_SCENE := "res://assets/models/soldiers/FRONTLINE_German_Grey_Block_Soldier.glb"
const RED_SCENE := "res://assets/models/soldiers/FRONTLINE_Soviet_Khaki_Block_Soldier.glb"
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")

const WEAPON_IDS := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]

static var _visual_template_cache: Dictionary = {}
static var _weapon_template_cache: Dictionary = {}

var proc: FRONTLINEProceduralSoldier
var _visual: Node3D
var _gun_pivot: Node3D
var _gun_mesh: MeshInstance3D
var _muzzle_node: Node3D
var _muzzle_flash: MeshInstance3D
var _label: Label3D
var _sfx_shot: AudioStreamPlayer3D
var _sfx_reload: AudioStreamPlayer3D
var _flash_time := 0.0
var _label_update_timer := 0.0
var _cached_cam: Camera3D = null
var _audio_env_timer := 0.0
var _audio_indoors := false
var _audio_occluded := false
var _weapon_id := "ak47"
var _team := "IRON LEGION"
var _bot_name := "Soldier"
var _role := "ASSAULT"
var _shout_timer := 0.0
var _reloading := false
var _base_label_color := Color.WHITE

func setup(team: String, bot_name: String, weapon_index: int, role: String) -> void:
	_team = team
	_bot_name = bot_name
	_role = role
	_weapon_id = WEAPON_IDS[clampi(weapon_index, 0, WEAPON_IDS.size() - 1)]
	_visual = Node3D.new()
	_visual.rotation.y = PI
	var path := RED_SCENE if team.to_upper().contains("RED") else IRON_SCENE
	var template: Node3D = _visual_template_cache.get(path)
	if template == null:
		template = _create_visual_template(path, team.to_upper().contains("RED"))
		if template == null:
			return
		_visual_template_cache[path] = template.duplicate() as Node3D
	_visual = template.duplicate() as Node3D
	add_child(_visual)
	if _visual.has_method("set_motion"):
		proc = _visual as FRONTLINEProceduralSoldier
	if GameSettings.quality == 0 and proc != null:
		proc.set_t_pose_arms(false)
		proc.set_aiming(true)
		proc.set_motion(0.0, false)
	_build_weapon()
	_build_label()
	_build_audio()

func _create_visual_template(path: String, is_red: bool) -> Node3D:
	var visual := Node3D.new()
	visual.rotation.y = PI
	var packed = load(path)
	if packed == null:
		push_error("FRONTLINE: cannot load soldier GLB " + path)
		return null
	var model = packed.instantiate()
	TACTICAL_GEAR.add_tactical_loadout(model, is_red, true)
	visual.add_child(model)
	var skeleton := BLOCK_RIG_BUILDER.rig_model(model)
	if skeleton is Skeleton3D:
		BLOCK_RIG_BUILDER.merge_rigged_model(skeleton)
		var skeleton_parent := skeleton.get_parent()
		if skeleton_parent != null and skeleton_parent != visual:
			var skeleton_xform := skeleton.transform
			skeleton_parent.remove_child(skeleton)
			visual.add_child(skeleton)
			skeleton.transform = skeleton_xform
			skeleton_parent.free()
		for mesh_node in visual.find_children("*", "MeshInstance3D", true, false):
			var mesh_inst := mesh_node as MeshInstance3D
			if mesh_inst == null:
				continue
			if GameSettings.quality <= 1:
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh_inst.visibility_range_end = maxf(120.0, GameSettings.view_distance() * 0.9)
		visual.set_script(PROCEDURAL)
	return visual

func _build_weapon() -> void:
	_gun_pivot = Node3D.new()
	_gun_pivot.name = "GunPivot"
	_gun_pivot.position = Vector3(0.16, 1.25, -0.22)
	add_child(_gun_pivot)
	var template: Node3D = _weapon_template_cache.get(_weapon_id)
	if template == null:
		template = WEAPON_MESHES.make_weapon(_weapon_id)
		if template == null:
			push_error("FRONTLINE: cannot build bot weapon " + _weapon_id)
			return
		template.scale = Vector3.ONE * 0.95
		_weapon_template_cache[_weapon_id] = template.duplicate() as Node3D
	var model := template.duplicate() as Node3D
	_gun_pivot.add_child(model)
	_muzzle_node = model.get_node_or_null("Muzzle") as Node3D
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if not meshes.is_empty():
		_gun_mesh = meshes[0] as MeshInstance3D
	if _muzzle_node == null:
		_muzzle_node = Node3D.new()
		_muzzle_node.position = Vector3(0.0, 0.05, -0.6)
		_gun_pivot.add_child(_muzzle_node)
	_build_muzzle_flash()

func _build_muzzle_flash() -> void:
	_muzzle_flash = MeshInstance3D.new()
	var flash_sphere := SphereMesh.new()
	flash_sphere.radius = 0.06
	flash_sphere.height = 0.12
	_muzzle_flash.mesh = flash_sphere
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.78, 0.25)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.6, 0.1)
	flash_mat.emission_energy_multiplier = 4.5
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_muzzle_flash.material_override = flash_mat
	_muzzle_flash.visible = false
	_muzzle_node.add_child(_muzzle_flash)

func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "%s [%s]" % [_bot_name, role_title()]
	_label.position = Vector3(0, 2.15, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 18
	_base_label_color = Color(0.85, 0.35, 0.35) if _team.contains("RED") else Color(0.65, 0.75, 0.85)
	_label.modulate = _base_label_color
	add_child(_label)
	_label_update_timer = randf_range(0.0, 0.25)

func _build_audio() -> void:
	_sfx_shot = AudioStreamPlayer3D.new()
	_sfx_shot.stream = WEAPON_SOUND.get_shot(_weapon_id)
	_sfx_shot.unit_size = 16.0
	_sfx_shot.max_distance = 220.0
	_sfx_shot.max_polyphony = 1
	_sfx_shot.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	_sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
	add_child(_sfx_shot)
	_sfx_reload = AudioStreamPlayer3D.new()
	_sfx_reload.stream = SFX_RELOAD_IN
	_sfx_reload.unit_size = 8.0
	_sfx_reload.max_distance = 45.0
	_sfx_reload.bus = COMBAT_AUDIO.BUS_SFX
	add_child(_sfx_reload)

func role_title() -> String:
	var is_red := _team.contains("RED")
	match _role:
		"MEDIC":
			return "САНИТАР" if is_red else "SANITÄTER"
		"GUNNER":
			return "ПУЛЕМЁТ" if is_red else "MG"
		"SNIPER":
			return "СНАЙПЕР" if is_red else "SCHARF"
		"ANTI_ARMOR":
			return "ПТ" if is_red else "PANZER"
		_:
			return "ШТУРМ" if is_red else "STURM"

func update_motion(speed: float, running: bool, crouching: bool, prone: bool, reloading: bool) -> void:
	if proc == null:
		return
	_reloading = reloading
	proc.set_motion(speed, running)
	proc.set_crouching(crouching)
	if proc.has_method("set_prone"):
		proc.call("set_prone", prone)
	proc.set_reloading(reloading)

func update_effects(delta: float, weapon_view_visible: bool) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0 and _muzzle_flash != null:
			_muzzle_flash.visible = false
			set_firing(false)
	if _gun_pivot != null and weapon_view_visible:
		var reload_tilt := -0.32 if _reloading else 0.0
		_gun_pivot.rotation.z = lerpf(_gun_pivot.rotation.z, reload_tilt, clampf(delta * 8.0, 0.0, 1.0))
	if _shout_timer > 0.0:
		_shout_timer -= delta
		if _shout_timer <= 0.0 and _label != null:
			_label.text = _bot_name
			_label.modulate = _base_label_color
	_update_label(delta)

func _update_label(delta: float) -> void:
	if _label == null:
		return
	_label_update_timer -= delta
	if _label_update_timer > 0.0:
		return
	_label_update_timer = 0.25
	if _cached_cam == null or not is_instance_valid(_cached_cam):
		var vp := get_viewport()
		_cached_cam = vp.get_camera_3d() if vp != null else null
	var label_dist := 999.0
	if _cached_cam != null and is_instance_valid(_cached_cam):
		label_dist = global_position.distance_to(_cached_cam.global_position)
	_label.visible = GameSettings.quality > 0 and label_dist < 36.0

func shout(phrase: String, color: Color) -> void:
	if _label == null:
		return
	_label.text = "[ " + phrase + " ]"
	_label.modulate = color
	_shout_timer = 1.8

func set_look(yaw: float, pitch: float) -> void:
	if proc != null:
		proc.set_look(yaw, pitch)

func set_gun_pitch(pitch: float) -> void:
	if _gun_pivot != null:
		_gun_pivot.rotation.x = pitch

func set_firing(value: bool) -> void:
	if proc != null:
		proc.set_firing(value)

func flash_muzzle() -> void:
	if _muzzle_flash != null:
		_muzzle_flash.visible = true
		_flash_time = 0.045

func add_flinch(amount: float) -> void:
	if proc != null:
		proc.add_flinch(amount)

func set_ragdoll(enabled: bool, direction: Vector3, headshot: bool) -> void:
	if proc != null:
		proc.set_ragdoll(enabled, direction, headshot)

func muzzle_position() -> Vector3:
	return _muzzle_node.global_position if _muzzle_node != null else global_position + Vector3(0, 1.3, 0)

func gun_position() -> Vector3:
	return _gun_pivot.global_position if _gun_pivot != null else global_position + Vector3(0.0, 1.25, 0.0)

func weapon_drop_position() -> Vector3:
	return _gun_pivot.global_position if _gun_pivot != null else global_position

func mark_dead() -> void:
	if _label != null:
		_label.text = "КИА"
		_label.modulate = Color(0.9, 0.2, 0.2, 0.8)
		_label.visible = false

func weapon_mesh() -> Mesh:
	return _gun_mesh.mesh if _gun_mesh != null else null

func hide_weapon() -> void:
	if _gun_pivot != null:
		_gun_pivot.visible = false

func play_shot(from: Vector3) -> void:
	if _sfx_shot == null:
		return
	var listener_pos := COMBAT_AUDIO.get_listener_position(get_tree())
	var profile: Dictionary = COMBAT_AUDIO.WEAPON_PROFILES.get(_weapon_id, {})
	var max_dist := float(profile.get("max_dist", 220.0))
	if from.distance_squared_to(listener_pos) > max_dist * max_dist:
		return
	_sfx_shot.unit_size = float(profile.get("unit_size", 16.0))
	_sfx_shot.max_distance = max_dist
	_sfx_shot.pitch_scale = randf_range(0.96, 1.04)
	_sfx_shot.volume_db = float(profile.get("vol", -2.0))
	_audio_env_timer -= get_physics_process_delta_time()
	if _audio_env_timer <= 0.0:
		_audio_env_timer = 0.25
		var world_3d := get_world_3d()
		_audio_indoors = COMBAT_AUDIO.is_indoors(world_3d, from)
		_audio_occluded = (not _audio_indoors) and COMBAT_AUDIO.check_occlusion(world_3d, from, listener_pos)
	if _audio_indoors:
		_sfx_shot.bus = COMBAT_AUDIO.BUS_INDOOR_REVERB
		_sfx_shot.attenuation_filter_cutoff_hz = 18000.0
		_sfx_shot.attenuation_filter_db = 0.0
	elif _audio_occluded:
		_sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_OCCLUDED
		_sfx_shot.attenuation_filter_cutoff_hz = 1250.0
		_sfx_shot.attenuation_filter_db = -8.0
	else:
		_sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
		_sfx_shot.attenuation_filter_cutoff_hz = 20500.0
		_sfx_shot.attenuation_filter_db = 0.0
	_sfx_shot.play()

func play_reload() -> void:
	if _sfx_reload != null:
		_sfx_reload.play()
