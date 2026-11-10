extends CanvasLayer
class_name FRONTLINEPlayerHUD

## Весь HUD игрока: здоровье, патроны, компас-кроссхейр, урон, смерть, пауза.
## Не знает про оружие и ИИ — только отображает переданные значения.

signal pause_resumed
signal deploy_requested

const CROSSHAIR = preload("res://scripts/crosshair.gd")
const PAUSE_MENU = preload("res://scripts/pause_menu.gd")

var blood_overlay: ColorRect
var bodycam_vignette: ColorRect
var bodycam_rec_dot: Label
var bodycam_osd_label: Label
var crosshair
var health_label: Label
var health_bar: ProgressBar
var heal_progress_bar: ProgressBar
var ammo_label: Label
var equip_label: Label
var pickup_label: Label
var damage_label: Label
var death_screen: Control
var death_info_label: Label
var pause_menu: FRONTLINEPauseMenu

var _damage_time := 0.0
var _blood_timer := 0.0
var _bodycam_time := 0.0
var _osd_timer := 0.0

func setup(parent: Node) -> void:
	layer = 10
	_build_ui()
	_build_pause_menu(parent)

func _build_ui() -> void:
	blood_overlay = ColorRect.new()
	blood_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blood_overlay.color = Color(0.7, 0.0, 0.0, 0.0)
	blood_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blood_overlay)

	# Мягкая процедурная виньетка оптической линзы нательной камеры (Bodycam Vignette)
	bodycam_vignette = ColorRect.new()
	bodycam_vignette.name = "BodycamVignette"
	bodycam_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bodycam_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vign_mat := ShaderMaterial.new()
	var vign_shader := Shader.new()
	vign_shader.code = """
shader_type canvas_item;
void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float vig = smoothstep(0.42, 0.74, dist);
    COLOR = vec4(0.01, 0.02, 0.03, vig * 0.45);
}
"""
	vign_mat.shader = vign_shader
	bodycam_vignette.material = vign_mat
	add_child(bodycam_vignette)

	# Нательный OSD бодикамеры (Bodycam OSD): правый верхний угол левее кнопки паузы
	var bodycam_container := VBoxContainer.new()
	bodycam_container.name = "BodycamOSD"
	bodycam_container.anchor_left = 1.0
	bodycam_container.anchor_right = 1.0
	bodycam_container.offset_left = -440.0
	bodycam_container.offset_right = -120.0
	bodycam_container.offset_top = 16.0
	bodycam_container.offset_bottom = 64.0
	bodycam_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bodycam_container.add_theme_constant_override("separation", 2)
	add_child(bodycam_container)

	var line1 := HBoxContainer.new()
	line1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bodycam_container.add_child(line1)

	var cam_title := Label.new()
	cam_title.text = "AXON BODY 4   "
	cam_title.add_theme_font_size_override("font_size", 14)
	cam_title.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 0.88))
	cam_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	cam_title.add_theme_constant_override("shadow_offset_x", 2)
	cam_title.add_theme_constant_override("shadow_offset_y", 2)
	cam_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line1.add_child(cam_title)

	bodycam_rec_dot = Label.new()
	bodycam_rec_dot.text = "● REC"
	bodycam_rec_dot.add_theme_font_size_override("font_size", 14)
	bodycam_rec_dot.add_theme_color_override("font_color", Color(1.0, 0.18, 0.15, 1.0))
	bodycam_rec_dot.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	bodycam_rec_dot.add_theme_constant_override("shadow_offset_x", 2)
	bodycam_rec_dot.add_theme_constant_override("shadow_offset_y", 2)
	bodycam_rec_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line1.add_child(bodycam_rec_dot)

	bodycam_osd_label = Label.new()
	bodycam_osd_label.text = "2026-11-08 14:32:05Z   BAT 94%"
	bodycam_osd_label.add_theme_font_size_override("font_size", 13)
	bodycam_osd_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.90, 0.80))
	bodycam_osd_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	bodycam_osd_label.add_theme_constant_override("shadow_offset_x", 2)
	bodycam_osd_label.add_theme_constant_override("shadow_offset_y", 2)
	bodycam_osd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bodycam_container.add_child(bodycam_osd_label)

	crosshair = CROSSHAIR.new()
	add_child(crosshair)

	var health_box := HBoxContainer.new()
	health_box.offset_left = 28.0
	health_box.offset_top = 24.0
	health_box.offset_right = 260.0
	health_box.offset_bottom = 60.0
	health_box.add_theme_constant_override("separation", 10)
	add_child(health_box)

	health_label = Label.new()
	health_label.text = "HP 100"
	health_label.add_theme_font_size_override("font_size", 20)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	health_box.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(140, 22)
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	health_box.add_child(health_bar)

	# QA-fix TASK-0022: зелёная полоса перевязки по центру снизу.
	heal_progress_bar = ProgressBar.new()
	heal_progress_bar.min_value = 0.0
	heal_progress_bar.max_value = 100.0
	heal_progress_bar.value = 0.0
	heal_progress_bar.show_percentage = false
	heal_progress_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	heal_progress_bar.offset_left = -170.0
	heal_progress_bar.offset_right = 170.0
	heal_progress_bar.offset_top = -150.0
	heal_progress_bar.offset_bottom = -134.0
	heal_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heal_bg := StyleBoxFlat.new()
	heal_bg.bg_color = Color(0.06, 0.09, 0.06, 0.85)
	heal_bg.set_corner_radius_all(4)
	var heal_fill := StyleBoxFlat.new()
	heal_fill.bg_color = Color(0.30, 0.85, 0.35, 0.95)
	heal_fill.set_corner_radius_all(4)
	heal_progress_bar.add_theme_stylebox_override("background", heal_bg)
	heal_progress_bar.add_theme_stylebox_override("fill", heal_fill)
	heal_progress_bar.visible = false
	add_child(heal_progress_bar)

	ammo_label = Label.new()
	ammo_label.anchor_left = 1.0
	ammo_label.anchor_right = 1.0
	ammo_label.anchor_top = 1.0
	ammo_label.anchor_bottom = 1.0
	ammo_label.offset_left = -390.0
	ammo_label.offset_right = -24.0
	ammo_label.offset_top = -78.0
	ammo_label.offset_bottom = -38.0
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	ammo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	ammo_label.add_theme_constant_override("shadow_offset_x", 2)
	ammo_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(ammo_label)

	equip_label = Label.new()
	equip_label.anchor_left = 1.0
	equip_label.anchor_right = 1.0
	equip_label.anchor_top = 1.0
	equip_label.anchor_bottom = 1.0
	equip_label.offset_left = -640.0
	equip_label.offset_right = -24.0
	equip_label.offset_top = -112.0
	equip_label.offset_bottom = -82.0
	equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	equip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equip_label.add_theme_font_size_override("font_size", 15)
	equip_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
	add_child(equip_label)

	# На телефоне патроны и экипировка размещаются левее блока кнопок огня и приседа (не перекрывая aim)
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		ammo_label.anchor_left = 1.0
		ammo_label.anchor_right = 1.0
		ammo_label.anchor_top = 1.0
		ammo_label.anchor_bottom = 1.0
		ammo_label.offset_left = -560.0
		ammo_label.offset_right = -170.0
		ammo_label.offset_top = -68.0
		ammo_label.offset_bottom = -34.0
		ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		equip_label.anchor_left = 1.0
		equip_label.anchor_right = 1.0
		equip_label.anchor_top = 1.0
		equip_label.anchor_bottom = 1.0
		equip_label.offset_left = -660.0
		equip_label.offset_right = -170.0
		equip_label.offset_top = -102.0
		equip_label.offset_bottom = -72.0
		equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	pickup_label = Label.new()
	pickup_label.anchor_left = 0.5
	pickup_label.anchor_right = 0.5
	pickup_label.anchor_top = 1.0
	pickup_label.anchor_bottom = 1.0
	pickup_label.offset_left = -220.0
	pickup_label.offset_right = 220.0
	pickup_label.offset_top = -92.0
	pickup_label.offset_bottom = -54.0
	pickup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pickup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pickup_label.add_theme_font_size_override("font_size", 20)
	pickup_label.add_theme_color_override("font_color", Color(0.97, 0.88, 0.55))
	pickup_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.02, 0.95))
	pickup_label.add_theme_constant_override("shadow_offset_x", 2)
	pickup_label.add_theme_constant_override("shadow_offset_y", 2)
	pickup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickup_label.visible = false
	add_child(pickup_label)

	damage_label = Label.new()
	damage_label.anchor_left = 0.5
	damage_label.anchor_right = 0.5
	damage_label.anchor_top = 0.5
	damage_label.anchor_bottom = 0.5
	damage_label.offset_left = -90.0
	damage_label.offset_right = 90.0
	damage_label.offset_top = -78.0
	damage_label.offset_bottom = -34.0
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_size_override("font_size", 26)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.16, 0.12, 1.0))
	damage_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 0.95))
	damage_label.add_theme_constant_override("outline_size", 7)
	damage_label.visible = false
	add_child(damage_label)

	_build_death_screen()

