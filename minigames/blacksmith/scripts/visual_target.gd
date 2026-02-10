extends Node2D

const PX_PER_SECOND:int = 1068
const DESPAWN_THRESHOLD:float = 350

@onready var visual: Node2D = $Visual

var notifier:RhythmNotifier
var hit_time:float
var seconds_before_impact:float

signal missed(target)

func _ready() -> void:
	_update_position()

func _process(_delta: float) -> void:
	_update_position()
	if visual.position.x >= DESPAWN_THRESHOLD:
		missed.emit(self)
		queue_free()

func _update_position() -> void:
	seconds_before_impact = hit_time - notifier.current_position
	visual.position.x = seconds_before_impact * -PX_PER_SECOND
