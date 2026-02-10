extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var input_locked:bool = true

signal key_pressed

func _unlock_input():
	input_locked = false

func _lock_input():
	input_locked = true

func _input(event: InputEvent):
	if !input_locked:
		if event.is_action_pressed("ui_accept"):
			key_pressed.emit()
			animation_player.play("hit")
		elif event.is_action_released("ui_accept"):
			animation_player.play("release")
		#if(event.is_action_pressed("rhythm_game_key_2")):
			#key_pressed.emit(2)
		#if(event.is_action_pressed("rhythm_game_key_3")):
			#key_pressed.emit(3)
