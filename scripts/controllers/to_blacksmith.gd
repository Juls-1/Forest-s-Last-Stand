extends Area2D

@export var woodchopper_scene_path: String = "res://minigames/blacksmith/scenes/beat_forge.tscn"

var player_in_area: bool = false

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E and player_in_area:
			# marcamos el input como manejado PRIMERO
			get_viewport().set_input_as_handled()
			# luego hacemos la transición
			_enter_blacksmith_minigame()
			#get_tree().root.set_input_as_handled() //daba muchos errores
		
func _enter_blacksmith_minigame():
	_do_enter_with_fade()

func _do_enter_with_fade() -> void:
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	var minigame_scene = load(woodchopper_scene_path)
	var minigame_instance = minigame_scene.instantiate()
	get_tree().root.add_child(minigame_instance)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if SceneTransition:
		SceneTransition.fade_in(0.3)
