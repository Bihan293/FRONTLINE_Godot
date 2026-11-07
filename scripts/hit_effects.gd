extends RefCounted

## Кровь, пулевые отверстия и пыль. Отдельный модуль, чтобы не раздувать
## player.gd и dummy.gd.

static var _blood_tex: Texture2D
static var _hole_tex: Texture2D
static var _blood_mat: StandardMaterial3D
static var _hole_mat: StandardMaterial3D
static var _decals: Array = []
static var _blood_sphere: SphereMesh
static var _dust_sphere: SphereMesh
static var _blood_particle_mat: StandardMaterial3D
static var _dust_particle_mat: StandardMaterial3D

static func spawn_blood(parent: Node, pos: Vector3, normal: Vector3, world_parent: Node = null) -> void:
    if parent == null:
        return
    var mat := _blood_material()
    var decal := MeshInstance3D.new()
    var quad := PlaneMesh.new()
    quad.size = Vector2(0.42, 0.42)
    decal.mesh = quad
    decal.material_override = mat
    decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(decal)
    decal.global_transform = _surface_transform(pos, normal, 0.014)
    _register_decal(decal)

    var pool := MeshInstance3D.new()
    var pool_mesh := PlaneMesh.new()
    pool_mesh.size = Vector2(0.90, 0.90)
    pool.mesh = pool_mesh
    pool.material_override = mat
    pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var pool_parent: Node = world_parent if world_parent != null else parent
    pool_parent.add_child(pool)
    pool.global_transform = _surface_transform(Vector3(pos.x, 0.012, pos.z), Vector3.UP, 0.0)
    _register_decal(pool)

    var particles := _make_particles(parent, pos, normal, false)
    if particles != null:
        particles.amount = 16
        particles.initial_velocity_min = 1.0
        particles.initial_velocity_max = 3.2
        particles.spread = 55.0
        particles.scale_amount_min = 0.02
        particles.scale_amount_max = 0.05
        particles.mesh = _get_blood_sphere()
        particles.emitting = true
        particles.finished.connect(particles.queue_free)

static func spawn_bullet_hole(parent: Node, pos: Vector3, normal: Vector3) -> void:
    if parent == null:
        return
    var mat := _hole_material()
    var decal := MeshInstance3D.new()
    var quad := PlaneMesh.new()
    quad.size = Vector2(0.22, 0.22)
    decal.mesh = quad
    decal.material_override = mat
    decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(decal)
    decal.global_transform = _surface_transform(pos, normal, 0.012)
    _register_decal(decal)

    var particles := _make_particles(parent, pos, normal, true)
    if particles != null:
        particles.amount = 10
        particles.initial_velocity_min = 0.4
        particles.initial_velocity_max = 1.4
        particles.spread = 70.0
        particles.scale_amount_min = 0.01
        particles.scale_amount_max = 0.03
        particles.mesh = _get_dust_sphere()
        particles.emitting = true
        particles.finished.connect(particles.queue_free)

static func _make_particles(parent: Node, pos: Vector3, normal: Vector3, dust: bool) -> CPUParticles3D:
    var p := CPUParticles3D.new()
    p.one_shot = true
    p.explosiveness = 1.0
    p.lifetime = 0.55 if not dust else 0.7
    p.direction = normal
    p.gravity = Vector3(0, -9.8, 0)
    p.scale_amount_min = 0.02
    p.scale_amount_max = 0.04
    p.color = Color(0.35, 0.02, 0.01) if not dust else Color(0.55, 0.55, 0.5)
    parent.add_child(p)
    p.global_position = pos
    return p

static func _surface_transform(pos: Vector3, normal: Vector3, offset: float) -> Transform3D:
    var n := normal.normalized()
    if n.length_squared() < 0.1:
        n = Vector3.UP
    var up := Vector3.UP
    if absf(n.dot(up)) > 0.95:
        up = Vector3.FORWARD
    var x := up.cross(n).normalized()
    var y := n.cross(x).normalized()
    var basis := Basis(x, y, n)
    return Transform3D(basis, pos + n * offset)

