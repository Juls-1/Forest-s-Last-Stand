extends Node

const SUBDIVISIONS:int = 4

@onready var timer: Timer = $Timer
var tick_count:int = -8
var beat_length:float

signal tick

func _ready():
	timer.one_shot = false
	timer.timeout.connect(_on_tick)
	
func init_timer(bpm:int) -> void:
	beat_length = (60.0 / bpm) / SUBDIVISIONS
	timer.wait_time = beat_length
	timer.start()

func _on_tick():
	tick_count += 1
	tick.emit(tick_count)
	#print(str(tick_count))

func get_time_since_last_tick() -> float:
	return beat_length - timer.time_left
