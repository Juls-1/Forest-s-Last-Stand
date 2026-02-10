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

# Enemy state
var target: Node2D = null
var last_target_position: Vector2 = Vector2.ZERO
var is_active: bool = true
var is_attacking: bool = false
var attack_animation_timer: float = 0.0
var last_aggro_target: Node2D = null

@export var max_health: int = 30
@export var speed: float = 50.0
@export var damage: int = 10
@export var gold_value: int = 5

@export var enemy_type: String = "basic"  # "basic", "tank", "explorer" etc.

# Signals
signal died(enemy)
signal reached_end

func _ready():
	add_to_group("enemies")
	
	_ensure_components()
	
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		health_component.died.connect(_on_died)
		health_component.health_changed.connect(_on_health_changed)
	
	if hit_box:
		if not hit_box.area_entered.is_connected(_on_hit_box_entered):
			hit_box.area_entered.connect(_on_hit_box_entered)
	
	if attack_component:
		attack_component.damage = damage
		attack_component.attacked.connect(_on_attacked)
	
	if aggro_component:
		aggro_component.enemy_type = enemy_type
	
	if movement_component:
		movement_component.speed = speed
	
	# Find initial target
	var possible_targets = get_tree().get_nodes_in_group("target")
	if not possible_targets.is_empty():
		target = possible_targets[0]
		if movement_component:
			movement_component.set_target_position(target.global_position)

func _ensure_components():
	# 1. AggroComponent
	if not aggro_component:
		var aggro_node = get_node_or_null("AggroComponent")
		if not aggro_node:
			aggro_node = AggroComponent.new()
			aggro_node.name = "AggroComponent"
			add_child(aggro_node)
		aggro_component = aggro_node
	
	# 2. AnimationComponent
	if not animation_component:
		var anim_node = get_node_or_null("AnimationComponent")
		if not anim_node:
			anim_node = get_node_or_null("AnimationManager")
		animation_component = anim_node

	# 3. HealthComponent
	if not health_component:
		var health_node = get_node_or_null("HealthComponent")
		if not health_node:
			health_node = HealthComponent.new()
			health_node.name = "HealthComponent"
			add_child(health_node)
		health_component = health_node

	# 4. MovementComponent
	if not movement_component:
		var move_node = get_node_or_null("MovementComponent")
		if not move_node:
			move_node = MovementComponent.new()
			move_node.name = "MovementComponent"
			add_child(move_node)
			move_node.character_body = self
			if move_node.navigation_agent_path.is_empty():
				var nav = get_node_or_null("NavigationAgent2D")
				if nav: move_node.navigation_agent = nav
		movement_component = move_node

	# 5. AttackComponent
	if not attack_component:
		var atk_node = get_node_or_null("AttackComponent")
		if not atk_node:
			atk_node = AttackComponent.new()
			atk_node.name = "AttackComponent"
			add_child(atk_node)
		attack_component = atk_node
	
	# 6. SoundComponent
	if not sound_component:
		var snd_node = get_node_or_null("SoundComponent")
		if not snd_node:
			snd_node = SoundComponent.new()
			snd_node.name = "SoundComponent"
			add_child(snd_node)
		sound_component = snd_node

func _on_health_changed(new_health: int, _max_val: int):
	if health_bar:
		health_bar.value = new_health

func _physics_process(delta: float):
	if not is_active:
		return 

	if attack_animation_timer > 0:
		attack_animation_timer -= delta
		if attack_animation_timer <= 0:
			is_attacking = false 

	var current_aggro_target = aggro_component.get_current_target() if aggro_component else null
	var current_target = current_aggro_target if is_instance_valid(current_aggro_target) else target 
	
	if not is_instance_valid(current_target):
		var possible_targets = get_tree().get_nodes_in_group("target")
		if not possible_targets.is_empty():
			target = possible_targets[0] 
			current_target = target
		else:
			return

	var distance = global_position.distance_to(current_target.global_position)
	
	if attack_component:

		attack_component.target = current_target 
		
		if distance <= attack_component.attack_range:
			# Dentro del rango de ataque
			# Detener movimiento al entrar en estado de ataque
			if movement_component:
				# cancelar objetivo de movimiento y detener agente
				movement_component.has_target = false
				if movement_component.navigation_agent:
					movement_component.navigation_agent.set_velocity(Vector2.ZERO)
					movement_component.navigation_agent.target_position = global_position
				# detener la velocidad física
				velocity = Vector2.ZERO
				move_and_slide()
			if attack_component.can_attack():
				attack_component.perform_attack() 
				is_attacking = true
				attack_animation_timer = 0.5 
		
		elif movement_component:
			movement_component.set_target_position(current_target.global_position) 
			movement_component.move_towards_target(delta) 

	if animation_component:
		var move_dir = velocity.normalized()
		animation_component.update_animation(move_dir, is_attacking, current_target) 

	if not current_aggro_target and target and distance < 50.0:
		reached_end.emit()
		_on_died() 

func _on_died(_unit=null):
	if not is_active:
		return
	is_active = false
	died.emit(self)
	
	if sound_component:
		sound_component.play_death()

	if animation_component:
		await animation_component.play_death()
	
	queue_free()

func _on_attacked(target: Node2D):
	is_attacking = true
	attack_animation_timer = 0.5
	if sound_component:
		sound_component.play_attack()

func _on_hit_box_entered(area: Area2D):
	if area.is_in_group("projectiles"):
		if "damage" in area:
			if health_component:
				health_component.take_damage(area.damage)
				if sound_component: sound_component.play_hit()
		area.queue_free()

func set_aggro_target(unit: Node2D):
	if aggro_component:
		aggro_component.set_aggro_target(unit)

func clear_aggro_target(unit: Node2D):
	if aggro_component:
		aggro_component.clear_aggro_target(unit)

func take_damage(amount: int):
	if health_component:
		health_component.take_damage(amount)
		if sound_component: sound_component.play_hit()

func set_speed_modifier(modifier: float) -> void:
	"""Set speed modifier for spells like SLOW"""
	if movement_component:
		movement_component.set_speed_modifier(modifier)
