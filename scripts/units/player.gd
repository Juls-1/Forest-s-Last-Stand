extends CharacterBody2D

# Movimiento
@export var speed: float = 90.0
@export var rotation_speed: float = 10.0

# Combate
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 0.75  
@export var attack_animation_duration: float = 0.2 
@export var shooting_speed_multiplier: float = 0.5 
var can_shoot: bool = true
var last_shot: float = 0.0
var is_shooting: bool = false
var attack_timer: float = 0.0

# Componentes
@export var muzzle_path: NodePath = NodePath("Muzzle")
@export var animation_component_path: NodePath = NodePath("AnimationComponent")
@export var shoot_timer_path: NodePath = NodePath("ShootTimer")
@export var sound_component_path: NodePath = NodePath("SoundComponent")

@onready var muzzle: Marker2D = get_node_or_null(muzzle_path) if has_node(muzzle_path) else null
@onready var animation_component: AnimationComponent = get_node_or_null(animation_component_path)
@onready var shoot_timer: Timer = get_node_or_null(shoot_timer_path)
@onready var sound_component: SoundComponent = get_node_or_null(sound_component_path)

func _can_attack() -> bool:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("get"):
		if gm.current_location != "world":
			return false
		if gm.placement_manager and gm.placement_manager.is_placing:
			return false
	return true

func _ready() -> void:
	add_to_group("player")
	_ensure_sound_component()
	if shoot_timer:
		shoot_timer.timeout.connect(_on_shoot_cooldown_timeout)

func _ensure_sound_component():
	if not sound_component:
		var snd_node = get_node_or_null("SoundComponent")
		if not snd_node:
			snd_node = SoundComponent.new()
			snd_node.name = "SoundComponent"
			add_child(snd_node)
		sound_component = snd_node

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	var current_speed = speed
	if is_shooting:
		current_speed *= shooting_speed_multiplier
	velocity = input_vector * current_speed
	move_and_slide()
	
	if attack_timer > 0:
		attack_timer -= delta
		is_shooting = true
	else:
		is_shooting = false
	
	var anim_direction = input_vector
	if is_shooting:
		var mouse_pos = get_global_mouse_position()
		anim_direction = (mouse_pos - global_position).normalized()
	
	if animation_component:
		animation_component.update_animation(anim_direction, is_shooting)
	
	if Input.is_action_pressed("shoot") and can_shoot  and not _is_ui_hovered():
		shoot()

func shoot() -> void:
	if not projectile_scene:
		push_error("¡No hay escena de proyectil asignada al jugador!")
		return
	
	# Sound
	if sound_component: sound_component.play_attack()
	
	attack_timer = attack_animation_duration
	
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()
	var shoot_angle = shoot_direction.angle()
	
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.rotation = shoot_angle
	
	projectile.set_collision_layer_value(1, false)  
	projectile.set_collision_mask_value(1, false)   
	projectile.set_collision_mask_value(2, true)   
	
	can_shoot = false
	shoot_timer.start()

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and can_shoot and _can_attack() and not _is_ui_hovered():
		shoot()

func _is_ui_hovered() -> bool:
	var vp := get_viewport()
	if vp and vp.gui_get_hovered_control() != null:
		return true
	return false

func play_cast_spell(direction: Vector2) -> void:
	if animation_component and animation_component.has_method("play_cast"):
		animation_component.play_cast(direction)
