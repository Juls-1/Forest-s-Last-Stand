extends CanvasLayer

# Referencias de UI 
@onready var day_hub: PanelContainer = $DayHud
@onready var night_hub: PanelContainer = $NightHud
@onready var day_label: Label = $DayHud/MarginContainer/HBoxContainer/Day/DayLabel
@onready var gold_label: Label = $DayHud/MarginContainer/HBoxContainer/Gold/GoldLabel
@onready var wood_label: Label = $DayHud/MarginContainer/HBoxContainer/Wood/WoodLabel
@onready var stone_label: Label = $DayHud/MarginContainer/HBoxContainer/Stone/StoneLabel
@onready var enemies_reached_label: Label = $NightHud/MarginContainer/HBoxContainer/Lifes/EnemiesReachedLabel
@onready var remaining_enemies_label: Label = $NightHud/MarginContainer/HBoxContainer/Enemies/RemainingEnemiesLabel
@onready var start_defend_button: Button = $StartDefendButton if has_node("StartDefendButton") else null
@onready var success_message: Label = $SuccessMessage if has_node("SuccessMessage") else null

var archer_button: Button = null
var soldier_button: Button = null
var veteran_archer_button: Button = null
var veteran_soldier_button: Button = null
var save_button: Button = null
var load_button: Button = null
var units_menu: Control = null
var placement_menu: Control = null
var spells_menu: Control = null

func _ready() -> void:
	add_to_group("game_hud")
	
	if start_defend_button:
		start_defend_button.pressed.connect(_on_start_defend_pressed)
	
	if success_message:
		success_message.visible = false

	placement_menu = find_child("UnitsMenu", false, false)
	if not placement_menu:
		placement_menu = find_child("PlacementMenu", true, false)
	if not placement_menu:
		placement_menu = find_child("placement_menu", true, false)

	if not placement_menu:
		placement_menu = get_tree().root.find_child("UnitsMenu", true, false)
	if not placement_menu:
		placement_menu = get_tree().root.find_child("PlacementMenu", true, false)
	if not placement_menu:
		placement_menu = get_tree().root.find_child("placement_menu", true, false)
	if placement_menu:
		archer_button = placement_menu.find_child("ArcherButton", true, false)
		soldier_button = placement_menu.find_child("SoldierButton", true, false)
		# Find veteran buttons from MenuMejorado
		var menu_mejorado = placement_menu.find_child("MenuMejorado", true, false)
		if menu_mejorado:
			veteran_soldier_button = menu_mejorado.find_child("VeteranSoldierButton", true, false)
			veteran_archer_button = menu_mejorado.find_child("VeteranArcherButton", true, false)
	else:

		archer_button = get_node_or_null("ArcherButton")
		soldier_button = get_node_or_null("SoldierButton")
	# Note: Button connections are handled by placement_menu.gd, not here
	# We only need to find references if we need them later

	units_menu = find_child("UnitsMenu", true, false)
	spells_menu = find_child("SpellsMenu", true, false)
	if units_menu and _is_in_town_scene():
		units_menu.visible = false
	if placement_menu and _is_in_town_scene():
		placement_menu.visible = false
	if spells_menu:
		spells_menu.visible = false

	save_button = find_child("SaveButton", true, false)
	load_button = find_child("LoadButton", true, false)
	if save_button and save_button is Button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button and load_button is Button:
		load_button.pressed.connect(_on_load_pressed)
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if game_manager.has_signal("resources_updated"):
			game_manager.resources_updated.connect(_on_resources_updated)
		if game_manager.has_signal("day_changed"):
			game_manager.day_changed.connect(_on_day_changed)
		if game_manager.has_signal("enemy_reached_entrance_signal"):
			game_manager.enemy_reached_entrance_signal.connect(_on_enemies_reached_entrance)
		if game_manager.has_signal("day_started"):
			game_manager.day_started.connect(_on_day_started)
		if game_manager.has_signal("night_started"):
			game_manager.night_started.connect(_on_night_started)
		if game_manager.has_signal("wave_updated"):
			game_manager.wave_updated.connect(_on_wave_updated)
		if game_manager:
			var loc = game_manager.get("current_location")
			update_hud_visibility(game_manager.is_night, loc if loc != null else "world")

		update_day(game_manager.current_day)
		update_resources(game_manager.gold, game_manager.wood, game_manager.stone)
		update_enemies_reached(game_manager.enemies_reached_entrance, game_manager.max_enemies_allowed)
		update_remaining_enemies(game_manager.enemies_remaining)
		
		var loc_for_buttons = game_manager.get("current_location")
		var in_world: bool = (loc_for_buttons == "world") if (loc_for_buttons != null) else true
		if _is_in_town_scene():
			in_world = false
		if start_defend_button:
			start_defend_button.visible = not game_manager.is_night and in_world
		if placement_menu:
			placement_menu.visible = not game_manager.is_night and in_world
		if units_menu:
			units_menu.visible = not game_manager.is_night and in_world
		if spells_menu:
			spells_menu.visible = game_manager.is_night and in_world

		# Refrescar visibilidad un frame después para asegurar que GameManager ya tiene current_location (p. ej. en town)
		call_deferred("_refresh_units_menu_visibility")

	var resource_manager = get_tree().get_root().find_child("ResourceManager", true, false)
	if resource_manager:
		if resource_manager.has_signal("resources_updated"):
			resource_manager.resources_updated.connect(_on_resources_updated)

		if resource_manager.has_method("get_resource"):
			var g = resource_manager.get_resource("gold")
			var w = resource_manager.get_resource("wood")
			var s = resource_manager.get_resource("stone")
			update_resources(g, w, s)

