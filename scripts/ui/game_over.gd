extends CanvasLayer

@onready var reason_label: Label = $CenterContainer/VBoxContainer/ReasonLabel
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $CenterContainer/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
		restart_button.pressed.connect(_play_click_sound)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
		main_menu_button.pressed.connect(_play_click_sound)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
		quit_button.pressed.connect(_play_click_sound)

func show_game_over(reason: String = "Game Over") -> void:
	if reason_label:
		reason_label.text = reason
	show()
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	
	Engine.set_meta("blacksmith_improvement_achieved", false)
	SessionPersistence.clear_cached_units_state()
	
	queue_free()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _play_click_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/click.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
