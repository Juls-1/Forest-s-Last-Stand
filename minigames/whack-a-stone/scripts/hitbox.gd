extends Area2D

const TOUCH_ANIM_DURATION:float = 0.05
const TOUCH_MOVEMENT_AMOUNT:int = 6

@onready var rock:Rock = owner
@onready var visuals: Node2D = $"../../Visuals"

var pickaxe_dmg:int = 1
var disable_input:bool = false

func _ready() -> void:
	_load_pickaxe_damage()
	input_pickable = true

func _load_pickaxe_damage() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "pickaxe_tier" in gm:
		pickaxe_dmg = int(gm.pickaxe_tier)
	else:
		pickaxe_dmg = 1

func _touched_anim(obj:Node2D) -> void:
	var orig_x:float = visuals.position.x
	var direction:float = 1
	var rand:int = randi() % 2
	if rand == 0:
		direction *= -1
	direction *= TOUCH_MOVEMENT_AMOUNT
	direction += orig_x
	
	var tw = create_tween()
	tw.tween_property(
		obj,
		"position:x",
		direction,
		TOUCH_ANIM_DURATION
	)
	tw.chain().tween_property(
		obj,
		"position:x",
		orig_x,
		TOUCH_ANIM_DURATION
	)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if !disable_input:
		if event is InputEventMouseButton and event.pressed:
			_touched_anim(visuals)
			rock.hole.touch_sfx.play()
			rock.reduce_hp(pickaxe_dmg)
	else:
		pass

func _on_exploding_rock_rock_exploded(_rock) -> void:
	disable_input = true
