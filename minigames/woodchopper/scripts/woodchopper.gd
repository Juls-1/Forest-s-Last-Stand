extends CanvasLayer
@onready var timer: Timer = $Timer
@onready var label: Label = $TimerLabel
@onready var wood_counter: Label = $WoodIcon/WoodCounter
@onready var game_over_screen: Node2D = $GameOverScreen
@onready var play_again: Button = $GameOverScreen/PlayAgain
@onready var go_back: Button = $GameOverScreen/Return

var game_over:bool
var wood_collected:int

func _ready() -> void:
	game_over = false
	wood_collected = 0
	game_over_screen.visible = false
	
	# Pausar la música de town
	if SoundManager and SoundManager.current_scene == "town":
		SoundManager.pause_music()
	
	if play_again:
		play_again.pressed.connect(_on_play_again_pressed)
		play_again.pressed.connect(_play_click_sound)
	if go_back:
		go_back.pressed.connect(_on_return_pressed)
		go_back.pressed.connect(_play_click_sound)


func _process(_delta: float) -> void:
	if !game_over and timer != null:
		label.text = str(ceil(timer.time_left))

func increase_wood_counter() -> void:
	wood_collected += 1
	wood_counter.text = str(wood_collected)
	

func set_game_over():
	print("Game Over Activado") 
	game_over = true
	game_over_screen.visible = true

func _on_timer_timeout() -> void:
	timer.stop() 
	label.text = "0"
	set_game_over()
	
func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func _on_return_pressed() -> void:
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("reward_minigame") and wood_collected > 0:
		gm.reward_minigame({"gold": 0, "wood": wood_collected, "stone": 0})
	get_tree().paused = false
	
	if SoundManager and SoundManager.current_scene == "town":
		SoundManager.resume_music()
	
	queue_free()
	if SceneTransition:
		SceneTransition.fade_in(0.3)

func _play_click_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/click.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
