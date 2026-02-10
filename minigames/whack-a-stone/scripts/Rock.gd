extends Node
class_name Rock

@export var explosion:PackedScene
@onready var hole:Node2D = $"../.."
@onready var visuals: Node2D = $Visuals

var hp:int

signal rock_death(rock:Rock)

func reduce_hp(dmg:int) -> void:
	hp -= dmg
	if hp <= 0:
		_die()

func _free_hole() -> void:
	hole.occupied = false

func _die() -> void:
	rock_death.emit(self)
