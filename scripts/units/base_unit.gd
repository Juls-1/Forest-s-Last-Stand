class_name BaseUnit
extends CharacterBody2D

@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 100.0

@export var attack_range: CollisionShape2D
@export var aggro_range: CollisionShape2D
@export var projectile_scene: PackedScene
@export var muzzle_path: NodePath = NodePath("Muzzle")
@export var animation_manager_path: NodePath = NodePath("AnimationManager")
@export var sound_component_path: NodePath = NodePath("SoundComponent")
@export var health_bar_path: NodePath = NodePath("HealthBar")

@onready var muzzle: Marker2D = get_node_or_null(muzzle_path) if has_node(muzzle_path) else null
@onready var animation_manager: AnimationComponent = get_node_or_null(animation_manager_path)
@onready var sound_component: SoundComponent = get_node_or_null(sound_component_path)
@onready var health_bar: ProgressBar = get_node_or_null(health_bar_path)

enum UNIT_STATE { IDLE, MOVING, ATTACKING, DEAD }

const DEFAULT_MOVEMENT_TOLERANCE: float = 10.0
const DEFAULT_INVULNERABILITY_CHECK_FREQUENCY: float = 1.0

var current_state: UNIT_STATE = UNIT_STATE.IDLE
var current_health: int
var attack_timer: float = 0.0
var is_dying: bool = false

var target_position: Vector2
var movement_direction: Vector2 = Vector2.ZERO
var has_target: bool = false
var target_enemy: Node = null
var invulnerable_until: float = -1.0

func _ready() -> void:
	add_to_group("friendly_units")
	current_health = max_health
	_initialize_health_bar()
	_disable_collision_with_environment()
	_setup_attack_range()
	_setup_aggro_range()
	_connect_game_manager_signal()

func _initialize_health_bar() -> void:
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = current_health

func _disable_collision_with_environment() -> void:
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)

func _setup_attack_range() -> void:
	if not attack_range:
		attack_range = _find_collision_shape_in_area("AttackRange")
	if attack_range:
		var area = _get_area_parent(attack_range)
		if area:
			area.body_entered.connect(_on_attack_range_entered)
			area.body_exited.connect(_on_attack_range_exited)

func _setup_aggro_range() -> void:
	if not aggro_range:
		aggro_range = _find_collision_shape_in_area("AggroRange")
	if aggro_range:
		var area = _get_area_parent(aggro_range)
		if area:
			area.body_entered.connect(_on_aggro_body_entered)
			area.body_exited.connect(_on_aggro_body_exited)

func _find_collision_shape_in_area(area_name: String) -> CollisionShape2D:
	var area = get_node_or_null(area_name)
	if not area or not area is Area2D:
		return null
	var collision_shape = (area as Area2D).get_node_or_null("CollisionShape2D")
	return collision_shape if collision_shape else null

func _get_area_parent(collision_node: Node) -> Area2D:
	var parent = collision_node.get_parent()
	return parent if parent is Area2D else null

func _connect_game_manager_signal() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("day_started"):
		gm.day_started.connect(_on_day_started)

func _physics_process(delta: float) -> void:
	if animation_manager:
		animation_manager.update_animation(movement_direction, current_state == UNIT_STATE.ATTACKING)
	
	match current_state:
		UNIT_STATE.IDLE:
			_update_idle_state()
		UNIT_STATE.MOVING:
			_update_moving_state(delta)
		UNIT_STATE.ATTACKING:
			_update_attacking_state(delta)
		UNIT_STATE.DEAD:
			_update_death_state()
	
	move_and_slide()

func _update_idle_state() -> void:
	_find_nearby_enemy()
	if animation_manager:
		animation_manager.update_animation(Vector2.ZERO, false)

func _find_nearby_enemy() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= _get_attack_radius():
				set_target(enemy)
				break

func _update_moving_state(_delta: float) -> void:
	if not has_target:
		return
	var direction = (target_position - global_position).normalized()
	movement_direction = direction
	velocity = direction * move_speed
	
	if global_position.distance_to(target_position) < DEFAULT_MOVEMENT_TOLERANCE:
		has_target = false
		current_state = UNIT_STATE.IDLE
		velocity = Vector2.ZERO
		movement_direction = Vector2.ZERO

func _update_attacking_state(delta: float) -> void:
	if not is_instance_valid(target_enemy):
		current_state = UNIT_STATE.IDLE
		return
	
	movement_direction = (target_enemy.global_position - global_position).normalized()
	velocity = Vector2.ZERO
	
	var distance = global_position.distance_to(target_enemy.global_position)
	if distance > _get_attack_radius() + 1.0:
		target_enemy = null
		current_state = UNIT_STATE.IDLE
		return
	
	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown
	else:
		attack_timer -= delta

