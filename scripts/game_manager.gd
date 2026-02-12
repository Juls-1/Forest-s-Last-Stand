extends Node2D

@export var max_enemies_allowed: int = 3

const INITIAL_GOLD: int = 100
const INITIAL_WOOD: int = 100
const INITIAL_STONE: int = 100
const DAY_NIGHT_TRANSITION_DURATION: float = 1.5

var current_day: int = 0
var is_night: bool = false
var game_paused: bool = false
var game_over_triggered: bool = false
var enemies_remaining: int = 0
var current_wave: int = 0
var enemies_reached_entrance: int = 0
var wave_ending: bool = false

var current_location: String = "town"
var gold: int: get = _get_gold
var wood: int: get = _get_wood
var stone: int: get = _get_stone
var axe_tier: int = 1
var pickaxe_tier: int = 1

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
@onready var wave_manager: Node = get_node_or_null("WaveManager")
var placement_manager: Node


func _ready() -> void:
	add_to_group("game_manager")
	resource_manager.add_to_group("resource_manager")
	
	await get_tree().process_frame
	
	placement_manager = get_parent().get_node_or_null("PlacementManager")
	_find_canvas_modulate()
	_connect_signals()
	_restore_game_state()
	
	if current_day <= 0:
		start_new_day()

func _restore_game_state() -> void:
	var data = SessionPersistence.load_session()

	if data.location in ["world", "town"]:
		current_location = data.location

	if not data.game_state:
		if resource_manager and resource_manager.has_method("set_resources_bulk"):
			resource_manager.set_resources_bulk(INITIAL_GOLD, INITIAL_WOOD, INITIAL_STONE)
		
		if SoundManager:
			if current_location == "world":
				SoundManager.play_music_for_scene("world", is_night)
			elif current_location == "town":
				SoundManager.play_music_for_scene("town", false)
		return

	var gs: Dictionary = data.game_state
	if resource_manager and resource_manager.has_method("set_resources_bulk"):
		resource_manager.set_resources_bulk(
			int(gs.get("gold", INITIAL_GOLD)),
			int(gs.get("wood", INITIAL_WOOD)),
			int(gs.get("stone", INITIAL_STONE))
		)

	current_day = int(gs.get("current_day", current_day))
	is_night = bool(gs.get("is_night", false))
	current_wave = int(gs.get("current_wave", current_wave))
	enemies_remaining = int(gs.get("enemies_remaining", enemies_remaining))
	enemies_reached_entrance = int(gs.get("enemies_reached_entrance", enemies_reached_entrance))
	axe_tier = int(gs.get("axe_tier", 1))
	pickaxe_tier = int(gs.get("pickaxe_tier", 1))

	if SoundManager:
		if current_location == "world":
			SoundManager.play_music_for_scene("world", is_night)
		elif current_location == "town":
			SoundManager.play_music_for_scene("town", false)

	if is_night:
		transition_to_night()
		wave_updated.emit(enemies_remaining, current_wave)
		enemy_reached_entrance_signal.emit(enemies_reached_entrance)
	else:
		transition_to_day()
		day_changed.emit(current_day)

	_restore_units_if_needed(data)

func _restore_units_if_needed(data: Dictionary) -> void:
	if current_location == "world" and data.units_state is Array and data.units_state.size() > 0:
		unit_manager.restore_state(data.units_state, true)
		SessionPersistence.clear_cached_units_state()

func _connect_signals() -> void:
	day_started.connect(_on_day_started)
	night_started.connect(_on_night_started)
	
	if resource_manager.has_signal("resources_updated"):
		resource_manager.resources_updated.connect(_on_resources_updated)
	
	if placement_manager and placement_manager.has_signal("unit_placed"):
		placement_manager.unit_placed.connect(_on_unit_placed)
	
	if not resource_manager.has_method("set_resources_bulk"):
		return
	
	if not wave_manager:
		return
	
	wave_manager.enemies_remaining_updated.connect(_on_wave_updated)
	wave_manager.wave_completed.connect(func(_w): end_wave())
	wave_manager.enemy_died.connect(_on_enemy_died)
	wave_manager.enemy_reached_end.connect(_on_enemy_reached_end)

func _get_gold() -> int:
	return resource_manager.get_resource("gold")

func _get_wood() -> int:
	return resource_manager.get_resource("wood")

func _get_stone() -> int:
	return resource_manager.get_resource("stone")

func _get_or_create(node_name: String) -> Node2D:
	if has_node(node_name):
		return get_node(node_name)
	var n = Node2D.new()
	n.name = node_name
	add_child(n)
	return n

func _find_canvas_modulate() -> void:
	canvas_modulate = get_tree().get_first_node_in_group("canvas_modulate")

func start_new_day() -> void:
	if game_over_triggered:
		return
	current_day += 1
	is_night = false
	enemies_reached_entrance = 0
	transition_to_day()
	

	if current_location == "world" and SoundManager:
		SoundManager.play_music_for_scene("world", false)
	
	day_started.emit(current_day)
	day_changed.emit(current_day)
	heal_all_units(0.2)

func start_night() -> void:
	if is_night or current_location != "world":
		return
	is_night = true
	transition_to_night()
	
	if SoundManager:
		SoundManager.play_music_for_scene("world", true)
	
	night_started.emit()
	start_wave()

