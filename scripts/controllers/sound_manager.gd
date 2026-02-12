extends Node

signal music_changed(track_name: String)

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []

var main_menu_tracks: Array[String] = ["forest.ogg"]
var world_day_tracks: Array[String] = ["town_3.ogg", "town_4.mp3"]
var world_night_tracks: Array[String] = ["combat_1.mp3", "combat_2.mp3"]
var town_tracks: Array[String] = ["town.ogg", "town_2.mp3"]

var current_track: String = ""
var current_scene: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	
	for i in 10:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.finished.connect(func(): if p.stream and not p.playing: p.stream = null)
		add_child(p)
		sfx_pool.append(p)

func play_music(stream: AudioStream, crossfade: float = 0.5):
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()


func play_music_for_scene(scene_name: String, is_night: bool = false):
	current_scene = scene_name
	var tracks: Array[String] = []
	
	match scene_name:
		"main_menu":
			tracks = main_menu_tracks
		"world":
			tracks = world_day_tracks if not is_night else world_night_tracks
		"town":
			tracks = town_tracks
		_:
			return
	
	if tracks.is_empty():
		return
	
	play_random_track(tracks)

func play_random_track(tracks: Array[String]):
	if tracks.is_empty():
		return
	
	var available_tracks = tracks.duplicate()
	
	if not current_track.is_empty() and available_tracks.has(current_track):
		available_tracks.erase(current_track)
	
	if available_tracks.is_empty():
		available_tracks = tracks.duplicate()
	
	var random_track = available_tracks[randi() % available_tracks.size()]
	play_track(random_track)

func play_track(track_name: String):
	var track_path = "res://assets/sound/music/" + track_name
	
	if not ResourceLoader.exists(track_path):
		#print("Music track not found: ", track_path)
		return
	
	var audio_stream = load(track_path)
	if audio_stream:
		music_player.stream = audio_stream
		music_player.play()
		current_track = track_name
		music_changed.emit(track_name)
		#print("Playing music: ", track_name)

func stop_music():
	if music_player.playing:
		music_player.stop()
		current_track = ""

func _on_music_finished():
	var tracks: Array[String] = []
	
	if current_track in main_menu_tracks:
		tracks = main_menu_tracks
	elif current_track in world_day_tracks or current_track in world_night_tracks:
		var is_night = current_track in world_night_tracks
		tracks = world_day_tracks if not is_night else world_night_tracks
	elif current_track in town_tracks:
		tracks = town_tracks
	
	play_random_track(tracks)

func set_volume(volume_db: float):
	if music_player:
		music_player.volume_db = volume_db

func get_current_track() -> String:
	return current_track

func pause_music():
	if music_player and music_player.playing:
		music_player.stream_paused = true

func resume_music():
	if music_player and music_player.stream_paused:
		music_player.stream_paused = false

func play_global_sfx(stream: AudioStream, pitch_scale: float = 1.0):
	if not stream: return
	
	var player = _get_available_sfx_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in sfx_pool:
		if not p.playing:
			return p
	var p = AudioStreamPlayer.new()
	p.bus = "SFX"
	add_child(p)
	sfx_pool.append(p)
	return p

func play_ui_sound(stream: AudioStream):
	play_global_sfx(stream)
