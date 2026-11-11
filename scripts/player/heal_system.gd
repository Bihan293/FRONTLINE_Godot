extends RefCounted
class_name FRONTLINEPlayerHealing

## Лечение себя и союзников: аптечки, удержание, анимация бинта и прогресс.
## Компонент владеет состоянием лечения, игрок остаётся телом и HUD-владельцем.

const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")
const WORLD_LAYER_MASK := 1 << 0
const HEAL_DURATION := 2.2
const SELF_HEAL := 45.0
const ALLY_HEAL := 40.0
const ALLY_RANGE := 6.5

var medkits := 2
var is_healing := false
var heal_timer := 0.0
var heal_target: Node3D
var heal_hold := false
var heal_anim_time := 0.0
var heal_view_root: Node3D
var heal_bandage: Node3D

var _player: CharacterBody3D
var _camera: Camera3D
var _max_health := 100.0

func setup(player: CharacterBody3D, camera: Camera3D, max_health: float) -> void:
	_player = player
	_camera = camera
	_max_health = max_health

func build_view() -> void:
	if heal_view_root != null and is_instance_valid(heal_view_root):
		return
	var root := Node3D.new()
	root.name = "HealView"
	root.visible = false
	_camera.add_child(root)

	var sleeve := StandardMaterial3D.new()
	sleeve.albedo_color = Color(0.24, 0.25, 0.19)
	sleeve.roughness = 0.95
	var glove_mat := StandardMaterial3D.new()
	glove_mat.albedo_color = Color(0.33, 0.26, 0.19)
	glove_mat.roughness = 0.9

	# Предплечье, которое перевязываем.
	var forearm := MeshInstance3D.new()
	var f_mesh := CylinderMesh.new()
	f_mesh.top_radius = 0.044
	f_mesh.bottom_radius = 0.052
	f_mesh.height = 0.44
	f_mesh.radial_segments = 8
	forearm.mesh = f_mesh
	forearm.material_override = sleeve
	forearm.position = Vector3(-0.16, -0.24, -0.42)
	forearm.rotation = Vector3(deg_to_rad(74.0), 0.0, deg_to_rad(-24.0))
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(forearm)

	# Рулон бинта (двигается вокруг предплечья).
	var bandage := Node3D.new()
	bandage.name = "Bandage"
	var roll := MeshInstance3D.new()
	var r_mesh := CylinderMesh.new()
	r_mesh.top_radius = 0.056
	r_mesh.bottom_radius = 0.056
	r_mesh.height = 0.095
	r_mesh.radial_segments = 10
	roll.mesh = r_mesh
	var bandage_mat := StandardMaterial3D.new()
	bandage_mat.albedo_color = Color(0.88, 0.85, 0.74)
	bandage_mat.roughness = 1.0
	roll.material_override = bandage_mat
	roll.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	roll.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bandage.add_child(roll)
	bandage.position = Vector3(0.02, -0.18, -0.42)
	root.add_child(bandage)
	heal_bandage = bandage

	# Кисть, держащая бинт.
	var hand := MeshInstance3D.new()
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(0.06, 0.034, 0.095)
	hand.mesh = h_mesh
	hand.material_override = glove_mat
	hand.position = Vector3(0.09, -0.20, -0.40)
	hand.rotation = Vector3(deg_to_rad(18.0), deg_to_rad(-12.0), 0.0)
	hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hand)

	heal_view_root = root

