extends CharacterBody2D
class_name Enemy

@export var health_component_path: NodePath = NodePath("HealthComponent")
@export var movement_component_path: NodePath = NodePath("MovementComponent")
@export var attack_component_path: NodePath = NodePath("AttackComponent")
@export var animation_component_path: NodePath = NodePath("AnimationComponent")
@export var aggro_component_path: NodePath = NodePath("AggroComponent")
@export var sound_component_path: NodePath = NodePath("SoundComponent")
@export var health_bar_path: NodePath = NodePath("HealthBar")
@export var hit_box_path: NodePath = NodePath("HitBox")

@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var movement_component: MovementComponent = get_node_or_null(movement_component_path)
@onready var attack_component: AttackComponent = get_node_or_null(attack_component_path)
@onready var animation_component: AnimationComponent = get_node_or_null(animation_component_path)
@onready var aggro_component: AggroComponent = get_node_or_null(aggro_component_path)
@onready var sound_component: SoundComponent = get_node_or_null(sound_component_path)
@onready var health_bar: Range = get_node_or_null(health_bar_path)
@onready var hit_box: Area2D = get_node_or_null(hit_box_path) if has_node(hit_box_path) else null

const DEFAULT_ATTACK_COOLDOWN: float = 0.5
const REACHED_END_DISTANCE: float = 50.0

@export var max_health: int = 30
@export var speed: float = 500.0
@export var damage: int = 10
@export var gold_value: int = 5
@export var enemy_type: String = "basic"

var target: Node2D = null
var is_active: bool = true
var is_attacking: bool = false
var attack_animation_timer: float = 0.0

signal died(enemy)
signal reached_end

func _ready() -> void:
	add_to_group("enemies")
	_initialize_components()
	_initialize_health()
	_initialize_hit_box()
	_initialize_attack_component()
	_initialize_movement()

func _initialize_components() -> void:
	if aggro_component:
		aggro_component.enemy_type = enemy_type

func _initialize_health() -> void:
	if not health_component:
		return
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)

func _initialize_hit_box() -> void:
	if hit_box and not hit_box.area_entered.is_connected(_on_hit_box_entered):
		hit_box.area_entered.connect(_on_hit_box_entered)

func _initialize_attack_component() -> void:
	if not attack_component:
		return
	attack_component.damage = damage
	attack_component.attacked.connect(_on_attacked)

func _initialize_movement() -> void:
	if movement_component:
		movement_component.speed = speed
	_find_initial_target()

func _find_initial_target() -> void:
	var possible_targets = get_tree().get_nodes_in_group("target")
	if not possible_targets.is_empty():
		target = possible_targets[0]
		if movement_component:
			movement_component.set_target_position(target.global_position)

func _on_health_changed(new_health: int, _max_health: int) -> void:
	if health_bar:
		health_bar.value = new_health

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	_update_attack_animation(delta)
	
	var current_target = _get_current_target()
	if not is_instance_valid(current_target):
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	
	if _should_attack(distance):
		_execute_attack(current_target)
	elif movement_component:
		_move_toward_target(current_target, delta)
	
	_update_animation(current_target, distance)
	_check_reached_end(current_target, distance)

func _update_attack_animation(delta: float) -> void:
	if attack_animation_timer > 0:
		attack_animation_timer -= delta
		if attack_animation_timer <= 0:
			is_attacking = false

func _get_current_target() -> Node2D:
	var aggro_target = aggro_component.get_current_target() if aggro_component else null
	if is_instance_valid(aggro_target):
		return aggro_target
	
	if is_instance_valid(target):
		return target
	
	_find_initial_target()
	return target

func _should_attack(distance: float) -> bool:
	return attack_component and distance <= attack_component.attack_range

func _execute_attack(current_target: Node2D) -> void:
	attack_component.set_target(current_target)
	if movement_component:
		if "clear_target" in movement_component:
			movement_component.clear_target()
		# ensure the character body stops immediately
		velocity = Vector2.ZERO
		move_and_slide()
	
	if attack_component.can_attack():
		attack_component.perform_attack()
		is_attacking = true
		attack_animation_timer = DEFAULT_ATTACK_COOLDOWN

func _move_toward_target(current_target: Node2D, delta: float) -> void:
	movement_component.set_target_position(current_target.global_position)
	movement_component.move_towards_target(delta)

func _update_animation(current_target: Node2D, _distance: float) -> void:
	if not animation_component:
		return
	var move_dir = velocity.normalized()
	animation_component.update_animation(move_dir, is_attacking, current_target)

func _check_reached_end(_current_target: Node2D, distance: float) -> void:
	if aggro_component and aggro_component.has_aggro_targets():
		return
	if distance < REACHED_END_DISTANCE:
		reached_end.emit()
		_on_died()

func _on_died(_unit = null) -> void:
	if not is_active:
		return
	is_active = false
	died.emit(self)
	
	if sound_component:
		sound_component.play_death()
	
	await _play_death_animation()
	queue_free()

func _play_death_animation() -> void:
	if animation_component:
		await animation_component.play_death()

func _on_attacked(_target_node: Node2D) -> void:
	is_attacking = true
	attack_animation_timer = DEFAULT_ATTACK_COOLDOWN
	if sound_component:
		sound_component.play_attack()

func _on_hit_box_entered(area: Area2D) -> void:
	if area.is_in_group("projectiles"):
		_apply_projectile_damage(area)
		area.queue_free()

func _apply_projectile_damage(projectile: Area2D) -> void:
	if "damage" not in projectile:
		return
	if health_component:
		health_component.take_damage(projectile.damage)
	if sound_component:
		sound_component.play_hit()

func set_aggro_target(unit: Node2D) -> void:
	if aggro_component:
		aggro_component.set_aggro_target(unit)

func clear_aggro_target(unit: Node2D) -> void:
	if aggro_component:
		aggro_component.clear_aggro_target(unit)

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)
	if sound_component:
		sound_component.play_hit()

func set_speed_modifier(modifier: float) -> void:
	if movement_component:
		movement_component.set_speed_modifier(modifier)
