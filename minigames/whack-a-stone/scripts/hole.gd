extends Node2D

var game_continues:bool = true

@export var rocks:Array[PackedScene]

@onready var game: CanvasLayer = $"../.."
@onready var spawner: ColorRect = $Spawner
@onready var timer: Timer = $Timer
@onready var front: Sprite2D = $Front
@onready var sfx: AudioStreamPlayer = $BreakRocks
@onready var touch_sfx: AudioStreamPlayer = $TouchSFX
@onready var cpu_particles_2d: CPUParticles2D = $Front/CPUParticles2D

var occupied:bool = false

func _ready() -> void:
	game_continues = true
	timer.wait_time = randf_range(1, 10)
	timer.start()

func _on_timer_timeout() -> void:
	if !occupied and game_continues:
		occupied = true
		_spawn_random_rock()

func _spawn_random_rock() -> void:
		var r:int = randi_range(0, rocks.size() -1)
		var rock = rocks[r].instantiate()
		rock.rock_death.connect(_on_rock_has_died)
		if rock is ExplodingRock:
			rock.rock_exploded.connect(_on_rock_exploded)
		spawner.add_child(rock)

func _on_rock_has_died(rock) -> void:
	sfx.play()
	rock.queue_free()
	cpu_particles_2d.emitting = true
	occupied = false
	game.stone_collected += 1
	game.update_label()

func _on_rock_exploded(rock) -> void:
	game.stone_collected -= 1
	rock.queue_free()
	_play_explosion_sound()
	stop_game()

func stop_game() -> void:
	game_continues = false
	game.game_over()

func _play_explosion_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/lose.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
