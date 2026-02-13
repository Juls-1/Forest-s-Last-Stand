extends CanvasLayer

func _ready():
	var button = $Button as Button
	if button:
		button.pressed.connect(_on_volver_pressed)
		button.pressed.connect(_play_click_sound)

func _on_volver_pressed():
	# Remover el tutorial de la escena
	queue_free()

func _play_click_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/click.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
