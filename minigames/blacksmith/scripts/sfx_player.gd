extends AudioStreamPlayer

func play_win_sound() -> void:
	stream = load("res://minigames/blacksmith/sfx/win.wav")
	play()

func play_lose_sound() -> void:
	stream = load("res://minigames/blacksmith/sfx/lose.mp3")
	play()
