extends Node2D

@export var max_enemies_allowed: int = 3

var current_day: int = 0
var is_night: bool = false
var game_paused: bool = false
var game_over_triggered: bool = false

# Estado de oleadas
var enemies_remaining: int = 0
var current_wave: int = 0
var active_spawners: Array = []
var enemies_reached_entrance: int = 0
var wave_ending: bool = false

var current_location: String = "world"

# Recursos: única fuente de verdad en ResourceManager; getters para compatibilidad con HUD y persistencia
var gold: int: get = _get_gold
var wood: int: get = _get_wood
var stone: int: get = _get_stone

# Tiers de herramientas (1–3); usados en market y woodchopper
var axe_tier: int = 1
var pickaxe_tier: int = 1

const INITIAL_GOLD: int = 100
const INITIAL_WOOD: int = 100
const INITIAL_STONE: int = 100

signal day_started(day: int)
signal night_started
signal resources_updated(resources: Dictionary)
signal game_over(reason: String)
signal wave_updated(enemies_remaining: int, current_wave: int)
signal day_changed(day: int)
signal enemy_reached_entrance_signal(count: int)


@onready var enemies_node: Node2D = _get_or_create("Enemies")
var canvas_modulate: CanvasModulate

@onready var resource_manager: Node = get_parent().get_node("ResourceManager")
@onready var unit_manager: Node = get_parent().get_node("UnitManager")
@onready var wave_manager: Node = get_node_or_null("WaveManager")  # Solo en world; town no tiene oleadas
var placement_manager: Node


func _ready():
	add_to_group("game_manager")
	
	resource_manager.add_to_group("resource_manager")

	await get_tree().process_frame

	placement_manager = get_parent().get_node_or_null("PlacementManager")

	_find_canvas_modulate()
	_connect_signals()

	var data = SessionPersistence.load_session()
	var restored_from_meta: bool = false

	if data.location in ["world", "town"]:
		current_location = data.location

	if data.game_state:
		restored_from_meta = true
		var gs: Dictionary = data.game_state
		if resource_manager.has_method("set_resources_bulk"):
			resource_manager.set_resources_bulk(
				int(gs.get("gold", INITIAL_GOLD)),
				int(gs.get("wood", 0)),
				int(gs.get("stone", 0))
			)
		current_day = int(gs.get("current_day", current_day))
		is_night = bool(gs.get("is_night", false))
		current_wave = int(gs.get("current_wave", current_wave))
		enemies_remaining = int(gs.get("enemies_remaining", enemies_remaining))
		enemies_reached_entrance = int(gs.get("enemies_reached_entrance", enemies_reached_entrance))
		axe_tier = int(gs.get("axe_tier", 1))
		pickaxe_tier = int(gs.get("pickaxe_tier", 1))

		if is_night:
			transition_to_night()
			wave_updated.emit(enemies_remaining, current_wave)
			enemy_reached_entrance_signal.emit(enemies_reached_entrance)
		else:
			transition_to_day()
			day_changed.emit(current_day)

		if current_location == "world" and data.units_state is Array and data.units_state.size() > 0:
			if unit_manager.has_method("restore_state"):
				unit_manager.restore_state(data.units_state, true)
				SessionPersistence.clear_cached_units_state()

	if wave_manager:
		if wave_manager.has_signal("enemies_remaining_updated"):
			wave_manager.enemies_remaining_updated.connect(func(count): _on_wave_updated(count, wave_manager.current_wave if "current_wave" in wave_manager else current_wave))
		if wave_manager.has_signal("wave_completed"):
			wave_manager.wave_completed.connect(func(_w): end_wave())
		if wave_manager.has_signal("enemy_died"):
			wave_manager.enemy_died.connect(_on_enemy_died)
		if wave_manager.has_signal("enemy_reached_end"):
			wave_manager.enemy_reached_end.connect(_on_enemy_reached_end)

	if resource_manager.has_signal("resources_updated"):
		resource_manager.resources_updated.connect(_on_resources_updated)

	if placement_manager:
		if placement_manager.has_signal("unit_placed"):
			placement_manager.unit_placed.connect(_on_unit_placed)
	else:
		push_error("[GameManager] PlacementManager not found")

	# Inicializar recursos por defecto si es partida nueva (no se restauró desde meta)
	if resource_manager.has_method("set_resources_bulk") and not restored_from_meta:
		resource_manager.set_resources_bulk(INITIAL_GOLD, INITIAL_WOOD, INITIAL_STONE)

	if current_day <= 0:
		start_new_day()

