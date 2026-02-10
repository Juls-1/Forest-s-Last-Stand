class_name BaseUnit
extends CharacterBody2D

# Base stats
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
var current_state = UNIT_STATE.IDLE
var current_health: int
var attack_timer: float = 0.0
var is_dying: bool = false

var target_position: Vector2
var movement_direction: Vector2 = Vector2.ZERO
var has_target: bool = false
var target_enemy = null

var invulnerable_until: float = -1.0

func _ready():
	_ensure_sound_component()
	current_health = max_health
	if health_bar:
		health_bar.min_value=0
		health_bar.max_value=max_health
		health_bar.value=current_health
	add_to_group("friendly_units")

	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)

	if attack_range == null:
		var attack_area := get_node_or_null("AttackRange")
		if attack_area and attack_area is Area2D:
			var cs: Node = (attack_area as Area2D).get_node_or_null("CollisionShape2D")
			if cs == null:
				cs = (attack_area as Area2D).get_node_or_null("AttackRange")
			if cs and cs is CollisionShape2D:
				attack_range = cs

	var attack_area_to_connect: Area2D = null
	if attack_range and attack_range is CollisionShape2D and (attack_range as CollisionShape2D).get_parent() and (attack_range as CollisionShape2D).get_parent() is Area2D:
		attack_area_to_connect = (attack_range as CollisionShape2D).get_parent()
	else:
		var ar := get_node_or_null("AttackRange")
		if ar and ar is Area2D:
			attack_area_to_connect = ar
	if attack_area_to_connect:
		if not attack_area_to_connect.body_entered.is_connected(_on_attack_range_entered):
			attack_area_to_connect.body_entered.connect(_on_attack_range_entered)
		if not attack_area_to_connect.body_exited.is_connected(_on_attack_range_exited):
			attack_area_to_connect.body_exited.connect(_on_attack_range_exited)
	
	if aggro_range == null:
		var aggro_area := get_node_or_null("AggroRange")
		if aggro_area and aggro_area is Area2D:
			var cs2 := (aggro_area as Area2D).get_node_or_null("CollisionShape2D")
			if cs2 == null:
				cs2 = (aggro_area as Area2D).get_node_or_null("AggroRange")
			if cs2 and cs2 is CollisionShape2D:
				aggro_range = cs2

	var aggro_area_to_connect: Area2D = null
	var aggro_parent := (aggro_range as Node) if aggro_range else null
	if aggro_parent and aggro_parent is CollisionShape2D and (aggro_parent as CollisionShape2D).get_parent() and (aggro_parent as CollisionShape2D).get_parent() is Area2D:
		aggro_area_to_connect = (aggro_parent as CollisionShape2D).get_parent()
	else:
		var agr := get_node_or_null("AggroRange")
		if agr and agr is Area2D:
			aggro_area_to_connect = agr
	if aggro_area_to_connect:
		if not aggro_area_to_connect.body_entered.is_connected(_on_aggro_body_entered):
			aggro_area_to_connect.body_entered.connect(_on_aggro_body_entered)
		if not aggro_area_to_connect.body_exited.is_connected(_on_aggro_body_exited):
			aggro_area_to_connect.body_exited.connect(_on_aggro_body_exited)

	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("day_started"):
		gm.day_started.connect(_on_day_started)

func _ensure_sound_component():
	if not sound_component:
		var snd_node = get_node_or_null("SoundComponent")
		if not snd_node:
			snd_node = SoundComponent.new()
			snd_node.name = "SoundComponent"
			add_child(snd_node)
		sound_component = snd_node

func _physics_process(delta):
	if animation_manager:
		animation_manager.update_animation(movement_direction, current_state == UNIT_STATE.ATTACKING)
	
	match current_state:
		UNIT_STATE.IDLE:
			handle_idle()
		UNIT_STATE.MOVING:
			handle_movement(delta)
		UNIT_STATE.ATTACKING:
			handle_attack(delta)
		UNIT_STATE.DEAD:
			handle_death()
	move_and_slide()

func handle_idle():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= _get_attack_radius():
			set_target(enemy)
			break
	if animation_manager:
		animation_manager.update_animation(Vector2.ZERO, false)

func handle_movement(_delta):
	if has_target:
		var direction = (target_position - global_position).normalized()
		movement_direction = direction
		velocity = direction * move_speed
		if global_position.distance_to(target_position) < 10.0:
			has_target = false
			current_state = UNIT_STATE.IDLE
			velocity = Vector2.ZERO
			movement_direction = Vector2.ZERO