static func _register_decal(decal: MeshInstance3D) -> void:
    _decals.append(decal)
    while _decals.size() > 70:
        var old = _decals.pop_front()
        if old != null and is_instance_valid(old):
            old.queue_free()

static func _blood_material() -> StandardMaterial3D:
    if _blood_mat != null:
        return _blood_mat
    _blood_mat = StandardMaterial3D.new()
    _blood_mat.albedo_texture = _get_blood_texture()
    _blood_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _blood_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _blood_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return _blood_mat

static func _hole_material() -> StandardMaterial3D:
    if _hole_mat != null:
        return _hole_mat
    _hole_mat = StandardMaterial3D.new()
    _hole_mat.albedo_texture = _get_hole_texture()
    _hole_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _hole_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _hole_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return _hole_mat

static func _get_blood_texture() -> Texture2D:
    if _blood_tex != null:
        return _blood_tex
    var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var rng := RandomNumberGenerator.new()
    rng.seed = 9173
    for i in range(18):
        _paint_circle(img, rng.randi_range(18, 110), rng.randi_range(18, 110),
            rng.randi_range(5, 18), Color(0.38, 0.015, 0.012, rng.randf_range(0.55, 0.95)))
    for i in range(55):
        _paint_circle(img, rng.randi_range(8, 120), rng.randi_range(8, 120),
            rng.randi_range(1, 4), Color(0.32, 0.01, 0.008, rng.randf_range(0.45, 0.85)))
    _blood_tex = ImageTexture.create_from_image(img)
    return _blood_tex

static func _get_hole_texture() -> Texture2D:
    if _hole_tex != null:
        return _hole_tex
    var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    _paint_circle(img, 32, 32, 10, Color(0.02, 0.02, 0.02, 0.98))
    _paint_circle(img, 32, 32, 17, Color(0.20, 0.19, 0.17, 0.55))
    var rng := RandomNumberGenerator.new()
    rng.seed = 4421
    for i in range(9):
        _paint_circle(img, 32 + rng.randi_range(-22, 22), 32 + rng.randi_range(-22, 22),
            rng.randi_range(1, 3), Color(0.08, 0.07, 0.06, 0.6))
    _hole_tex = ImageTexture.create_from_image(img)
    return _hole_tex

static func _paint_circle(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
    var r2 := radius * radius
    for y in range(maxi(0, cy - radius), mini(img.get_height(), cy + radius + 1)):
        for x in range(maxi(0, cx - radius), mini(img.get_width(), cx + radius + 1)):
            var dx := x - cx
            var dy := y - cy
            if dx * dx + dy * dy <= r2:
                img.set_pixel(x, y, color)

static func _get_blood_sphere() -> SphereMesh:
    if _blood_sphere == null:
        _blood_sphere = SphereMesh.new()
        _blood_sphere.radius = 0.03
        _blood_sphere.height = 0.06
        _blood_sphere.radial_segments = 6
        _blood_sphere.rings = 3
        _blood_particle_mat = StandardMaterial3D.new()
        _blood_particle_mat.albedo_color = Color(0.45, 0.01, 0.008)
        _blood_particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        _blood_sphere.material = _blood_particle_mat
    return _blood_sphere

static func _get_dust_sphere() -> SphereMesh:
    if _dust_sphere == null:
        _dust_sphere = SphereMesh.new()
        _dust_sphere.radius = 0.025
        _dust_sphere.height = 0.05
        _dust_sphere.radial_segments = 5
        _dust_sphere.rings = 3
        _dust_particle_mat = StandardMaterial3D.new()
        _dust_particle_mat.albedo_color = Color(0.55, 0.55, 0.50)
        _dust_particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        _dust_sphere.material = _dust_particle_mat
    return _dust_sphere
