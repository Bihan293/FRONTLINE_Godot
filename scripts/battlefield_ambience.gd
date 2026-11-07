extends Node
class_name FRONTLINEAmbience

## Звуковая атмосфера поля боя в стиле Dummy War.
## Реализует:
## - Свист и щелчок пролетающих рядом пуль (Supersonic Bullet Whiz)
## - Далёкие раскаты артиллерии фронта
## - Стук сердца при критическом здоровье

static var instance: FRONTLINEAmbience

var _whiz_players: Array[AudioStreamPlayer] = []
var _artillery_player: AudioStreamPlayer
var _heartbeat_player: AudioStreamPlayer
var _artillery_timer := 0.0

func _ready() -> void:
	instance = self
	_build_audio_players()
	_artillery_timer = randf_range(6.0, 14.0)

func _build_audio_players() -> void:
	for i in range(3):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_whiz_players.append(p)

	_artillery_player = AudioStreamPlayer.new()
	_artillery_player.volume_db = -8.0
	add_child(_artillery_player)

## Проверяет, пролетела ли пуля рядом с головой игрока, и воспроизводит свист
static func check_bullet_flyby(ray_from: Vector3, ray_to: Vector3, ear_pos: Vector3) -> void:
	if instance == null:
		return
	var seg := ray_to - ray_from
	var seg_len := seg.length()
	if seg_len < 0.1:
		return
	var dir := seg / seg_len
	var to_ear := ear_pos - ray_from
	var proj := to_ear.dot(dir)
	if proj < 0.5 or proj > seg_len:
		return
	var closest_pt := ray_from + dir * proj
	var dist := closest_pt.distance_to(ear_pos)
	if dist < 2.8:
		instance.play_whiz()

func play_whiz() -> void:
	for p in _whiz_players:
		if not p.playing:
			p.pitch_scale = randf_range(0.95, 1.25)
			# Используем встроенный синтез короткого щелчка/свиста
			p.play()
			break

func _process(delta: float) -> void:
	_artillery_timer -= delta
	if _artillery_timer <= 0.0:
		_artillery_timer = randf_range(10.0, 22.0)
		_trigger_distant_artillery()

func _trigger_distant_artillery() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and "recoil" in player:
		# Лёгкая вибрация от далёкого разрыва снаряда
		player.recoil.y += randf_range(0.005, 0.012)