func _build_death_screen() -> void:
	death_screen = Control.new()
	death_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.visible = false
	add_child(death_screen)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.02, 0.02, 0.75)
	death_screen.add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.offset_left = -220
	center.offset_right = 220
	center.offset_top = -140
	center.offset_bottom = 140
	center.add_theme_constant_override("separation", 16)
	death_screen.add_child(center)

	var title := Label.new()
	title.text = "ПОГИБ В БОЮ (K.I.A.)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.20))
	center.add_child(title)

	death_info_label = Label.new()
	death_info_label.text = "Вы были сражены в бою"
	death_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_info_label.add_theme_font_size_override("font_size", 18)
	death_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	center.add_child(death_info_label)

	var respawn_btn := Button.new()
	respawn_btn.text = "ТАКТИЧЕСКИЙ ДЕПЛОЙ (DEPLOY)"
	respawn_btn.custom_minimum_size = Vector2(300, 56)
	respawn_btn.add_theme_font_size_override("font_size", 20)
	respawn_btn.pressed.connect(func():
		if death_screen != null:
			death_screen.visible = false
		deploy_requested.emit()
	)
	center.add_child(respawn_btn)

	var menu_btn := Button.new()
	menu_btn.text = "В ГЛАВНОЕ МЕНЮ"
	menu_btn.custom_minimum_size = Vector2(300, 48)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	center.add_child(menu_btn)


