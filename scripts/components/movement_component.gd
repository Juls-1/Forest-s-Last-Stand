extends Node
class_name MovementComponent

@export var speed: float = 100.0
@export var navigation_agent_path: NodePath = NodePath("NavigationAgent2D")
@export var character_body_path: NodePath = NodePath("")
@onready var navigation_agent: NavigationAgent2D = get_node_or_null(navigation_agent_path) if has_node(navigation_agent_path) else get_parent().get_node_or_null("NavigationAgent2D")
@onready var character_body: CharacterBody2D = get_node_or_null(character_body_path) if has_node(character_body_path) else get_parent()

var target_position: Vector2
var has_target: bool = false
var speed_modifier: float = 1.0

signal target_reached

func _ready():
	if navigation_agent:
		navigation_agent.velocity_computed.connect(_on_velocity_computed)

func set_target_position(pos: Vector2):
	target_position = pos
	has_target = true
	if navigation_agent:
		navigation_agent.target_position = pos

func move_towards_target(_delta: float):
	if not has_target or not navigation_agent:
		return
	
	if navigation_agent.is_navigation_finished():
		has_target = false
		target_reached.emit()
		return
	
	var next_pos = navigation_agent.get_next_path_position()
	var direction = character_body.global_position.direction_to(next_pos)
	var velocity = direction * speed * speed_modifier
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(velocity)
	else:
		_on_velocity_computed(velocity)

func _on_velocity_computed(safe_velocity: Vector2):
	character_body.velocity = safe_velocity
	character_body.move_and_slide()

func set_speed_modifier(modifier: float) -> void:
	"""Set a speed multiplier (e.g., 1.0 for normal, 1/3 for slow spell)"""
	speed_modifier = modifier
