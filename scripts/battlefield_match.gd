extends RefCounted
class_name FRONTLINEBattlefieldMatch

## Состояние матча: счёт, тикеты, время, статистика игрока и экран победы.
## Компонент не строит мир и не спавнит ботов — только правила боя.

const TDM_TARGET_KILLS := 50

var game_mode := "CONQUEST"
var team_name := "IRON LEGION"
var score_iron := 60
var score_red := 60
var score_kills := 0
var match_elapsed_time := 0.0
var player_deaths := 0
var player_damage := 0
var player_captures := 0
var is_game_over := false
var victory_panel: PanelContainer

var _battlefield: Node3D
var _ticket_bleed_timer := 4.0

func setup(battlefield: Node3D) -> void:
	_battlefield = battlefield

func configure_mode(mode: String, player_team: String) -> void:
	game_mode = mode
	team_name = player_team
	if game_mode == "TDM":
		score_iron = 0
		score_red = 0
	else:
		score_iron = 60
		score_red = 60

func tick(delta: float) -> void:
	if is_game_over:
		return
	match_elapsed_time += delta
	_update_ticket_bleed(delta)

func record_player_death() -> void:
	player_deaths += 1

func record_player_damage(amount: int) -> void:
	if amount > 0:
		player_damage += amount

func record_player_capture() -> void:
	player_captures += 1

func add_kill() -> void:
	score_kills += 1

func on_bot_killed(victim: FRONTLINESoldierBot) -> void:
	if game_mode == "TDM":
		if victim.team_name.contains("RED"):
			score_iron += 1
		else:
			score_red += 1
		refresh_hud()
		if score_iron >= TDM_TARGET_KILLS:
			end_match("IRON LEGION")
		elif score_red >= TDM_TARGET_KILLS:
			end_match("RED FRONT")
	else:
		if victim.team_name.contains("RED"):
			score_red = maxi(0, score_red - 1)
		else:
			score_iron = maxi(0, score_iron - 1)
		refresh_hud()
		if score_red <= 0:
			end_match("IRON LEGION")
		elif score_iron <= 0:
			end_match("RED FRONT")

func refresh_hud() -> void:
	var hud = _battlefield.get("battlefield_hud")
	if hud != null:
		hud.call("refresh_score", game_mode, score_iron, score_red)

func end_match(winner: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player = _battlefield.get("player")
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", true)
	var tree := _battlefield.get_tree()
	for bot in tree.get_nodes_in_group("bots"):
		if is_instance_valid(bot):
			bot.set_physics_process(false)
			bot.set_process(false)

	var is_player_winner: bool = (team_name == winner)
	victory_panel = PanelContainer.new()
	victory_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	victory_panel.offset_left = -320
	victory_panel.offset_right = 320
	victory_panel.offset_top = -220
	victory_panel.offset_bottom = 220
	var hud = _battlefield.get("hud")
	if hud != null:
		hud.add_child(victory_panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	victory_panel.add_child(vb)

	var title := Label.new()
	title.text = "★ ПОБЕДА! ★" if is_player_winner else "ПОРАЖЕНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	var title_col := Color(0.95, 0.82, 0.25) if is_player_winner else Color(0.92, 0.28, 0.22)
	title.add_theme_color_override("font_color", title_col)
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "СЕКТОРЫ ПОД КОНТРОЛЕМ" if is_player_winner else "СИЛЫ ФРОНТА ИСЧЕРПАНЫ"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vb.add_child(sub)

	var mins := int(match_elapsed_time) / 60
	var secs := int(match_elapsed_time) % 60
	var kd_ratio: float = float(score_kills) if player_deaths == 0 else (float(score_kills) / float(player_deaths))
	var stats := Label.new()
	stats.text = "КАРТА: %s   •   РЕЖИМ: %s   •   ВРЕМЯ: %02d:%02d\nСЧЁТ: ЖЕЛЕЗНЫЙ ЛЕГИОН %d : %d КРАСНАЯ ЗВЕЗДА\n\nБОЕВОЙ ОТЧЁТ ИГРОКА:\nФраги: %d   •   Смерти: %d   •   K/D: %.2f\nЗахват секторов: %d   •   Нанесённый урон: %d" % [
		MatchState.map_name, game_mode, mins, secs,
		score_iron, score_red,
		score_kills, player_deaths, kd_ratio,
		player_captures, player_damage
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	vb.add_child(stats)

	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 24)
	vb.add_child(btn_box)

	var restart_btn := Button.new()
	restart_btn.text = "ПЕРЕИГРАТЬ"
	restart_btn.custom_minimum_size = Vector2(140, 48)
	restart_btn.add_theme_font_size_override("font_size", 16)
	restart_btn.pressed.connect(func():
		tree.paused = false
		tree.reload_current_scene()
	)
	btn_box.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "ГЛАВНОЕ МЕНЮ"
	menu_btn.custom_minimum_size = Vector2(160, 48)
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(func():
		tree.paused = false
		tree.change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_box.add_child(menu_btn)
	tree.paused = true

func _update_ticket_bleed(delta: float) -> void:
	if game_mode == "TDM":
		return
	_ticket_bleed_timer -= delta
	if _ticket_bleed_timer > 0.0:
		return
	_ticket_bleed_timer = 4.0

	var iron_sec := 0
	var red_sec := 0
	var sectors: Array = _battlefield.get("sector_data")
	for sec in sectors:
		if sec.owner == "IRON LEGION":
			iron_sec += 1
		elif sec.owner == "RED FRONT":
			red_sec += 1

	if iron_sec > red_sec:
		score_red = maxi(0, score_red - (iron_sec - red_sec))
	elif red_sec > iron_sec:
		score_iron = maxi(0, score_iron - (red_sec - iron_sec))

	refresh_hud()
	if score_red <= 0:
		end_match("IRON LEGION")
	elif score_iron <= 0:
		end_match("RED FRONT")