func set_hud_visible(value: bool) -> void:
	visible = value

func set_health(value: float) -> void:
	if health_label != null:
		health_label.text = "HP %d" % int(round(value))
	if health_bar != null:
		health_bar.value = value

func set_ammo_text(text: String) -> void:
	if ammo_label != null:
		ammo_label.text = text

func set_equipment_text(text: String) -> void:
	if equip_label != null:
		equip_label.text = text

func set_pickup_prompt(text: String) -> void:
	if pickup_label == null:
		return
	pickup_label.visible = not text.is_empty()
	if not text.is_empty() and pickup_label.text != text:
		pickup_label.text = text

func set_heal_progress(progress: float) -> void:
	if heal_progress_bar == null:
		return
	heal_progress_bar.visible = progress >= 0.0
	if progress >= 0.0:
		heal_progress_bar.value = clampf(progress * 100.0, 0.0, 100.0)

func set_scope(active: bool) -> void:
	if crosshair != null and crosshair.has_method("set_sniper_scope"):
		crosshair.call("set_sniper_scope", active)

func set_crosshair_visible(value: bool) -> void:
	if crosshair != null:
		crosshair.visible = value

func flash_hit() -> void:
	if crosshair != null and crosshair.has_method("flash_hit"):
		crosshair.call("flash_hit")

func show_damage(amount: int) -> void:
	if damage_label == null:
		return
	damage_label.text = "−%d" % amount
	damage_label.visible = true
	damage_label.modulate = Color.WHITE
	damage_label.offset_top = -78.0
	damage_label.offset_bottom = -34.0
	_damage_time = 0.65

func flash_blood() -> void:
	_blood_timer = 1.0

func show_death(killer_name: String) -> void:
	if death_info_label != null:
		death_info_label.text = "Вас уничтожил: " + killer_name
	if death_screen != null:
		death_screen.visible = true

func hide_death() -> void:
	if death_screen != null:
		death_screen.visible = false

func reset_after_respawn() -> void:
	_damage_time = 0.0
	_blood_timer = 0.0
	if damage_label != null:
		damage_label.visible = false
	set_heal_progress(-1.0)
	hide_death()

func is_death_visible() -> bool:
	return death_screen != null and death_screen.visible

func open_pause() -> void:
	if pause_menu != null and not get_tree().paused:
		pause_menu.open()

func update(delta: float, health: float) -> void:
	_damage_time = maxf(0.0, _damage_time - delta)
	if damage_label != null:
		if _damage_time > 0.0:
			var fade := clampf(_damage_time / 0.65, 0.0, 1.0)
			damage_label.modulate.a = fade
			damage_label.offset_top = -78.0 - (1.0 - fade) * 22.0
			damage_label.offset_bottom = damage_label.offset_top + 44.0
		elif damage_label.visible:
			damage_label.visible = false

	_blood_timer = maxf(0.0, _blood_timer - delta * 2.5)
	var blood_alpha := _blood_timer * 0.45
	if blood_alpha <= 0.0 and health < 35.0:
		blood_alpha = clampf((35.0 - health) / 35.0, 0.0, 0.3)
	if blood_overlay != null:
		blood_overlay.color.a = blood_alpha
		blood_overlay.visible = blood_alpha > 0.004

	_bodycam_time += delta
	if bodycam_rec_dot != null:
		bodycam_rec_dot.modulate.a = 0.30 + 0.70 * absf(sin(_bodycam_time * 3.6))
	_osd_timer -= delta
	if _osd_timer <= 0.0 and bodycam_osd_label != null:
		_osd_timer = 1.0
		var dt := Time.get_datetime_dict_from_system()
		bodycam_osd_label.text = "%04d-%02d-%02d %02d:%02d:%02dZ   BAT 94%%" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]

func _build_pause_menu(parent: Node) -> void:
	pause_menu = PAUSE_MENU.new()
	parent.add_child(pause_menu)
	pause_menu.resumed.connect(func(): pause_resumed.emit())

	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.offset_left = -108.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_top = 16.0
	pause_btn.offset_bottom = 56.0
	pause_btn.add_theme_font_size_override("font_size", 18)
	pause_btn.pressed.connect(open_pause)
	add_child(pause_btn)

