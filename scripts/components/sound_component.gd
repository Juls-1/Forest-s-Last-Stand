extends Node2D
class_name SoundComponent

@export var attack_sound: AudioStream
@export var death_sound: AudioStream
@export var hit_sound: AudioStream
@export var walk_sound: AudioStream

@onready var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

func _ready():
	add_child(audio_player)
	audio_player.bus = "SFX"

func play_attack():
	if attack_sound: play_sound(attack_sound)

func play_death():
	if death_sound: play_sound(death_sound)

func play_hit():
	if hit_sound: play_sound(hit_sound)

func play_walk():
	if walk_sound and not audio_player.playing:
		play_sound(walk_sound, 0.9, 1.1)

func play_custom(stream: AudioStream):
	play_sound(stream)

func play_sound(stream: AudioStream, min_pitch: float = 0.9, max_pitch: float = 1.1):
	if stream:
		# If it's the same stream and already playing, maybe don't restart? 
		# For attacks we usually want to restart or allow overlap (polyphony).
		# AudioStreamPlayer2D is monophonic by default unless instantiated multiple times.
		# For this component, we'll interrupt.
		audio_player.stream = stream
		audio_player.pitch_scale = randf_range(min_pitch, max_pitch)
		audio_player.play()
