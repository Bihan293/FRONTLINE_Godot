extends Node

## Единственный источник правды о конфигурации матча.
## Заменяет строковые get_tree().get_meta("selected_map"/"selected_team"/...).
## Сцены и игроки читают отсюда, меню и деплой пишут сюда.

const DEFAULT_MAP := "BATTLEFIELD"
const DEFAULT_MODE := "CONQUEST"
const DEFAULT_TEAM := "IRON LEGION"
const DEFAULT_ROLE := "ASSAULT"
const DEFAULT_LOADOUT := "BALANCED"

const VALID_MAPS := ["BATTLEFIELD", "VILLAGE", "COUNTRYSIDE", "POLYGON"]
const VALID_MODES := ["CONQUEST", "TDM"]
const VALID_TEAMS := ["IRON LEGION", "RED FRONT"]
const VALID_ROLES := ["ASSAULT", "SNIPER", "MEDIC", "ANTI_TANK", "RADIO_OPERATOR"]

var map_name := DEFAULT_MAP
var mode := DEFAULT_MODE
var player_team := DEFAULT_TEAM
var player_role := DEFAULT_ROLE
var loadout_preset := DEFAULT_LOADOUT
var primary_weapon_index := -1
var grenades_override := -1
var smoke_override := -1
var medkits_override := -1
var rockets_override := -1
var squad_size := 7
var difficulty := 1
var spawn_position := Vector3.ZERO
var has_spawn_position := false
var skip_deploy_screen := false

var _open_deploy_on_start := false
var _deploy_intro := false

func configure(
	p_map: String,
	p_mode: String,
	p_team: String,
	p_role: String = DEFAULT_ROLE,
	p_squad_size: int = 7,
	p_difficulty: int = 1
) -> void:
	map_name = p_map if p_map in VALID_MAPS else DEFAULT_MAP
	mode = p_mode if p_mode in VALID_MODES else DEFAULT_MODE
	player_team = p_team if p_team in VALID_TEAMS else DEFAULT_TEAM
	player_role = p_role if p_role in VALID_ROLES else DEFAULT_ROLE
	squad_size = clampi(p_squad_size, 7, 14)
	difficulty = clampi(p_difficulty, 0, 2)
	loadout_preset = DEFAULT_LOADOUT
	primary_weapon_index = -1
	grenades_override = -1
	smoke_override = -1
	medkits_override = -1
	rockets_override = -1
	spawn_position = Vector3.ZERO
	has_spawn_position = false
	skip_deploy_screen = false
	_open_deploy_on_start = false
	_deploy_intro = false

func set_spawn(p_position: Vector3) -> void:
	spawn_position = p_position
	has_spawn_position = true

func consume_spawn(default_position: Vector3) -> Vector3:
	return spawn_position if has_spawn_position else default_position

func request_deploy_screen(on_start: bool, with_intro: bool) -> void:
	_open_deploy_on_start = on_start
	_deploy_intro = with_intro

func consume_open_deploy() -> bool:
	if not _open_deploy_on_start:
		return false
	_open_deploy_on_start = false
	_deploy_intro = false
	return true

func consume_deploy_intro() -> bool:
	var value := _deploy_intro
	_deploy_intro = false
	return value

func has_pending_deploy_intro() -> bool:
	return _deploy_intro

func has_pending_open_deploy() -> bool:
	return _open_deploy_on_start

func clear_spawn() -> void:
	spawn_position = Vector3.ZERO
	has_spawn_position = false
