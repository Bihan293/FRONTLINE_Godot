extends RefCounted
class_name FRONTLINEBotBody

## Тело бота: капсула, визуал, хитбоксы и кэш RID для исключения своих попаданий.
## Компонент строит узлы, бот владеет ИИ и состоянием.

const HITBOX_LAYER_MASK := 1 << 1

var visuals: FRONTLINEBotVisuals
var hitboxes: Array[Area3D] = []
var self_rids: Array[RID] = []

var _bot: CharacterBody3D

func build(bot: CharacterBody3D, team_name: String, soldier_name: String, weapon_index: int, role: String) -> void:
	_bot = bot
	_build_collision()
	_build_visuals(team_name, soldier_name, weapon_index, role)
	_build_hitboxes()
	rebuild_self_rids()

func rebuild_self_rids() -> void:
	self_rids.clear()
	self_rids.append(_bot.get_rid())
	for hitbox in hitboxes:
		if is_instance_valid(hitbox):
			self_rids.append(hitbox.get_rid())

func projectile_rids() -> Array[RID]:
	if self_rids.is_empty():
		rebuild_self_rids()
	return self_rids

func disable_hitboxes() -> void:
	for hitbox in hitboxes:
		if is_instance_valid(hitbox):
			hitbox.remove_from_group("damageable")
			hitbox.collision_layer = 0

func _build_collision() -> void:
	var body_collision := CollisionShape3D.new()
	body_collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	body_collision.shape = capsule
	body_collision.position.y = capsule.height * 0.5
	_bot.add_child(body_collision)

func _build_visuals(team_name: String, soldier_name: String, weapon_index: int, role: String) -> void:
	visuals = FRONTLINEBotVisuals.new()
	visuals.name = "BotVisuals"
	_bot.add_child(visuals)
	visuals.setup(team_name, soldier_name, weapon_index, role)

func _build_hitboxes() -> void:
	var shape_head := BoxShape3D.new()
	shape_head.size = Vector3(0.38, 0.38, 0.38)
	_add_hitbox("head", Vector3(0, 1.76, 0), shape_head)

	var shape_torso := BoxShape3D.new()
	shape_torso.size = Vector3(0.55, 0.70, 0.36)
	_add_hitbox("chest", Vector3(0, 1.20, 0), shape_torso)

	var shape_legs := BoxShape3D.new()
	shape_legs.size = Vector3(0.52, 0.85, 0.38)
	_add_hitbox("leg", Vector3(0, 0.42, 0), shape_legs)

func _add_hitbox(region: String, local_pos: Vector3, shape: Shape3D) -> void:
	var area := Area3D.new()
	area.collision_layer = HITBOX_LAYER_MASK
	area.collision_mask = 0
	area.set_meta("owner_actor", _bot)
	area.set_meta("region", region)
	area.add_to_group("damageable")
	var collision := CollisionShape3D.new()
	collision.shape = shape
	area.add_child(collision)
	area.position = local_pos
	visuals.add_child(area)
	hitboxes.append(area)
