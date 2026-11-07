extends CharacterBody3D
class_name FRONTLINERadioDrone

## Камикадзе FPV-дрон на проводном управлении (TASK-0008).
## Запускается радистом с пульта, летит на физической тяге,
## соединён гибким кабелем с оператором (предел длины по масштабу карты)
## и детонирует кумулятивным зарядом при столкновении или по команде.

signal detonated(pos: Vector3)
signal returned()

const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const SFX_EXPLODE = preload("res://assets/audio/explosion.wav")

const BLAST_DAMAGE := 240.0
const BLAST_RADIUS := 9.5
const DRONE_SPEED := 18.5
const CLIMB_SPEED := 7.0
const TURN_SPEED := 3.2
const ROTOR_SPEED := 45.0

var operator: CharacterBody3D
var operator_name := "Player"
var operator_team := "IRON LEGION"
var max_tether := 150.0
var battery_lifetime := 45.0
var flight_time := 0.0
var is_exploding := false

var move_input := Vector2.ZERO
var vertical_input := 0.0
var yaw_input := 0.0
var drone_yaw := 0.0
var drone_pitch := 0.0

var camera: Camera3D
var _feed_viewport: SubViewport
var _feed_camera: Camera3D
var _feed_refresh_timer := 0.0
var _model: Node3D
var _collision_shape: CollisionShape3D
var _rotors: Array[Node3D] = []
var _tether_mesh: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _osd_label: Label
var _osd_canvas: CanvasLayer

func launch(start_pos: Vector3, initial_yaw: float, op: CharacterBody3D, tether_len := 150.0) -> void:
	operator = op
	operator_name = "Player"
	operator_team = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	max_tether = maxf(30.0, tether_len)
	if _collision_shape != null and is_instance_valid(operator):
		add_collision_exception_with(operator)
	drone_yaw = initial_yaw
	global_position = start_pos
	rotation.y = initial_yaw
	velocity = -transform.basis.z * 4.0 + Vector3.UP * 2.0
	if camera != null:
		camera.current = true

func _ready() -> void:
	add_to_group("radio_drones")
	collision_layer = 1 << 0
	collision_mask = 1 | 2 | 4 # Мир, хитбоксы, боты
	_build_model()
	_build_collision()
	_build_camera()
	_build_tether_renderer()
	_build_osd()

func _exit_tree() -> void:
	if _osd_canvas != null and is_instance_valid(_osd_canvas):
		_osd_canvas.queue_free()

func _physics_process(delta: float) -> void:
	if is_exploding:
		return

	if operator == null or not is_instance_valid(operator) or bool(operator.get("is_dead")):
		return_to_operator()
		return
	var world_state := get_parent()
	if world_state != null and "is_game_over" in world_state and bool(world_state.get("is_game_over")):
		return_to_operator()
		return

	flight_time += delta
	if flight_time >= battery_lifetime:
		detonate(global_position)
		return

	# Вращение пропеллеров
	for r in _rotors:
		if is_instance_valid(r):
			r.rotation.y += ROTOR_SPEED * delta

	# Управление рысканием и дифферентом
	drone_yaw -= yaw_input * TURN_SPEED * delta
	rotation.y = drone_yaw
	if camera != null:
		camera.rotation.x = clampf(deg_to_rad(-8.0) + drone_pitch, deg_to_rad(-65.0), deg_to_rad(55.0))

	# Направление тяги квадрокоптера
	var forward := -transform.basis.z
	var right := transform.basis.x
	var target_vel := forward * (-move_input.y * DRONE_SPEED) + right * (move_input.x * DRONE_SPEED * 0.75)
	target_vel.y = vertical_input * CLIMB_SPEED

	# Инерция полёта
	velocity = velocity.lerp(target_vel, clampf(delta * 5.5, 0.0, 1.0))

	# Проверка натяжения кабеля
	var op_pos := _operator_anchor_position()
	var tether_vector := global_position - op_pos
	var current_dist := tether_vector.length()
	if current_dist >= max_tether:
		# Ограничение кабелем: нельзя улететь дальше предельной длины
		var outward_speed := velocity.dot(tether_vector.normalized())
		if outward_speed > 0.0:
			velocity -= tether_vector.normalized() * outward_speed
		global_position = op_pos + tether_vector.normalized() * max_tether

	# Наклон корпуса в сторону движения (реалистичная динамика Dummy War)
	if _model != null:
		var target_roll := -move_input.x * deg_to_rad(28.0)
		var target_tilt := move_input.y * deg_to_rad(24.0)
		_model.rotation.z = lerpf(_model.rotation.z, target_roll, delta * 9.0)
		_model.rotation.x = lerpf(_model.rotation.x, target_tilt, delta * 9.0)
	if _feed_camera != null and camera != null:
		_feed_camera.global_transform = camera.global_transform
		_feed_refresh_timer -= delta
		if _feed_refresh_timer <= 0.0:
			_feed_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			_feed_refresh_timer = 1.0 / 24.0

	# Физическое перемещение с проверкой коллизий
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		detonate(collision.get_position())
		return
	var after_move_vector := global_position - op_pos
	if after_move_vector.length() > max_tether:
		global_position = op_pos + after_move_vector.normalized() * max_tether
		var after_move_outward := velocity.dot(after_move_vector.normalized())
		if after_move_outward > 0.0:
			velocity -= after_move_vector.normalized() * after_move_outward

	# Обновление отрисовки провода и OSD
	_update_tether(op_pos)
	_update_osd(global_position.distance_to(op_pos))