func transition_to_day() -> void:
	if canvas_modulate:
		create_tween().tween_property(canvas_modulate, "color", Color(1, 1, 1, 1), DAY_NIGHT_TRANSITION_DURATION)

func transition_to_night() -> void:
	if canvas_modulate:
		create_tween().tween_property(canvas_modulate, "color", Color(0.357, 0.358, 0.58, 1.0), DAY_NIGHT_TRANSITION_DURATION)

func start_wave() -> void:
	if not wave_manager:
		return
	wave_manager.start_wave_for_day(current_day)

func _on_enemy_died(enemy = null) -> void:
	if not enemy:
		return
	var gold_drop = _calculate_enemy_gold_drop(enemy)
	resource_manager.add_resources(gold_drop, 0, 0)

func _calculate_enemy_gold_drop(enemy: Node) -> int:
	if "gold_value" in enemy:
		return int(enemy.gold_value)
	var enemy_type = enemy.get_meta("enemy_type") if enemy.has_meta("enemy_type") else "basic"
	return EnemyConfig.ENEMIES.get(enemy_type, EnemyConfig.ENEMIES.get("basic")).gold_drop

func enemy_reached_entrance() -> void:
	if game_over_triggered:
		return
	enemies_reached_entrance += 1
	enemy_reached_entrance_signal.emit(enemies_reached_entrance)
	if enemies_reached_entrance >= max_enemies_allowed:
		trigger_game_over("Too many enemies reached the entrance!")

func _on_enemy_reached_end() -> void:
	enemy_reached_entrance()

func start_defense() -> void:
	start_night()

func end_wave() -> void:
	if game_over_triggered or wave_ending or not is_night:
		return
	wave_ending = true
	show_successful_defend_message()
	await get_tree().create_timer(2.0).timeout
	is_night = false
	start_new_day()

func show_successful_defend_message() -> void:
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("show_wave_complete_message"):
		hud.show_wave_complete_message(current_wave)

func can_afford_unit(unit_type: String) -> bool:
	return resource_manager.can_afford_unit(unit_type)

func recruit_unit(unit_type: String, spawn_position: Vector2) -> void:
	unit_manager.recruit_unit(unit_type, spawn_position)

func heal_all_units(heal_percentage: float) -> void:
	unit_manager.heal_all_units(heal_percentage)

func update_resources(gold_delta: int = 0, wood_delta: int = 0, stone_delta: int = 0) -> void:
	resource_manager.add_resources(gold_delta, wood_delta, stone_delta)

func reward_minigame(rewards: Dictionary) -> void:
	update_resources(
		rewards.get("gold", 0),
		rewards.get("wood", 0),
		rewards.get("stone", 0)
	)

func trigger_game_over(reason: String) -> void:
	if game_over_triggered:
		return
	game_over_triggered = true
	game_paused = true
	game_over.emit(reason)
	_show_game_over_ui(reason)

func _show_game_over_ui(reason: String) -> void:
	var game_over_ui = get_tree().get_first_node_in_group("game_over_ui")
	if not game_over_ui:
		game_over_ui = load("res://scenes/ui/game_over.tscn").instantiate()
		game_over_ui.add_to_group("game_over_ui")
		get_tree().root.add_child(game_over_ui)
	if game_over_ui and game_over_ui.has_method("show_game_over"):
		game_over_ui.show_game_over(reason)

func start_unit_placement(unit_type: String) -> void:
	if is_night or current_location != "world" or not can_afford_unit(unit_type):
		return
	if placement_manager:
		placement_manager.start_placement(unit_type)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_debug_input(event.keycode)
	if placement_manager and placement_manager.is_placing and event is InputEventMouseButton and event.pressed:
		_handle_placement_input(event)

func _handle_debug_input(keycode: int) -> void:
	match keycode:
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

func _handle_placement_input(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if not is_night and can_afford_unit(placement_manager.pending_unit_type):
			placement_manager.confirm_placement(get_global_mouse_position())
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		placement_manager.cancel_placement()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if is_night and enemies_remaining <= 0:
			end_wave()
		elif not is_night and current_location == "world":
			start_night()
	if placement_manager and placement_manager.is_placing:
		placement_manager.update_ghost_position(get_global_mouse_position())

func _on_day_started(day: int) -> void:
	game_paused = false
	current_day = day
	enemies_reached_entrance = 0
	wave_ending = false
	day_changed.emit(day)
	enemy_reached_entrance_signal.emit(enemies_reached_entrance)
	if placement_manager:
		placement_manager.cancel_placement()

func _on_night_started() -> void:
	game_paused = true
	if placement_manager:
		placement_manager.cancel_placement()

func _on_resources_updated(resources: Dictionary) -> void:
	resources_updated.emit(resources)

func _on_unit_placed(unit: Node2D, unit_type: String) -> void:
	if not resource_manager.purchase_unit(unit_type):
		if is_instance_valid(unit):
			unit.queue_free()
		return
	unit_manager.register_placed_unit(unit, unit_type)

func _on_wave_updated(enemies_count: int, wave_num: int = -1) -> void:
	enemies_remaining = enemies_count
	if wave_num == -1:
		current_wave = wave_manager.current_wave if is_instance_valid(wave_manager) and "current_wave" in wave_manager else current_wave
	else:
		current_wave = wave_num
	wave_updated.emit(enemies_remaining, current_wave)
