extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const SFX_POOL_SIZE: int = 8

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_bgm_path: String = ""
var _bgm_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_players()
	load_audio_settings()

func _setup_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_bgm(stream: AudioStream, fade_duration: float = 0.5) -> void:
	if not stream:
		return
	if bgm_player.playing and bgm_player.stream == stream:
		return
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if "loop" in stream:
		stream.loop = true
	if bgm_player.playing and fade_duration > 0.0:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration * 0.5)
		_bgm_tween.tween_callback(func():
			bgm_player.stream = stream
			bgm_player.play()
		)
		_bgm_tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration * 0.5)
	else:
		bgm_player.volume_db = 0.0
		bgm_player.stream = stream
		bgm_player.play()

func stop_bgm(fade_duration: float = 0.5) -> void:
	if not bgm_player.playing:
		return
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if fade_duration > 0.0:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
		_bgm_tween.tween_callback(func():
			bgm_player.stop()
			bgm_player.volume_db = 0.0
		)
	else:
		bgm_player.stop()

func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if not stream:
		return
	var player := _get_available_sfx_player()
	player.stream = stream
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("AudioManager: Bus '%s' não encontrado." % bus_name)
		return
	var clamped := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_idx, clamped <= 0.001)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamped))

func get_bus_volume(bus_name: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1 or AudioServer.is_bus_mute(bus_idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master", get_bus_volume("Master"))
	config.set_value("audio", "bgm", get_bus_volume("BGM"))
	config.set_value("audio", "sfx", get_bus_volume("SFX"))
	config.save(SETTINGS_PATH)

func load_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		set_bus_volume("Master", config.get_value("audio", "master", 1.0))
		set_bus_volume("BGM", config.get_value("audio", "bgm", 0.8))
		set_bus_volume("SFX", config.get_value("audio", "sfx", 1.0))
	else:
		set_bus_volume("Master", 1.0)
		set_bus_volume("BGM", 0.8)
		set_bus_volume("SFX", 1.0)
