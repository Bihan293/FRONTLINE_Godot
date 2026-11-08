extends Node

## Lightweight performance probe for TASK-0019.
## Run under Xvfb for draw-call/FPS data or headless for CPU/physics/object data:
##   xvfb-run -a ... godot --path . --rendering-driver opengl3 \
##     res://tools/perf_probe.tscn -- map=BATTLEFIELD squad=14
##   godot --headless --path . res://tools/perf_probe.tscn -- map=BATTLEFIELD squad=14

const BATTLEFIELD_SCENE := "res://scenes/Battlefield.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var map_name := "BATTLEFIELD"
	var squad := 14
	var quality := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("map="):
			map_name = arg.substr(4)
		elif arg.begins_with("squad="):
			squad = clampi(int(arg.substr(6)), 4, 14)
		elif arg.begins_with("quality="):
			quality = clampi(int(arg.substr(8)), 0, 2)
	# QA: замер на конкретном пресете графики (0 = low mobile).
	if quality >= 0 and "quality" in GameSettings:
		GameSettings.quality = quality
		GameSettings.apply_video()
		GameSettings.apply_frame_limit()
	get_tree().set_meta("selected_map", map_name)
	get_tree().set_meta("selected_mode", "CONQUEST")
	get_tree().set_meta("selected_team", "IRON LEGION")
	get_tree().set_meta("selected_role", "ASSAULT")
	get_tree().set_meta("match_squad_size", squad)
	var packed: PackedScene = load(BATTLEFIELD_SCENE)
	var battlefield := packed.instantiate()
	add_child(battlefield)
	for _i in range(60):
		await get_tree().process_frame
	print("PERF map=%s squad=%d fps=%.1f process=%.2fms physics=%.2fms draw_calls=%d objects=%d nodes=%d memory=%.1fMB" % [
		map_name,
		squad,
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	])
	if "hold" in OS.get_cmdline_user_args():
		# QA-sweep инструмент: держим сцену живой 3 сек, чтобы различать
		# ошибки во время игры и при разрушении сцены.
		await get_tree().create_timer(3.0).timeout
		print("HOLD_PHASE_DONE")
	battlefield.queue_free()
	await get_tree().process_frame
	get_tree().quit()