func _operator_anchor_position() -> Vector3:
	if operator != null and is_instance_valid(operator):
		var anchor = operator.get("drone_controller_anchor")
		if anchor is Node3D and is_instance_valid(anchor):
			return (anchor as Node3D).global_position
		return operator.global_position + operator.transform.basis * Vector3(0.30, 1.45, -0.48)
	return global_position

func detonate(pos: Vector3) -> void:
	if is_exploding:
		return
	is_exploding = true

	var world := get_parent()
	if world != null:
		_spawn_explosion_visuals(world, pos)
		_apply_blast_damage(pos)
		_play_explosion(world, pos)

	detonated.emit(pos)
	if _osd_canvas != null and is_instance_valid(_osd_canvas):
		_osd_canvas.queue_free()
	queue_free()

func return_to_operator() -> void:
	if is_exploding:
		return
	returned.emit()
	if _osd_canvas != null and is_instance_valid(_osd_canvas):
		_osd_canvas.queue_free()
	queue_free()

func _play_explosion(world: Node, pos: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = SFX_EXPLODE
	player.volume_db = -3.0
	player.max_distance = 120.0
	player.unit_size = 10.0
	player.position = pos
	world.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _apply_blast_damage(pos: Vector3) -> void:
	# Урон ботам с защитой от огня по своим
	var bots := get_tree().get_nodes_in_group("bots")
	for b in bots:
		if b != null and is_instance_valid(b) and not bool(b.get("is_dead")):
			var b_team: String = str(b.get("team_name"))
			if b_team != "" and b_team == operator_team:
				continue # Дружественный огонь отключен
			var dist := pos.distance_to((b as Node3D).global_position)
			if dist <= BLAST_RADIUS:
				var falloff := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(BLAST_DAMAGE * falloff * falloff))
				var was_dead: bool = bool(b.get("is_dead"))
				b.call("receive_hit", dmg, pos, "chest", operator_name + " [DRONE]")
				if not was_dead and bool(b.get("is_dead")):
					var world_node := get_parent()
					if world_node != null and world_node.has_method("add_kill"):
						world_node.call("add_kill")

	# Урон манекенам на Полигоне
	for d in get_tree().get_nodes_in_group("training_dummy"):
		if d != null and is_instance_valid(d) and d.has_method("receive_hit"):
			var dist := pos.distance_to(d.global_position)
			if dist <= BLAST_RADIUS:
				var falloff := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(BLAST_DAMAGE * falloff * falloff))
				d.receive_hit(dmg, pos, "chest", operator_name + " [DRONE]")

	# Взрыв бочек в радиусе поражения (TASK-0008)
	for barrel in get_tree().get_nodes_in_group("explosive_barrels"):
		if barrel != null and is_instance_valid(barrel):
			var dist := pos.distance_to(barrel.global_position)
			if dist <= BLAST_RADIUS and not bool(barrel.get("is_burning")):
				if barrel.has_method("receive_hit"):
					var barrel_dmg := int(round(BLAST_DAMAGE * (1.0 - dist / BLAST_RADIUS)))
					barrel.call("receive_hit", barrel_dmg, pos, "barrel", operator_name + " [DRONE]")

