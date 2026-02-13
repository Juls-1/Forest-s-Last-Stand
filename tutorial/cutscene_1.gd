extends Node2D

@export var animation_player : AnimationPlayer
@export var autoplay : bool = false

var is_skipping := false
var animation_finished := false

func _ready():
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
		if autoplay:
			animation_player.play()
	
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_accept") and not animation_finished and not is_skipping:
		skip_cutscene()

func skip_cutscene():
	if is_skipping or animation_finished:
		return
	
	is_skipping = true
	if animation_player:
		animation_player.stop()
	go_to_town()

func _on_animation_finished(_anim_name: String):
	if not is_skipping:
		animation_finished = true
		await get_tree().create_timer(1.0).timeout
		go_to_town()

func go_to_town():
	await SceneTransition.transition_to_scene(
		0.35,
		func():
			get_tree().change_scene_to_file("res://scenes/levels/town.tscn")
	)
