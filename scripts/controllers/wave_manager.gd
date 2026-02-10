class_name WaveManager
extends Node

# Señales
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemies_remaining_updated(count: int)
signal enemy_died(enemy)
signal enemy_reached_end()

# Configuración de las oleadas
@export var max_enemies_allowed: int = 3
@export var time_between_waves: float = 30.0
@export var initial_wave_delay: float = 5.0

# Estado de las oleadas
var current_wave: int = 0
var enemies_remaining: int = 0
var is_wave_active: bool = false
var wave_timer: float = 0.0
var spawners: Array = []

# Configuración de enemigos centralizada en EnemyConfig

# Referencias
@onready var enemies_node: Node2D = get_node_or_null("../Enemies") as Node2D
var enemy_scenes: Dictionary = {}

func _ready() -> void:
	set_process(false)
	# Precargar escenas de enemigos
	for enemy_type in EnemyConfig.ENEMIES:
		var path = EnemyConfig.ENEMIES[enemy_type].scene
		if not enemy_scenes.has(path):
			enemy_scenes[path] = load(path)

# Inicia la oleada correspondiente al día actual (oleada = día; así no se reinicia al volver de town).
func start_wave_for_day(day: int) -> void:
	current_wave = day
	is_wave_active = true

	# Obtener configuración de la oleada según el día
	var data = load_wave_data(current_wave)
	enemies_remaining = data.enemy_count

	# Emitir señal de inicio de oleada
	wave_started.emit(current_wave)
	enemies_remaining_updated.emit(enemies_remaining)

	# Buscar spawners y distribuir el número de enemigos
	var spawners = get_tree().get_nodes_in_group("spawn_points")
	if spawners.is_empty():
		push_error("No se encontraron nodos con el grupo 'spawn_points'")
		return

	var per_spawner = int(ceil(float(enemies_remaining) / spawners.size()))
	var remaining = enemies_remaining

	for spawner in spawners:
		var to_spawn = min(per_spawner, remaining)
		if to_spawn <= 0:
			break
		_configure_spawner(spawner, data, to_spawn)
		remaining -= to_spawn

# Genera enemigos
func _spawn_enemies(count: int) -> void:
	var active_spawners = _get_active_spawners()
	if active_spawners.is_empty():
		push_error("No hay spawners activos")
		return
	
	for i in range(count):
		var spawner = active_spawners[randi() % active_spawners.size()]
		var enemy_type = _get_random_enemy_type()
		var enemy_scene = enemy_scenes[EnemyConfig.ENEMIES[enemy_type].scene]
		
		# Crear instancia del enemigo
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawner.global_position
		
		# Configurar propiedades del enemigo
		var config = EnemyConfig.ENEMIES[enemy_type]
		enemy.health = config.health
		enemy.speed = config.speed
		enemy.damage = config.damage
		enemy.gold_value = config.gold_drop
		enemy.set_meta("enemy_type", enemy_type)
		
		# Conectar señales (la contabilidad de muertes llega vía spawners)
		
		# Añadir a la escena
		enemies_node.add_child(enemy)
		
		# Pequeño retraso entre generaciones
		await get_tree().create_timer(0.5).timeout

# Calcula la configuración de enemigos para la oleada dada (EnemyConfig)
func load_wave_data(wave: int) -> Dictionary:
	var types = EnemyConfig.types_for_wave(wave)
	var count = EnemyConfig.enemy_count_for_wave(wave)
	var rate = EnemyConfig.spawn_rate_for_wave(wave)
	return {"enemy_count": count, "enemy_types": types, "spawn_rate": rate}

# Configura un punto de aparición con los parámetros de la oleada
func _configure_spawner(spawner, data: Dictionary, count: int) -> void:
	var enemy_type = data.enemy_types[randi() % data.enemy_types.size()]

	var scene_path = EnemyConfig.ENEMIES[enemy_type].scene
	if not enemy_scenes.has(scene_path):
		enemy_scenes[scene_path] = load(scene_path)

	spawner.enemy_scene = enemy_scenes[scene_path]
	spawner.spawn_delay = data.spawn_rate
	spawner.spawn_count = count

	# Reconectar señales del spawner hacia este WaveManager
	if spawner.all_enemies_spawned.is_connected(_on_all_enemies_spawned):
		spawner.all_enemies_spawned.disconnect(_on_all_enemies_spawned)
	if spawner.enemy_died.is_connected(_on_spawner_enemy_died):
		spawner.enemy_died.disconnect(_on_spawner_enemy_died)
	if spawner.enemy_reached_end.is_connected(_on_spawner_enemy_reached_end):
		spawner.enemy_reached_end.disconnect(_on_spawner_enemy_reached_end)

	spawner.all_enemies_spawned.connect(_on_all_enemies_spawned.bind(spawner))
	spawner.enemy_died.connect(_on_spawner_enemy_died)
	spawner.enemy_reached_end.connect(_on_spawner_enemy_reached_end)

	spawner.start_spawning({
		"wave_number": current_wave,
		"enemy_count": count,
		"enemy_type": enemy_type
	})

# Obtiene un tipo de enemigo aleatorio basado en pesos
func _get_random_enemy_type() -> String:
	var types = EnemyConfig.types_for_wave(current_wave)
	return EnemyConfig.random_type_weighted(types)

# Maneja la muerte de un enemigo notificada por un spawner
func _on_spawner_enemy_died(enemy: Node2D = null) -> void:
	if enemy != null:
		enemy_died.emit(enemy)
	enemies_remaining -= 1
	enemies_remaining_updated.emit(enemies_remaining)
	if enemies_remaining <= 0:
		_wave_completed()

# Maneja cuando un enemigo llega al final notificado por un spawner
func _on_spawner_enemy_reached_end() -> void:
	enemy_reached_end.emit()
	enemies_remaining -= 1
	enemies_remaining_updated.emit(enemies_remaining)
	if enemies_remaining <= 0:
		_wave_completed()

# Marca la oleada como completada
func _wave_completed() -> void:
	is_wave_active = false
	wave_timer = time_between_waves
	wave_completed.emit(current_wave)

# Obtiene los spawners activos
func _get_active_spawners() -> Array:
	if spawners.is_empty():
		spawners = get_tree().get_nodes_in_group("spawn_points")
	return spawners

func _on_all_enemies_spawned(spawner) -> void:
	if spawner.all_enemies_spawned.is_connected(_on_all_enemies_spawned):
		spawner.all_enemies_spawned.disconnect(_on_all_enemies_spawned)

# Reinicia el gestor de oleadas
func reset() -> void:
	current_wave = 0
	enemies_remaining = 0
	is_wave_active = false
	wave_timer = initial_wave_delay