# ------------------------------------------------------------------------------
func _get_gold() -> int:
	return resource_manager.get_resource("gold") if resource_manager.has_method("get_resource") else 0

func _get_wood() -> int:
	return resource_manager.get_resource("wood") if resource_manager.has_method("get_resource") else 0

func _get_stone() -> int:
	return resource_manager.get_resource("stone") if resource_manager.has_method("get_resource") else 0

# ------------------------------------------------------------------------------
func _get_or_create(node_name: String) -> Node2D:
	""" Crea un nodo hijo si no existe, o lo devuelve si ya existe """
	if has_node(node_name):
		return get_node(node_name)

	var n = Node2D.new()
	n.name = node_name
	add_child(n)
	return n

# ------------------------------------------------------------------------------
func _find_canvas_modulate():
	""" Busca el nodo CanvasModulate para las transiciones día/noche """
	canvas_modulate = get_tree().get_first_node_in_group("canvas_modulate")
	if not canvas_modulate:
		push_warning("No se encontró CanvasModulate – las transiciones día/noche no funcionarán")

# ------------------------------------------------------------------------------
func _connect_signals():
	""" Conecta las señales internas del gestor. No conectar wave_updated a _on_wave_updated (esa se llama solo desde WaveManager; emitir wave_updated desde ahí provocaría recursión). """
	day_started.connect(_on_day_started)
	night_started.connect(_on_night_started)


func start_new_day():
	if game_over_triggered:
		return

	current_day += 1
	is_night = false
	enemies_reached_entrance = 0

	transition_to_day()
	day_started.emit(current_day)
	day_changed.emit(current_day)

	heal_all_units(0.2)


func start_night():
	if is_night:
		return
	if current_location != "world":
		return

	is_night = true
	transition_to_night()
	night_started.emit()

	start_wave()


func transition_to_day():
	if canvas_modulate:
		create_tween().tween_property(canvas_modulate, "color", Color(1, 1, 1, 1), 1.5)

# ------------------------------------------------------------------------------
func transition_to_night():
	if canvas_modulate:
		create_tween().tween_property(canvas_modulate, "color", Color(0.357, 0.358, 0.58, 1.0), 1.5)

func start_wave():
	if not wave_manager:
		push_error("[GameManager] WaveManager no encontrado; la escena world debe incluir el nodo WaveManager.")
		return
	# La oleada depende del día actual: día 1 = oleada 1, día 2 = oleada 2, etc. (no se reinicia al volver de town).
	if wave_manager.has_method("start_wave_for_day"):
		wave_manager.start_wave_for_day(current_day)
	else:
		push_error("[GameManager] WaveManager no tiene el método start_wave_for_day.")


# ==============================================================================
# GESTIÓN DE EVENTOS DE ENEMIGOS
# ==============================================================================

func _on_enemy_died(enemy = null):
	""" Maneja la muerte de un enemigo """
	if enemy:
		var drop = 0
		if "gold_value" in enemy:
			drop = int(enemy.gold_value)
		else:
			var tipo = enemy.get_meta("enemy_type") if enemy.has_meta("enemy_type") else "basic"
			drop = EnemyConfig.ENEMIES.get(tipo, EnemyConfig.ENEMIES.get("basic")).gold_drop
		if resource_manager.has_method("add_resources"):
			resource_manager.add_resources(drop, 0, 0)

	# Si existe WaveManager, no modificar conteos aquí (lo gestiona el controlador)
	if wave_manager:
		return

	enemies_remaining = max(0, enemies_remaining - 1)
	wave_updated.emit(enemies_remaining, current_wave)
	if enemies_remaining <= 0:
		end_wave()

func start_defense():
	# Método auxiliar para UI: inicia defensa (fase de noche)
	start_night()