func _update_death_state() -> void:
	if not is_dying:
		_start_death()

func _perform_attack() -> void:
	if sound_component:
		sound_component.play_attack()
	
	if projectile_scene and is_instance_valid(target_enemy):
		_fire_projectile()
	elif is_instance_valid(target_enemy):
		_apply_melee_damage()

func _fire_projectile() -> void:
	var direction = (target_enemy.global_position - global_position).normalized()
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = muzzle.global_position if muzzle else global_position
	projectile.rotation = direction.angle()
	_configure_projectile_collision(projectile)

func _configure_projectile_collision(projectile: Node2D) -> void:
	if projectile.has_method("set_collision_layer_value"):
		projectile.set_collision_layer_value(1, false)
		projectile.set_collision_mask_value(1, false)
		projectile.set_collision_mask_value(2, true)

func _apply_melee_damage() -> void:
	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(attack_damage)

func _get_attack_radius() -> float:
	if not attack_range or not attack_range is CollisionShape2D:
		return 0.0
	var shape = (attack_range as CollisionShape2D).shape
	if not shape or not shape is CircleShape2D:
		return 0.0
	return float((shape as CircleShape2D).radius) * float((attack_range as CollisionShape2D).global_scale.x)

func _get_aggro_radius() -> float:
	if not aggro_range or not aggro_range is CollisionShape2D:
		return _get_attack_radius()
	var shape = (aggro_range as CollisionShape2D).shape
	if not shape or not shape is CircleShape2D:
		return 0.0
	return float((shape as CircleShape2D).radius) * float((aggro_range as CollisionShape2D).global_scale.x)

func take_damage(amount: int) -> void:
	if is_dying or current_state == UNIT_STATE.DEAD:
		return
	if _is_invulnerable():
		return
	
	current_health = max(0, current_health - amount)
	if health_bar:
		health_bar.value = current_health
	
	if sound_component:
		sound_component.play_hit()
	
	if current_health <= 0 and not is_dying:
		_start_death()

func _is_invulnerable() -> bool:
	return invulnerable_until > 0 and Time.get_ticks_msec() / 1000.0 < invulnerable_until

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	if health_bar:
		health_bar.value = current_health

func full_heal() -> void:
	current_health = max_health
	if health_bar:
		health_bar.value = current_health

func set_invulnerable(duration: float) -> void:
	invulnerable_until = Time.get_ticks_msec() / 1000.0 + duration

func _start_death() -> void:
	if is_dying:
		return
	is_dying = true
	current_state = UNIT_STATE.DEAD
	has_target = false
	target_enemy = null
	velocity = Vector2.ZERO
	movement_direction = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	_disable_collision_areas()
	_clear_enemy_aggro()
	if sound_component:
		sound_component.play_death()
	await _play_death_animation()
	queue_free()

func _disable_collision_areas() -> void:
	if attack_range:
		var area = _get_area_parent(attack_range)
		if area:
			area.set_deferred("monitoring", false)
	if aggro_range:
		var area = _get_area_parent(aggro_range)
		if area:
			area.set_deferred("monitoring", false)

func _clear_enemy_aggro() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("clear_aggro_target"):
			enemy.clear_aggro_target(self)

func _play_death_animation() -> void:
	if animation_manager:
		await animation_manager.play_death()
	else:
		await get_tree().create_timer(0.1).timeout

func set_target_position(pos: Vector2) -> void:
	target_position = pos
	has_target = true
	current_state = UNIT_STATE.MOVING

func set_target(enemy: Node) -> void:
	if is_instance_valid(enemy):
		target_enemy = enemy
		current_state = UNIT_STATE.ATTACKING

func _on_attack_range_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		set_target(body)

func _on_attack_range_exited(body: Node) -> void:
	if body.is_in_group("enemies") and body == target_enemy:
		target_enemy = null
		current_state = UNIT_STATE.IDLE

func _on_aggro_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("enemies") and body.has_method("set_aggro_target"):
		body.set_aggro_target(self)

func _on_aggro_body_exited(body: Node2D) -> void:
	if body and body.is_in_group("enemies") and body.has_method("clear_aggro_target"):
		body.clear_aggro_target(self)

func _on_day_started(_day: int) -> void:
	current_state = UNIT_STATE.IDLE
	has_target = false
	target_enemy = null
	velocity = Vector2.ZERO
	movement_direction = Vector2(0, 1)
	if animation_manager:
		animation_manager.update_animation(movement_direction, false)
