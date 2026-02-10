extends CanvasLayer

var stone_collected:int = 0
var last_mouse_mode: int = -1

@onready var game_over_screen: Node2D = $GameOverScreen
@onready var label: Label = $HUD/Label
@onready var custom_cursor: Node2D = $CustomCursor
@onready var button: Button = game_over_screen.find_child("Button", true, false)

func _ready() -> void:
	game_over_screen.visible = false
	update_label()
	last_mouse_mode = Input.mouse_mode



func game_over() -> void:
	game_over_screen.visible = true

func update_label() -> void:
	label.text = "x " + str(stone_collected).pad_zeros(2)

func _process(_delta: float) -> void:
	if Input.mouse_mode != last_mouse_mode:
		print("[WhackAStone] ALERTA: mouse_mode cambió de ", last_mouse_mode, " a ", Input.mouse_mode)
		last_mouse_mode = Input.mouse_mode

func _on_button_pressed() -> void:
	var resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if resource_manager and stone_collected > 0:
		resource_manager.add_resources(0, 0, stone_collected)  
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	get_tree().paused = false
	queue_free()
	if SceneTransition:
		SceneTransition.fade_in(0.3)
