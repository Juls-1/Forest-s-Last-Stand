extends CanvasLayer

@onready var reason_label: Label = $CenterContainer/VBoxContainer/ReasonLabel
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $CenterContainer/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	# Establecer el modo de proceso en ALWAYS para que los botones funcionen cuando el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	

	
	# Ocultar por defecto
	hide()

func show_game_over(reason: String = "Game Over") -> void:
	"""Mostrar la pantalla de fin de juego con un motivo"""
	if reason_label:
		reason_label.text = reason
	show()
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	"""Reiniciar la escena actual"""
	get_tree().paused = false
	# Remove this game over screen before reloading
	queue_free()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	"""Volver al menú principal"""
	get_tree().paused = false
	# Remove this game over screen before changing scene
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	"""Salir del juego"""
	get_tree().quit()
