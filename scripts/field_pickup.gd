extends Area3D

## World weapon drops and reusable ammunition caches.

const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")

var pickup_kind := "weapon"
var weapon_index := 0
var magazine_ammo := 0
var reserve_ammo := 0
var ammo_amount := 0
var respawn_seconds := 0.0
var life_remaining := 50.0
var launch_velocity := Vector3.ZERO
var angular_velocity := Vector3.ZERO
var settled := true
var _hidden_for_respawn := false
var pickup_cooldown := 0.0

func configure_weapon(index: int, clip: int, reserve: int) -> void:
	pickup_kind = "weapon"
	weapon_index = index
	magazine_ammo = maxi(0, clip)
	reserve_ammo = maxi(0, reserve)
	life_remaining = 50.0
	_build_weapon_visual()

func configure_ammo(amount: int, respawn_delay := 65.0) -> void:
	pickup_kind = "ammo"
	ammo_amount = maxi(1, amount)
	respawn_seconds = maxf(0.0, respawn_delay)
	life_remaining = 0.0 if respawn_seconds > 0.0 else 50.0
	add_to_group("field_supply_crates")
	_build_ammo_visual()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	if pickup_kind == "weapon":
		add_to_group("field_weapon_pickups")
	elif pickup_kind == "ammo":
		add_to_group("field_supply_crates")
	var pickup_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.65
	pickup_shape.shape = sphere
	add_child(pickup_shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _hidden_for_respawn:
		return
	if pickup_cooldown > 0.0:
		pickup_cooldown = maxf(0.0, pickup_cooldown - delta)
	if pickup_kind == "weapon":
		life_remaining -= delta
		if life_remaining <= 0.0:
			queue_free()
			return
	if not settled:
		launch_velocity.y -= 14.0 * delta
		var next_pos := position + launch_velocity * delta
		rotation += angular_velocity * delta

		var space := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), global_position + Vector3(0, -0.7, 0))
		query.collision_mask = 1
		query.collide_with_areas = false
		var floor_hit := space.intersect_ray(query)
		var ground_y: float = floor_hit.position.y + 0.18 if not floor_hit.is_empty() else 0.18

		if next_pos.y <= ground_y and launch_velocity.y < 0.0:
			position.y = ground_y
			position.x = next_pos.x
			position.z = next_pos.z
			launch_velocity.y = -launch_velocity.y * 0.18
			launch_velocity.x *= 0.55
			launch_velocity.z *= 0.55
			angular_velocity *= 0.35
			if launch_velocity.length_squared() < 0.08:
				launch_velocity = Vector3.ZERO
				angular_velocity = Vector3.ZERO
				settled = true
		else:
			position = next_pos
	else:
		rotation.y += delta * 0.18

func launch(initial_velocity: Vector3) -> void:
	launch_velocity = initial_velocity
	angular_velocity = Vector3(randf_range(-3.0, 3.0), randf_range(-5.0, 5.0), randf_range(-3.0, 3.0))
	settled = false
	pickup_cooldown = 1.2

func can_collect(actor: Node) -> bool:
	if not is_instance_valid(actor) or pickup_cooldown > 0.0:
		return false
	if pickup_kind == "ammo":
		return actor.has_method("can_take_field_ammo") and bool(actor.call("can_take_field_ammo", ammo_amount))
	return actor.has_method("can_take_weapon_pickup") and bool(actor.call("can_take_weapon_pickup", weapon_index, magazine_ammo, reserve_ammo))

func prompt_text(mobile: bool) -> String:
	if pickup_kind == "ammo":
		return ("ПОДОБРАТЬ: БОЕПРИПАСЫ +%d" % ammo_amount) if mobile else ("F — БОЕПРИПАСЫ +%d" % ammo_amount)
	var names := ["AK-47", "MP-40", "MOSIN-NAGANT", "M1911", "PUMP SHOTGUN", "PPSH-41", "KAR98K", "PANZERFAUST"]
	var weapon_name: String = names[clampi(weapon_index, 0, names.size() - 1)]
	return ("ВЗЯТЬ: %s" % weapon_name) if mobile else ("F — ВЗЯТЬ: %s" % weapon_name)

func collect(actor: Node) -> bool:
	if not can_collect(actor):
		return false
	var collected := false
	if pickup_kind == "ammo":
		collected = int(actor.call("take_field_ammo", ammo_amount)) > 0
	else:
		collected = bool(actor.call("take_weapon_pickup", weapon_index, magazine_ammo, reserve_ammo))
	if not collected:
		return false
	if pickup_kind == "ammo" and respawn_seconds > 0.0:
		_hide_until_respawn()
	else:
		queue_free()
	return true

func _hide_until_respawn() -> void:
	_hidden_for_respawn = true
	visible = false
	set_deferred("monitoring", false)
	get_tree().create_timer(respawn_seconds, false).timeout.connect(func():
		if not is_instance_valid(self):
			return
		_hidden_for_respawn = false
		visible = true
		set_deferred("monitoring", true)
	)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("register_field_pickup"):
		body.call("register_field_pickup", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("unregister_field_pickup"):
		body.call("unregister_field_pickup", self)

func _build_weapon_visual() -> void:
	var names := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]
	var model: Node3D = WEAPON_MESHES.make_weapon(names[clampi(weapon_index, 0, names.size() - 1)])
	if model == null:
		return
	model.name = "DroppedWeapon"
	model.scale = Vector3.ONE * 0.90
	# Кладём оружие плашмя, а не ставим вертикальной «палкой».
	model.rotation = Vector3(0.0, PI * 0.5, 0.0)
	model.position.y = 0.14
	_disable_shadows(model)
	add_child(model)

func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)

func _build_ammo_visual() -> void:
	var crate := MeshInstance3D.new()
	crate.name = "AmmoCrate"
	var crate_mesh := BoxMesh.new()
	crate_mesh.size = Vector3(0.62, 0.38, 0.46)
	crate.mesh = crate_mesh
	crate.position.y = 0.20
	crate.material_override = _make_material(Color(0.24, 0.30, 0.20), 0.78)
	crate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crate)

	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.66, 0.07, 0.50)
	lid.mesh = lid_mesh
	lid.position.y = 0.42
	lid.material_override = _make_material(Color(0.52, 0.43, 0.20), 0.58)
	lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lid)

	var label := Label3D.new()
	label.text = "AMMO"
	label.font_size = 30
	label.pixel_size = 0.008
	label.modulate = Color(0.95, 0.84, 0.46)
	label.outline_size = 5
	label.position = Vector3(0.0, 0.53, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
