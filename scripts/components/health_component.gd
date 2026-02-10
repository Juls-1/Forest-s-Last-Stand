extends Node
class_name HealthComponent

@export var max_health: int = 100
@onready var current_health: int = max_health

signal health_changed(new_health: int, max_health: int)
signal died

func _ready():
	health_changed.emit(current_health, max_health)

func take_damage(amount: int):
	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0