func update_day(day: int) -> void:
	if day_label:
		day_label.text = " %d" % day


func update_resources(gold: int, wood: int, stone: int) -> void:
	if gold_label:
		gold_label.text = " %d" % gold
	if wood_label:
		wood_label.text = " %d" % wood
	if stone_label:
		stone_label.text = " %d" % stone
		
func update_hud_visibility(is_night: bool, current_location: String = "world") -> void:
	var in_world: bool = (current_location == "world") and not _is_in_town_scene()
	day_hub.visible = not is_night
	night_hub.visible = is_night

	if start_defend_button:
		start_defend_button.visible = not is_night and in_world

	# Menú de unidades solo de día en world (nunca en town)
	if placement_menu:
		placement_menu.visible = not is_night and in_world
	if units_menu:
		units_menu.visible = not is_night and in_world
	if spells_menu:
		spells_menu.visible = is_night and in_world

func _is_in_town_scene() -> bool:
	var cur = get_tree().current_scene
	return cur != null and cur.scene_file_path != null and "town" in cur.scene_file_path

func _refresh_units_menu_visibility() -> void:
	""" Refresca la visibilidad del menú de unidades según location/is_night (útil cuando se carga town y GameManager ya tiene current_location). """
	if _is_in_town_scene():
		if placement_menu:
			placement_menu.visible = false
		if units_menu:
			units_menu.visible = false
		return
	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm:
		return
	var loc = gm.get("current_location")
	var is_night_val = gm.get("is_night")
	var is_night: bool = is_night_val if is_night_val != null else false
	update_hud_visibility(is_night, loc if loc != null else "world")
		
func _on_resources_updated(resources: Dictionary) -> void:
	update_resources(
		resources.get("gold", 0),
		resources.get("wood", 0),
		resources.get("stone", 0)
	)

func _on_day_changed(day: int) -> void:
	update_day(day)

func update_enemies_reached(count: int, max_count: int) -> void:
	if enemies_reached_label:
		enemies_reached_label.text = " %d/%d" % [(max_count-count),max_count]

		if count >= max_count - 1:
			enemies_reached_label.add_theme_color_override("font_color", Color(1, 0, 0, 1)) 
		elif count >= max_count / 2.0:
			enemies_reached_label.add_theme_color_override("font_color", Color(1, 0.5, 0, 1)) 
		else:
			enemies_reached_label.add_theme_color_override("font_color", Color(0.276, 0.761, 0.318, 1.0)) 


func update_remaining_enemies(count: int) -> void:
	if remaining_enemies_label:
		remaining_enemies_label.text = ": %d" % count


func _on_enemies_reached_entrance(count: int) -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		update_enemies_reached(count, game_manager.max_enemies_allowed)

func _on_start_defend_pressed() -> void:

	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("start_defense"):
		game_manager.start_defense()

func _on_day_started(_day: int) -> void:
	# Día solo ocurre en world; menú de unidades visible solo de día en world
	update_hud_visibility(false, "world")
	if start_defend_button:
		start_defend_button.visible = true
		start_defend_button.disabled = false
	if remaining_enemies_label:
		remaining_enemies_label.visible = false
	if enemies_reached_label:
		enemies_reached_label.visible = false
	if spells_menu:
		spells_menu.visible = false

func _on_night_started() -> void:
	update_hud_visibility(true)
	"""Llamado cuando empieza la fase de noche"""
	if start_defend_button:
		start_defend_button.visible = false
	if remaining_enemies_label:
		remaining_enemies_label.visible = true
	if enemies_reached_label:
		enemies_reached_label.visible = true
	if placement_menu:
		placement_menu.visible = false
	if units_menu:
		units_menu.visible = false
	if spells_menu:
		spells_menu.visible = true
	

func _on_wave_updated(enemies_remaining: int, _current_wave: int) -> void:
	"""Llamado cuando se actualiza el estado de la oleada"""
	update_remaining_enemies(enemies_remaining)

# Note: Unit placement button handlers are managed by placement_menu.gd
# Game HUD only manages the display of resources, day/night info, etc.

# Early return - these methods are no longer used as placement_menu.gd handles button connections
func _on_archer_pressed() -> void:
	pass # Handled by placement_menu.gd

func _on_soldier_pressed() -> void:
	pass # Handled by placement_menu.gd

func _on_veteran_archer_pressed() -> void:
	pass # Handled by placement_menu.gd

func _on_veteran_soldier_pressed() -> void:
	pass # Handled by placement_menu.gd

# ------------------------------------------------------------------------------
func _on_save_pressed() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("save_game"):
		gm.save_game()

# ------------------------------------------------------------------------------
func _on_load_pressed() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("load_game"):
		gm.load_game()

func show_wave_complete_message(wave: int) -> void:

	if success_message:
		success_message.text = "¡DEFENSA EXITOSA! ¡Oleada %d completada!" % wave
		success_message.visible = true
		
		# Desvanecer después de 2 segundos
		await get_tree().create_timer(1.5).timeout
		if success_message:
			var tween = create_tween()
			tween.tween_property(success_message, "modulate:a", 0.0, 0.5)
			await tween.finished
			success_message.visible = false
			success_message.modulate.a = 1.0
