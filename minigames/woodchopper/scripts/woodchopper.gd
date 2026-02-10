extends CanvasLayer
#@export var timer: Timer 
#@export var label: Label 
#@export var wood_counter: Label 
#@export var game_over_screen: Node2D 
#@export var play_again: Button
#@export var go_back: Button 
@onready var timer: Timer = $Timer
@onready var label: Label = $TimerLabel
@onready var wood_counter: Label = $WoodCounter
@onready var game_over_screen: Node2D = $GameOverScreen
@onready var play_again: Button = $GameOverScreen/PlayAgain
@onready var go_back: Button = $GameOverScreen/Return

var game_over:bool
var wood_collected:int

func _ready() -> void:
	game_over = false
	wood_collected = 0
	game_over_screen.visible = false


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
	#if timer != null:
		#timer.stop()
	#game_over_screen.visible = true
	#
	#game_over = true

func _on_timer_timeout() -> void:
	timer.stop() 
	label.text = "0"
	#timer.queue_free()
	#label.text = str(0.0)
	set_game_over()
	
func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func _on_return_pressed() -> void:
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	# Añadir la madera recolectada al total del juego
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("reward_minigame") and wood_collected > 0:
		gm.reward_minigame({"gold": 0, "wood": wood_collected, "stone": 0})
	get_tree().paused = false
	queue_free()
	if SceneTransition:
		SceneTransition.fade_in(0.3)