func use() -> void:
	if medkits <= 0 or bool(_player.get("is_dead")) or is_healing:
		return
	heal_target = null
	if str(_player.get("player_role")) == "MEDIC":
		var player_team := MatchState.player_team
		var nearest_dist := ALLY_RANGE
		for bot in _player.get_tree().get_nodes_in_group("bots"):
			if bot == null or not is_instance_valid(bot) or bool(bot.get("is_dead")):
				continue
			if str(bot.get("team_name")) != player_team or not ("health" in bot):
				continue
			var distance := _player.global_position.distance_to((bot as Node3D).global_position)
			if float(bot.get("health")) < _max_health and distance < nearest_dist:
				nearest_dist = distance
				heal_target = bot as Node3D
		if heal_target != null:
			var start := _player.global_position + Vector3.UP * 1.1
			var finish := heal_target.global_position + Vector3.UP * 0.9
			var query := PhysicsRayQueryParameters3D.create(start, finish)
			query.collision_mask = WORLD_LAYER_MASK
			query.exclude = [_player.get_rid()]
			if not _player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				heal_target = null
	if heal_target == null and float(_player.get("health")) >= _max_health:
		return
	is_healing = true
	heal_hold = true
	heal_anim_time = 0.0
	heal_timer = HEAL_DURATION
	_player.call("_play_sfx", _player.get("sfx_reload_in"), SFX_RELOAD_IN, -4.0, 1.0)
	_player.call("_refresh_equipment")

func release_hold() -> void:
	heal_hold = false
	if is_healing:
		cancel()

func cancel() -> void:
	if not is_healing:
		return
	is_healing = false
	heal_target = null
	heal_timer = 0.0
	heal_hold = false
	_finish_visual()
	_player.call("_refresh_equipment")

## Сброс перед респавном: без обновления HUD и снаряжения.
func reset() -> void:
	is_healing = false
	heal_target = null
	heal_timer = 0.0
	heal_hold = false
	heal_anim_time = 0.0
	if heal_view_root != null and is_instance_valid(heal_view_root):
		heal_view_root.visible = false

func tick(delta: float) -> void:
	if not is_healing:
		return
	var moving_to_cancel := Vector2(_player.get("mobile_move")).length() > 0.15 or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D)
	if moving_to_cancel or not heal_hold:
		cancel()
		return
	_update_visual(delta)
	heal_timer -= delta
	if heal_timer > 0.0:
		return

	if heal_target != null and is_instance_valid(heal_target) and not bool(heal_target.get("is_dead")):
		heal_target.set("health", minf(_max_health, float(heal_target.get("health")) + ALLY_HEAL))
	else:
		_player.set("health", minf(_max_health, float(_player.get("health")) + SELF_HEAL))
	is_healing = false
	heal_target = null
	medkits = maxi(0, medkits - 1)
	_finish_visual()
	_player.call("_refresh_health")
	_player.call("_refresh_equipment")
	_player.call("_play_sfx", _player.get("sfx_reload_in"), SFX_RELOAD_IN, -2.0, 1.1)

func _update_visual(delta: float) -> void:
	heal_anim_time += delta
	if heal_view_root != null and is_instance_valid(heal_view_root):
		heal_view_root.visible = true
	var weapon_root: Node3D = _player.get("weapon_root")
	if weapon_root != null:
		weapon_root.visible = false
	if heal_bandage != null and is_instance_valid(heal_bandage):
		var t := heal_anim_time
		# Бинт наматывается по кругу вокруг предплечья.
		heal_bandage.position = Vector3(
			0.03 + sin(t * 7.5) * 0.055,
			-0.185 + cos(t * 6.0) * 0.05,
			-0.42 + cos(t * 7.5) * 0.02
		)
		heal_bandage.rotation = Vector3(t * 2.4, t * 1.7, t * 2.1)
	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("set_heal_progress", clampf(1.0 - heal_timer / HEAL_DURATION, 0.0, 1.0))

func _finish_visual() -> void:
	heal_anim_time = 0.0
	if heal_view_root != null and is_instance_valid(heal_view_root):
		heal_view_root.visible = false
	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("set_heal_progress", -1.0)
	var weapon_root: Node3D = _player.get("weapon_root")
	var grenades = _player.get("_grenades")
	var grenade_busy := grenades != null and bool(grenades.call("is_busy"))
	if weapon_root != null and not bool(_player.get("is_dead")) and not bool(_player.get("is_shovel_equipped")) and not grenade_busy:
		weapon_root.visible = true