func handle_attack(delta):
	if not is_instance_valid(target_enemy):
		current_state = UNIT_STATE.IDLE
		return
	movement_direction = (target_enemy.global_position - global_position).normalized()
	velocity = Vector2.ZERO 
	var dist := global_position.distance_to(target_enemy.global_position)
	var max_r := _get_attack_radius()
	if dist > max_r + 1.0:
		target_enemy = null
		current_state = UNIT_STATE.IDLE
		return
	if attack_timer <= 0:
		perform_attack()
		attack_timer = attack_cooldown
	else:
		attack_timer -= delta

func perform_attack():
	if sound_component: sound_component.play_attack()
	
	if projectile_scene and is_instance_valid(target_enemy):
		var dir = (target_enemy.global_position - global_position).normalized()
		var angle = dir.angle()
		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		projectile.global_position = (muzzle.global_position if muzzle else global_position)
		projectile.rotation = angle
		if projectile.has_method("set_collision_layer_value"):
			projectile.set_collision_layer_value(1, false)
			projectile.set_collision_mask_value(1, false)
			projectile.set_collision_mask_value(2, true)
	elif is_instance_valid(target_enemy) and target_enemy.has_method("take_damage"):
		target_enemy.take_damage(attack_damage)

func _get_attack_radius() -> float:
	if attack_range and attack_range is CollisionShape2D:
		var shape := (attack_range as CollisionShape2D).shape
		if shape and shape is CircleShape2D:
			return float((shape as CircleShape2D).radius) * float((attack_range as CollisionShape2D).global_scale.x)
	return 0.0

func _get_aggro_radius() -> float:
	if aggro_range and aggro_range is CollisionShape2D:
		var shp = (aggro_range as CollisionShape2D).shape
		if shp and shp is CircleShape2D:
			return float((shp as CircleShape2D).radius) * float((aggro_range as CollisionShape2D).global_scale.x)
	return _get_attack_radius()

func full_heal() -> void:
	current_health = max_health
	if health_bar:
		health_bar.value = current_health

func set_invulnerable(duration: float) -> void:
	invulnerable_until = Time.get_ticks_msec() / 1000.0 + duration

func take_damage(amount: int):
	if is_dying or current_state == UNIT_STATE.DEAD:
		return
	if invulnerable_until > 0 and Time.get_ticks_msec() / 1000.0 < invulnerable_until:
		return
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	
	if sound_component: sound_component.play_hit()
	
	if current_health <= 0:
		current_health = 0
		if not is_dying:
			_start_death()

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
	set_collision_layer(0)
	set_collision_mask(0)
	var attack_area_to_disable: Area2D = (attack_range.get_parent() if attack_range and attack_range.get_parent() is Area2D else get_node_or_null("AttackRange"))
	if attack_area_to_disable: attack_area_to_disable.set_deferred("monitoring", false)
	var aggro_area_to_disable: Area2D = (aggro_range.get_parent() if aggro_range and aggro_range.get_parent() is Area2D else get_node_or_null("AggroRange"))
	if aggro_area_to_disable: aggro_area_to_disable.set_deferred("monitoring", false)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("clear_aggro_target"):
			e.clear_aggro_target(self)
	
	if sound_component: sound_component.play_death()
	
	if animation_manager:
		await animation_manager.play_death()
	else:
		await get_tree().create_timer(0.1).timeout
	queue_free()

func set_target_position(pos: Vector2):
	target_position = pos
	has_target = true
	current_state = UNIT_STATE.MOVING

func set_target(enemy):
	if is_instance_valid(enemy):
		target_enemy = enemy
		current_state = UNIT_STATE.ATTACKING

func handle_death():
	if not is_dying:
		_start_death()

func _on_attack_range_entered(body):
	if body.is_in_group("enemies"):
		set_target(body)

func _on_attack_range_exited(body):
	if body.is_in_group("enemies"):
		if body == target_enemy:
			target_enemy = null
			current_state = UNIT_STATE.IDLE

func _on_aggro_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("enemies"):
		if body.has_method("set_aggro_target"):
			body.set_aggro_target(self)

func _on_aggro_body_exited(body: Node2D) -> void:
	if body and body.is_in_group("enemies"):
		if body.has_method("clear_aggro_target"):
			body.clear_aggro_target(self)

func _on_day_started(_day: int) -> void:
	current_state = UNIT_STATE.IDLE
	has_target = false
	target_enemy = null
	velocity = Vector2.ZERO
	movement_direction = Vector2(0, 1)
	if animation_manager:
		animation_manager.update_animation(movement_direction, false)
