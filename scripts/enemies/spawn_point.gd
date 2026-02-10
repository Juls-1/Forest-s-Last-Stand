extends Node2D
class_name SpawnPoint

# Configuration
@export var spawn_radius: float = 50.0
@export var spawn_delay: float = 1.0
@export var spawn_count: int = 1
@export var wave_enemy_count: int = 1
@export var enemy_scene: PackedScene

# Signals
signal enemy_spawned(enemy: Node2D)
signal all_enemies_spawned()
signal enemy_died(enemy: Node2D)
signal enemy_reached_end()

# State
var current_wave: int = 0
var enemies_to_spawn: int = 0
var is_active: bool = false
var spawn_timer: float = 0.0
var navigation_region: NavigationRegion2D

func _ready() -> void:
	add_to_group("spawn_points")
	set_process(false)
	
	# Find the navigation region in the scene
	var root = get_tree().get_root()
	for child in root.get_children():
		if child is NavigationRegion2D:
			navigation_region = child
			break

# Proceso principal del generador: maneja la cadencia de aparición y notifica cuando termina
func _process(delta):
	if not is_active or enemies_to_spawn <= 0:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = spawn_delay
		enemies_to_spawn -= 1
		if enemies_to_spawn <= 0:
			all_enemies_spawned.emit()
			set_process(false)

# Inicia la generación de enemigos a partir de los datos de la oleada
func start_spawning(wave_data: Dictionary) -> void:
	if not enemy_scene:
		push_error("¡No hay escena de enemigo asignada al generador!")
		return
	
	current_wave = wave_data.get("wave_number", 1)
	enemies_to_spawn = wave_data.get("enemy_count", 1)
	
	if enemies_to_spawn > 0:
		is_active = true
		spawn_timer = 0.0  # Spawn first enemy immediately
		set_process(true)

# Instancia un enemigo, lo añade al nodo Enemies y conecta sus señales relevantes
func spawn_enemy() -> void:
	if not enemy_scene:
		push_error("¡No hay escena de enemigo asignada al generador!")
		return
	
	var enemy = enemy_scene.instantiate()
	var spawn_pos = global_position + Vector2(
		randf_range(-spawn_radius, spawn_radius), 
		randf_range(-spawn_radius, spawn_radius)
	)
	
	# Add to the Enemies node in the scene
	var enemies_node = get_tree().get_root().find_child("Enemies", true, false)
	if enemies_node:
		enemies_node.add_child(enemy)
		enemy.global_position = spawn_pos
		
		# Set up navigation agent if it exists
		if enemy.has_node("NavigationAgent2D"):
			var nav_agent = enemy.get_node("NavigationAgent2D")
			if navigation_region:
				nav_agent.navigation_layers = navigation_region.navigation_layers
		
		# Conectar señales con comprobaciones
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
			
		if enemy.has_signal("reached_end"):
			enemy.reached_end.connect(_on_enemy_reached_end.bind(enemy))
		
		emit_signal("enemy_spawned", enemy)
	else:
		push_error("¡No se pudo encontrar el nodo 'Enemies' en la escena!")

# Reenvía la señal de muerte del enemigo hacia los sistemas superiores
func _on_enemy_died(enemy: Node2D) -> void:
	# Evitar doble conteo si ya alcanzó el final
	if enemy and enemy.has_meta("reached_end") and enemy.get_meta("reached_end") == true:
		return
	# Reenviar la señal de muerte del enemigo
	enemy_died.emit(enemy)

# Reenvía el evento de enemigo que alcanzó el final hacia los sistemas superiores
func _on_enemy_reached_end(enemy: Node2D) -> void:
	# Marcar para evitar doble conteo si luego muere por daño rezagado
	if enemy:
		enemy.set_meta("reached_end", true)
	# Reenviar la señal de enemigo que alcanzó el final
	enemy_reached_end.emit()