func _spawn_explosion_visuals(world: Node, pos: Vector3) -> void:
	# Вспышка и частицы взрыва
	var flash := OmniLight3D.new()
	flash.position = pos + Vector3.UP * 0.5
	flash.light_color = Color(1.0, 0.65, 0.25)
	flash.light_energy = 9.0
	flash.omni_range = 14.0
	world.add_child(flash)
	get_tree().create_timer(0.12, false).timeout.connect(flash.queue_free)

	# Сфера огненного шара
	var sphere := MeshInstance3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = 2.4
	smesh.height = 4.8
	sphere.mesh = smesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.45, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.35, 0.05)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material_override = mat
	sphere.position = pos
	world.add_child(sphere)

	var tween := sphere.create_tween()
	tween.tween_property(sphere, "scale", Vector3(1.8, 1.8, 1.8), 0.22)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.tween_callback(sphere.queue_free)

func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "DroneModel"
	add_child(_model)

	# Центральный фюзеляж дрона
	var body_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.24, 0.07, 0.28)
	body_mesh.mesh = box
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.12, 0.14, 0.14)
	body_mat.metallic = 0.5
	body_mat.roughness = 0.6
	body_mesh.material_override = body_mat
	_model.add_child(body_mesh)

	# Кумулятивная боевая часть снизу (боевой заряд)
	var warhead := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = 0.22
	warhead.mesh = cyl
	warhead.rotation.x = PI * 0.5
	warhead.position = Vector3(0.0, -0.055, 0.0)
	var warhead_mat := StandardMaterial3D.new()
	warhead_mat.albedo_color = Color(0.28, 0.35, 0.20)
	warhead.material_override = warhead_mat
	_model.add_child(warhead)

	# 4 луча с роторами
	var arm_offsets := [
		Vector3(-0.16, 0.02, -0.16),
		Vector3(0.16, 0.02, -0.16),
		Vector3(-0.16, 0.02, 0.16),
		Vector3(0.16, 0.02, 0.16)
	]
	for idx in range(arm_offsets.size()):
		var offset: Vector3 = arm_offsets[idx]
		var arm := MeshInstance3D.new()
		var arm_box := BoxMesh.new()
		arm_box.size = Vector3(0.025, 0.015, offset.length() * 1.8)
		arm.mesh = arm_box
		arm.look_at_from_position(offset * 0.5, offset, Vector3.UP)
		arm.material_override = body_mat
		_model.add_child(arm)

		# Моторчик и пропеллер
		var rotor_hub := Node3D.new()
		rotor_hub.position = offset
		_model.add_child(rotor_hub)
		_rotors.append(rotor_hub)

		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.22, 0.005, 0.025)
		blade.mesh = blade_mesh
		var blade_mat := StandardMaterial3D.new()
		blade_mat.albedo_color = Color(0.85, 0.85, 0.85, 0.6)
		blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		blade.material_override = blade_mat
		rotor_hub.add_child(blade)

		# Габаритные огни на передних лучах
		if offset.z < 0:
			var light := OmniLight3D.new()
			light.light_color = Color(0.1, 1.0, 0.2) if offset.x < 0 else Color(1.0, 0.1, 0.1)
			light.light_energy = 1.2
			light.omni_range = 1.5
			light.position = offset + Vector3(0, 0.03, 0)
			_model.add_child(light)

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "DroneCollision"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.19
	_collision_shape.shape = sphere
	add_child(_collision_shape)
	if operator != null and is_instance_valid(operator):
		add_collision_exception_with(operator)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "DroneCamera"
	camera.position = Vector3(0.0, 0.06, -0.23)
	camera.rotation.x = deg_to_rad(-12.0) # Лёгкий наклон вниз для обзора поля боя
	camera.fov = 85.0
	add_child(camera)
	_feed_viewport = SubViewport.new()
	_feed_viewport.name = "ControllerScreenFeed"
	_feed_viewport.size = Vector2i(480, 270) if not OS.has_feature("mobile") else Vector2i(384, 216)
	_feed_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_feed_viewport.world_3d = get_world_3d()
	add_child(_feed_viewport)
	_feed_camera = Camera3D.new()
	_feed_camera.name = "FeedCamera"
	_feed_camera.fov = camera.fov
	_feed_viewport.add_child(_feed_camera)
	_feed_camera.current = true
	_feed_camera.global_transform = camera.global_transform
	_feed_refresh_timer = 0.0
	_feed_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _build_tether_renderer() -> void:
	_tether_mesh = MeshInstance3D.new()
	_tether_mesh.name = "TetherLine"
	_immediate_mesh = ImmediateMesh.new()
	_tether_mesh.mesh = _immediate_mesh
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.15, 0.16, 0.18)
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tether_mesh.material_override = line_mat
	add_child(_tether_mesh)

