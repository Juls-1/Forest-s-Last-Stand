extends Control

func _ready():
	# Conectar botones a funciones usando la sintaxis de señales de Godot 4
	var start_button = $VBoxContainer/PanelContainer/StartButton as Button
	var quit_button = $VBoxContainer/PanelContainer2/QuitButton as Button
	
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		start_button.grab_focus()
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	await SceneTransition.transition_to_scene(
		0.35,
		func():
			get_tree().change_scene_to_file("res://scenes/levels/world.tscn")
	)



func _on_quit_button_pressed():
	get_tree().quit()
