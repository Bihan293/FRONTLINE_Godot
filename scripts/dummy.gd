extends Node3D

var team_color := Color(0.28,0.3,0.32)
var dummy_name := "TARGET"
var health := 100.0
var _hit_material: StandardMaterial3D

func _ready() -> void:
    _hit_material = StandardMaterial3D.new()
    _hit_material.albedo_color = team_color
    _hit_material.roughness = 1.0
    _part(Vector3(0,1.55,0), Vector3(0.48,0.48,0.42), Color(0.72,0.62,0.5), "head")
    _part(Vector3(0,0.92,0), Vector3(0.72,0.9,0.38), team_color, "chest")
    _part(Vector3(0,0.38,0), Vector3(0.68,0.22,0.36), team_color.darkened(0.12), "stomach")
    _part(Vector3(-0.57,0.98,0), Vector3(0.28,0.85,0.28), team_color, "arm")
    _part(Vector3(0.57,0.98,0), Vector3(0.28,0.85,0.28), team_color, "arm")
    _part(Vector3(-0.2,-0.28,0), Vector3(0.28,0.95,0.3), team_color.darkened(0.08), "leg")
    _part(Vector3(0.2,-0.28,0), Vector3(0.28,0.95,0.3), team_color.darkened(0.08), "leg")
    # T-pose arms extended horizontally
    _part(Vector3(-0.92,1.25,0), Vector3(0.62,0.22,0.24), team_color, "arm")
    _part(Vector3(0.92,1.25,0), Vector3(0.62,0.22,0.24), team_color, "arm")
    var label := Label3D.new()
    label.text = dummy_name
    label.position = Vector3(0,2.05,0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 32
    add_child(label)

func _part(pos: Vector3, size: Vector3, color: Color, region: String) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.add_to_group("damageable")
    body.set_meta("region", region)
    body.set_meta("owner_dummy", self)
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 1.0
    visual.material_override = mat
    body.add_child(visual)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    add_child(body)

func receive_hit(region: String) -> int:
    var damage := 15
    match region:
        "head": damage = 100
        "chest": damage = 45
        "stomach": damage = 35
        "arm": damage = 15
        "leg": damage = 20
    health -= damage
    if health <= 0:
        health = 100.0
        # Reset as a respawning paper target for repeated weapon tests.
    return damage
