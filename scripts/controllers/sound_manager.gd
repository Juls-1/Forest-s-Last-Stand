extends Node

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Pre-instantiate pool
	for i in 10:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.finished.connect(func(): if p.stream and not p.playing: p.stream = null)
		add_child(p)
		sfx_pool.append(p)

func play_music(stream: AudioStream, crossfade: float = 0.5):
	if music_player.stream == stream and music_player.playing:
		return
		
	# Simple crossfade could be implemented here with Tweens, keeping it simple for now
	music_player.stream = stream
	music_player.play()

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
	
	# Expand pool if needed
	var p = AudioStreamPlayer.new()
	p.bus = "SFX"
	add_child(p)
	sfx_pool.append(p)
	return p

# Helper for minigames or UI
func play_ui_sound(stream: AudioStream):
	play_global_sfx(stream)
