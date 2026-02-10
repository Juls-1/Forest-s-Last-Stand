extends Area2D

# Propiedades del proyectil
@export var speed: float = 800.0
@export var damage: int = 10
@export var max_distance: float = 1500.0  # Max distance before despawn

@onready var lifetime_timer: Timer = $LifetimeTimer

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var has_hit: bool = false

func _ready() -> void:
	# Add to projectile group
	add_to_group("projectiles")
	
	# Wait one frame for position and rotation to be set
	await get_tree().process_frame
	
	# Store starting position
	start_position = global_position
	
	# Set up direction and velocity based on rotation
	direction = Vector2.RIGHT.rotated(rotation)
	velocity = direction * speed
	
	# Connect lifetime timer (configurado en la escena con autostart=true)
	if lifetime_timer:
		lifetime_timer.timeout.connect(_on_lifetime_timeout)
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Mover el proyectil
	global_position += velocity * delta
	
	# Comprobar si supera la distancia máxima
	if global_position.distance_to(start_position) > max_distance:
		queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	# Golpear a un enemigo u obstáculo
	if has_hit:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		has_hit = true
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("player"):
		# Golpear terreno u otro obstáculo
		has_hit = true
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Golpear otra área (como la hitbox del enemigo)
	if has_hit:
		return
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		has_hit = true
		area.get_parent().take_damage(damage)
		queue_free()
