extends CanvasLayer
class_name FRONTLINEPlayerHUD

## Весь HUD игрока: здоровье, патроны, прицел, урон, смерть, пауза.
## Вёрстка живёт в scenes/PlayerHUD.tscn, скрипт только обновляет данные.

signal pause_resumed
signal deploy_requested

const PAUSE_MENU = preload("res://scripts/pause_menu.gd")

@onready var blood_overlay: ColorRect = %BloodOverlay
@onready var bodycam_vignette: ColorRect = %BodycamVignette
@onready var bodycam_rec_dot: Label = %RecDot
@onready var bodycam_osd_label: Label = %OsdLabel
@onready var crosshair: Control = %Crosshair
@onready var health_label: Label = %HealthLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var heal_progress_bar: ProgressBar = %HealProgressBar
@onready var ammo_label: Label = %AmmoLabel
@onready var equip_label: Label = %EquipLabel
@onready var pickup_label: Label = %PickupLabel
@onready var damage_label: Label = %DamageLabel
@onready var death_screen: Control = %DeathScreen
@onready var death_info_label: Label = %DeathInfoLabel

var pause_menu: FRONTLINEPauseMenu

@onready var _pause_button: Button = %PauseButton
@onready var _deploy_button: Button = %DeployButton
@onready var _menu_button: Button = %MenuButton

var _damage_time := 0.0
var _blood_timer := 0.0
var _bodycam_time := 0.0
var _osd_timer := 0.0

func _ready() -> void:
	_pause_button.pressed.connect(open_pause)
	_deploy_button.pressed.connect(_on_deploy_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_apply_mobile_layout()

func setup(parent: Node) -> void:
	_build_pause_menu(parent)

func _apply_mobile_layout() -> void:
	if not (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
		return
	ammo_label.offset_left = -560.0
	ammo_label.offset_right = -170.0
	ammo_label.offset_top = -68.0
	ammo_label.offset_bottom = -34.0
	equip_label.offset_left = -660.0
	equip_label.offset_right = -170.0
	equip_label.offset_top = -102.0
	equip_label.offset_bottom = -72.0

func _on_deploy_pressed() -> void:
	hide_death()
	deploy_requested.emit()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

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