func _update_tether(op_pos: Vector3) -> void:
	if _immediate_mesh == null:
		return
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Точка на дроне (хвост фюзеляжа) в глобальных координатах
	var drone_rear := global_position + transform.basis.z * 0.15
	# Провод слегка провисает в середине (дуга из 4 сегментов)
	var mid_point := (drone_rear + op_pos) * 0.5 - Vector3(0, 0.45, 0)
	var points := [
		drone_rear,
		(drone_rear + mid_point) * 0.5 - Vector3(0, 0.2, 0),
		mid_point,
		(mid_point + op_pos) * 0.5 - Vector3(0, 0.2, 0),
		op_pos
	]
	for i in range(points.size() - 1):
		# Локальные координаты относительно tether_mesh
		var p1 := to_local(points[i])
		var p2 := to_local(points[i + 1])
		_immediate_mesh.surface_add_vertex(p1)
		_immediate_mesh.surface_add_vertex(p2)
	_immediate_mesh.surface_end()

func _build_osd() -> void:
	_osd_canvas = CanvasLayer.new()
	_osd_canvas.layer = 15
	add_child(_osd_canvas)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_osd_canvas.add_child(root)
	var live_screen := TextureRect.new()
	live_screen.name = "LiveDroneScreen"
	live_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	live_screen.texture = _feed_viewport.get_texture()
	live_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	live_screen.stretch_mode = TextureRect.STRETCH_SCALE
	live_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(live_screen)

	# FPV виньетка и помехи
	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.offset_left = 32
	border.offset_top = 24
	border.offset_right = -32
	border.offset_bottom = -24
	border.border_color = Color(0.2, 0.85, 0.3, 0.5)
	border.border_width = 1.5
	border.editor_only = false
	root.add_child(border)

	# Центральное перекрестие FPV
	var center_box := CenterContainer.new()
	center_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center_box)

	var cross_lbl := Label.new()
	cross_lbl.text = "[   +   ]"
	cross_lbl.add_theme_font_size_override("font_size", 22)
	cross_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 0.85))
	center_box.add_child(cross_lbl)

	# Телеметрия (Батарея, Дистанция кабеля, Скорость)
	_osd_label = Label.new()
	_osd_label.offset_left = 48
	_osd_label.offset_top = 36
	_osd_label.add_theme_font_size_override("font_size", 16)
	_osd_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.35, 0.95))
	root.add_child(_osd_label)

	# Инструкция возврата
	var hint := Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_bottom = -36
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "FPV: WASD/ЛЕВЫЙ СТИК — ПОЛЁТ • МЫШЬ/СВАЙП — КУРС • ПРОБЕЛ/CTRL — ВЫСОТА • ЛКМ/ОГОНЬ — ПОДРЫВ • V/ВОЗВРАТ — НАЗАД"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3, 0.9))
	root.add_child(hint)

func _update_osd(dist: float) -> void:
	if _osd_label == null:
		return
	var rem_bat := maxf(0.0, battery_lifetime - flight_time)
	var speed_kmh := velocity.length() * 3.6
	var tether_pct := clampf(dist / max_tether, 0.0, 1.0) * 100.0
	var warn := "  [ПРЕДЕЛ КАБЕЛЯ!]" if dist >= max_tether - 2.0 else ""
	_osd_label.text = "● FPV TETHER DRONE-1\nКАБЕЛЬ: %5.1f / %3.0f м (%2.0f%%)%s\nСКОРОСТЬ: %4.1f км/ч   АКБ: %4.1f с\nСИГНАЛ: 100%% ПРОВОДНОЙ" % [
		dist, max_tether, tether_pct, warn,
		speed_kmh, rem_bat
	]

