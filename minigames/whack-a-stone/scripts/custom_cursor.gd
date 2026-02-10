extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var pickaxe_damage: int = 1 

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			sprite.frame = 1
		else:
			sprite.frame = 0
