extends Node

## Диагностика ИИ: запускает реальный бой без рендера и печатает,
## сколько ботов двигается, видят цель и в каком состоянии находятся.
## godot --headless --path . res://tools/ai_probe.tscn

const BATTLEFIELD_SCENE := "res://scenes/Battlefield.tscn"

func _ready() -> void:
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "IRON LEGION")
	get_tree().set_meta("match_squad_size", 7)
	get_tree().set_meta("skip_deploy_screen", true)

	var bot_script: Script = load("res://scripts/soldier_bot.gd")
	if bot_script != null:
		bot_script.profile_build = "profile" in OS.get_cmdline_user_args()
		var t0 := Time.get_ticks_usec()
		var test_bot: Node3D = bot_script.new()
		add_child(test_bot)
		var build_ms := float(Time.get_ticks_usec() - t0) / 1000.0
		print("BOT_BUILD_MS %.2f" % build_ms)
		test_bot.queue_free()
		await get_tree().process_frame
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate()
	add_child(battlefield)
	for _i in range(30):
		await get_tree().process_frame

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		player.global_position = Vector3(0.0, 0.6, 0.0)

	var starts := {}
	for bot in get_tree().get_nodes_in_group("bots"):
		starts[bot] = bot.global_position

	var elapsed := 0.0
	while elapsed < 40.0:
		await get_tree().create_timer(2.0).timeout
		elapsed += 2.0
		var bots := get_tree().get_nodes_in_group("bots")
		var targeting := 0
		var moved := 0
		var states := {}
		for bot in bots:
			var perception = bot.get("_perception")
			if perception != null and perception.target != null:
				targeting += 1
			if starts.has(bot) and bot.global_position.distance_to(starts[bot]) > 3.0:
				moved += 1
			var state := int(bot.get("ai_state"))
			states[state] = int(states.get(state, 0)) + 1
		print("AI t=%.0f bots=%d moving=%d targeting=%d states=%s fps=%.0f process=%.2fms nodes=%d" % [
			elapsed, bots.size(), moved, targeting, str(states),
			Performance.get_monitor(Performance.TIME_FPS),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		])
	print("AI_PROBE_OK")
	battlefield.queue_free()
	await get_tree().process_frame
	get_tree().quit()