# ------------------------------------------------------------------------------
func enemy_reached_entrance() -> void:
	""" Maneja cuando un enemigo llega a la entrada del bosque """
	if game_over_triggered:
		return

	enemies_reached_entrance += 1
	enemy_reached_entrance_signal.emit(enemies_reached_entrance)

	if enemies_reached_entrance >= max_enemies_allowed:
		trigger_game_over("¡Demasiados enemigos llegaron a la entrada del bosque!")
		return

	# Si WaveManager gestiona el conteo, no decrementar ni emitir aquí
	if wave_manager:
		return

	enemies_remaining = max(0, enemies_remaining - 1)
	wave_updated.emit(enemies_remaining, current_wave)

# ------------------------------------------------------------------------------
func _on_enemy_reached_end():
	""" Callback cuando un enemigo llega al final del camino """
	enemy_reached_entrance()

# ==============================================================================
# FINALIZACIÓN DE OLEADA
# ==============================================================================

func end_wave():
	""" Finaliza la oleada actual y prepara el siguiente día """
	if game_over_triggered or wave_ending or not is_night:
		return

	wave_ending = true

	_disconnect_all_spawners()
	active_spawners.clear()

	show_successful_defend_message()

	# Esperamos un momento antes de pasar al siguiente día
	await get_tree().create_timer(2.0).timeout

	is_night = false
	start_new_day()

# ------------------------------------------------------------------------------
func _disconnect_all_spawners():
	""" Desconecta todas las señales de los puntos de aparición """
	for spawner in get_tree().get_nodes_in_group("spawn_points"):
		if spawner.enemy_died.is_connected(_on_enemy_died):
			spawner.enemy_died.disconnect(_on_enemy_died)
		if spawner.enemy_reached_end.is_connected(_on_enemy_reached_end):
			spawner.enemy_reached_end.disconnect(_on_enemy_reached_end)

# ------------------------------------------------------------------------------
func _clear_existing_enemies():
	""" Elimina todos los enemigos existentes """
	if is_instance_valid(enemies_node):
		for e in enemies_node.get_children():
			e.queue_free()

# ------------------------------------------------------------------------------
func show_successful_defend_message():
	""" Muestra un mensaje de defensa exitosa """
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("show_wave_complete_message"):
		hud.show_wave_complete_message(current_wave)

# ==============================================================================
# GESTIÓN DE UNIDADES ALIADAS
# ==============================================================================

func can_afford_unit(unit_type: String) -> bool:
	""" Verifica si hay suficientes recursos para reclutar una unidad (delega en ResourceManager). """
	return resource_manager.has_method("can_afford_unit") and resource_manager.can_afford_unit(unit_type)

# ------------------------------------------------------------------------------
func recruit_unit(unit_type: String, spawn_position: Vector2) -> void:
	""" Recluta una nueva unidad (delega en UnitManager). """
	if not unit_manager.has_method("recruit_unit"):
		push_error("[GameManager] UnitManager no tiene el método recruit_unit.")
		return
	unit_manager.recruit_unit(unit_type, spawn_position)

# ------------------------------------------------------------------------------
func heal_all_units(heal_percentage: float) -> void:
	""" Cura todas las unidades aliadas (delega en UnitManager). """
	if unit_manager.has_method("heal_all_units"):
		unit_manager.heal_all_units(heal_percentage)

# ==============================================================================
# GESTIÓN DE RECURSOS
# ==============================================================================

func update_resources(gold_delta: int = 0, wood_delta: int = 0, stone_delta: int = 0) -> void:
	""" Actualiza los recursos económicos (única fuente de verdad: ResourceManager). """
	if not resource_manager.has_method("add_resources"):
		push_error("[GameManager] ResourceManager no tiene el método add_resources.")
		return
	resource_manager.add_resources(gold_delta, wood_delta, stone_delta)

# ------------------------------------------------------------------------------
func reward_minigame(rewards: Dictionary):
	""" Otorga recursos como recompensa de un minijuego """
	update_resources(
		rewards.get("gold", 0),
		rewards.get("wood", 0),
		rewards.get("stone", 0)
	)

# ==============================================================================
# GESTIÓN DEL FIN DEL JUEGO
# ==============================================================================

