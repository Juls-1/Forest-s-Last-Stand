extends Control

func _ready():
	var start_button = $VBoxContainer/PanelContainer/StartButton as Button
	var quit_button = $VBoxContainer/PanelContainer2/QuitButton as Button
	
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		start_button.grab_focus()
		start_button.pressed.connect(_play_click_sound)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
		quit_button.pressed.connect(_play_click_sound)
	
	SoundManager.play_music_for_scene("main_menu")

func _on_start_button_pressed():
	await SceneTransition.transition_to_scene(
		0.35,
		func():
			get_tree().change_scene_to_file("res://tutorial/cutscene1.tscn")
	)

func _on_quit_button_pressed():
	get_tree().quit()

func _play_click_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/click.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
