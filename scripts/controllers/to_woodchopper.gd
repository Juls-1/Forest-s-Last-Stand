extends Area2D

@export var woodchopper_scene_path: String = "res://minigames/woodchopper/scenes/woodchopper.tscn"
@export var tutorial_scene_path: String = "res://tutorial/tutorial_woodchopper.tscn"

var player_in_area: bool = false
var tutorial_instance: CanvasLayer = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E and player_in_area:
			get_viewport().set_input_as_handled()
			_enter_woodchopper_minigame()
		elif event.keycode == KEY_T and player_in_area:
			get_viewport().set_input_as_handled()
			_show_tutorial()
		
func _enter_woodchopper_minigame():
	_do_enter_with_fade()

func _do_enter_with_fade() -> void:
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	
	if SoundManager and SoundManager.current_scene == "town":
		SoundManager.pause_music()
	
	var minigame_scene = load(woodchopper_scene_path)
	var minigame_instance = minigame_scene.instantiate()
	get_tree().root.add_child(minigame_instance)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if SceneTransition:
		SceneTransition.fade_in(0.3)

func _show_tutorial():
	if tutorial_instance:
		return  
	
	var tutorial_scene = load(tutorial_scene_path)
	if tutorial_scene:
		tutorial_instance = tutorial_scene.instantiate()
		get_tree().current_scene.add_child(tutorial_instance)
	
		tutorial_instance.tree_exiting.connect(_on_tutorial_closed)

func _on_tutorial_closed():
	tutorial_instance = null