func trigger_game_over(reason: String) -> void:
	""" Activa el estado de fin del juego """
	if game_over_triggered:
		return

	game_over_triggered = true
	game_paused = true

	game_over.emit(reason)

	# Buscamos o creamos la interfaz de fin del juego
	var game_over_ui = get_tree().get_first_node_in_group("game_over_ui")
	if not game_over_ui:
		var packed = load("res://scenes/ui/game_over.tscn")
		if packed:
			game_over_ui = packed.instantiate()
			game_over_ui.add_to_group("game_over_ui")
			get_tree().root.add_child(game_over_ui)

	if game_over_ui and game_over_ui.has_method("show_game_over"):
		game_over_ui.show_game_over(reason)

# ==============================================================================
# CONTROLES DE DEBUG (ELIMINAR EN VERSIÓN FINAL)
# ==============================================================================

func _input(event):
	""" Maneja controles de teclado para desarrollo """
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_N:
				if current_location == "world" and not is_night:
					start_night()
			KEY_D:
				if is_night and enemies_remaining <= 0:
					end_wave()
			KEY_1:
				if current_location == "world" and not is_night and can_afford_unit("archer"):
					recruit_unit("archer", get_global_mouse_position())
			KEY_2:
				if current_location == "world" and not is_night and can_afford_unit("soldier"):
					recruit_unit("soldier", get_global_mouse_position())
			KEY_ESCAPE:
				if placement_manager and placement_manager.is_placing:
					placement_manager.cancel_placement()

	# Modo colocación: clic izquierdo para colocar (con snap), derecho para cancelar
	if placement_manager and placement_manager.is_placing and event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not is_night and can_afford_unit(placement_manager.pending_unit_type):
				var pos = get_global_mouse_position()
				placement_manager.confirm_placement(pos)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			placement_manager.cancel_placement()

# ------------------------------------------------------------------------------
func start_unit_placement(unit_type: String) -> void:
	# Entrar en modo colocación solo durante el día y si hay recursos
	if is_night:
		return
	# Solo disponible en el mundo
	if current_location != "world":
		return
	if not can_afford_unit(unit_type):
		return
	if placement_manager:
		placement_manager.start_placement(unit_type)

# ------------------------------------------------------------------------------
func _process(_delta):
	""" Proceso principal - maneja controles adicionales """
	if Input.is_action_just_pressed("ui_accept"):
		if is_night and enemies_remaining <= 0:
			end_wave()
		elif not is_night and current_location == "world":
			start_night()
	# Actualizar ghost de colocación
	if placement_manager and placement_manager.is_placing:
		placement_manager.update_ghost_position(get_global_mouse_position())

# ==============================================================================
# MANEJADORES DE SEÑALES INTERNAS
# ==============================================================================

func _on_day_started(day: int):
	""" Se ejecuta cuando inicia un nuevo día """
	game_paused = false
	# Sincronizar estado y resetear contadores/ UI
	current_day = day
	enemies_reached_entrance = 0
	wave_ending = false
	day_changed.emit(day)
	enemy_reached_entrance_signal.emit(enemies_reached_entrance)

	# Salir de modo colocación si estaba activo
	if placement_manager:
		placement_manager.cancel_placement()

func _on_resources_updated(resources: Dictionary):
	resources_updated.emit(resources)

func _on_unit_placed(unit: Node2D, type: String) -> void:
	if not resource_manager.has_method("purchase_unit"):
		if is_instance_valid(unit):
			unit.queue_free()
		return
	if not resource_manager.purchase_unit(type):
		if is_instance_valid(unit):
			unit.queue_free()
		return
	if not unit_manager.has_method("register_placed_unit"):
		push_error("[GameManager] UnitManager no disponible; la unidad colocada no se registrará correctamente.")
		if is_instance_valid(unit):
			unit.queue_free()
		return
	unit_manager.register_placed_unit(unit, type)

func _on_night_started():
	""" Se ejecuta cuando inicia la noche """
	game_paused = true
	# Ocultar/limpiar ghost de colocación
	if placement_manager:
		placement_manager.cancel_placement()

# ------------------------------------------------------------------------------
func _on_wave_updated(_enemies_remaining: int, _current_wave: int):
	""" Se ejecuta cuando cambia el estado de la oleada (señal del WaveManager). """
	enemies_remaining = _enemies_remaining
	current_wave = _current_wave
	wave_updated.emit(enemies_remaining, current_wave)
