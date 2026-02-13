extends CanvasLayer

@onready var day_hub := find_child("DayHud", true, false)
@onready var night_hub := find_child("NightHud", true, false)
@onready var day_label := find_child("DayLabel", true, false)
@onready var gold_label := find_child("GoldLabel", true, false)
@onready var wood_label := find_child("WoodLabel", true, false)
@onready var stone_label := find_child("StoneLabel", true, false)
@onready var enemies_reached_label := find_child("EnemiesReachedLabel", true, false)
@onready var remaining_enemies_label := find_child("RemainingEnemiesLabel", true, false)
@onready var start_defend_button := find_child("StartDefendButton", true, false)
@onready var success_message := find_child("SuccessMessage", true, false)

var archer_button: Button
var soldier_button: Button
var veteran_archer_button: Button
var veteran_soldier_button: Button
var save_button: Button
var load_button: Button
var units_menu: Control
var placement_menu: Control
var spells_menu: Control

func _ready() -> void:
	add_to_group("game_hud")
	_init_ui_nodes()
	_connect_game_signals()
	_connect_resource_signals()
	_configure_initial_visibility()


func _init_ui_nodes() -> void:
	placement_menu = find_child("UnitsMenu", true, false)
	units_menu = find_child("UnitsMenu", true, false)
	spells_menu = find_child("SpellsMenu", true, false)

	archer_button = placement_menu.find_child("ArcherButton", true, false)
	soldier_button = placement_menu.find_child("SoldierButton", true, false)
	var menu_mejorado = placement_menu.find_child("MenuMejorado", true, false)
	veteran_soldier_button = menu_mejorado.find_child("VeteranSoldierButton", true, false)
	veteran_archer_button = menu_mejorado.find_child("VeteranArcherButton", true, false)

	success_message.visible = false


func _connect_game_signals() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	gm.resources_updated.connect(_on_resources_updated)
	gm.day_changed.connect(_on_day_changed)
	gm.enemy_reached_entrance_signal.connect(_on_enemies_reached_entrance)
	gm.day_started.connect(_on_day_started)
	gm.night_started.connect(_on_night_started)
	gm.wave_updated.connect(_on_wave_updated)

	update_day(gm.current_day)
	update_resources(gm.gold, gm.wood, gm.stone)
	update_enemies_reached(gm.enemies_reached_entrance, gm.max_enemies_allowed)
	update_remaining_enemies(gm.enemies_remaining)

	var loc_for_buttons: String = gm.get("current_location") as String
	var in_world: bool = (loc_for_buttons == "world")
	if _is_in_town_scene():
		in_world = false

	placement_menu.visible = not gm.is_night and in_world
	units_menu.visible = not gm.is_night and in_world
	spells_menu.visible = gm.is_night and in_world
	call_deferred("_refresh_units_menu_visibility")


func _connect_resource_signals() -> void:
	var resource_manager = get_tree().get_root().find_child("ResourceManager", true, false)
	resource_manager.resources_updated.connect(_on_resources_updated)
	var g = resource_manager.get_resource("gold")
	var w = resource_manager.get_resource("wood")
	var s = resource_manager.get_resource("stone")
	update_resources(g, w, s)


func _configure_initial_visibility() -> void:
	day_hub.visible = true
	night_hub.visible = false

func update_day(day: int) -> void:
	day_label.text = " %d" % day


func update_resources(gold: int, wood: int, stone: int) -> void:
	gold_label.text = " %d" % gold
	wood_label.text = " %d" % wood
	stone_label.text = " %d" % stone
		
func update_hud_visibility(is_night: bool, current_location: String = "world") -> void:
	var in_world: bool = (current_location == "world") and not _is_in_town_scene()
	day_hub.visible = not is_night
	night_hub.visible = is_night

	placement_menu.visible = not is_night and in_world
	units_menu.visible = not is_night and in_world
	spells_menu.visible = is_night and in_world

func _is_in_town_scene() -> bool:
	var cur = get_tree().current_scene
	return cur != null and cur.scene_file_path != null and "town" in cur.scene_file_path

func _refresh_units_menu_visibility() -> void:
	if _is_in_town_scene():
		placement_menu.visible = false
		units_menu.visible = false
		return
	var gm = get_tree().get_first_node_in_group("game_manager")
	var loc: String = gm.get("current_location") as String
	var is_night: bool = bool(gm.get("is_night"))
	update_hud_visibility(is_night, loc)
		
func _on_resources_updated(resources: Dictionary) -> void:
	update_resources(
		resources.get("gold", 0),
		resources.get("wood", 0),
		resources.get("stone", 0)
	)

func _on_day_changed(day: int) -> void:
	update_day(day)

func update_enemies_reached(count: int, max_count: int) -> void:
	enemies_reached_label.text = " %d/%d" % [(max_count - count), max_count]

	if count >= max_count - 1:
		enemies_reached_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	elif count >= max_count / 2.0:
		enemies_reached_label.add_theme_color_override("font_color", Color(1, 0.5, 0, 1))
	else:
		enemies_reached_label.add_theme_color_override("font_color", Color(0.276, 0.761, 0.318, 1.0))


func update_remaining_enemies(count: int) -> void:
	remaining_enemies_label.text = ": %d" % count


func _on_enemies_reached_entrance(count: int) -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	update_enemies_reached(count, game_manager.max_enemies_allowed)


func _on_start_defend_pressed() -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	game_manager.start_defense()

func _on_day_started(_day: int) -> void:
	update_hud_visibility(false, "world")
	if remaining_enemies_label:
		remaining_enemies_label.visible = false
	if enemies_reached_label:
		enemies_reached_label.visible = false
	if spells_menu:
		spells_menu.visible = false

func _on_night_started() -> void:
	update_hud_visibility(true)
	remaining_enemies_label.visible = true
	enemies_reached_label.visible = true
	placement_menu.visible = false
	units_menu.visible = false
	spells_menu.visible = true
	
func _on_wave_updated(enemies_remaining: int, _current_wave: int) -> void:
	update_remaining_enemies(enemies_remaining)

func show_wave_complete_message(wave: int) -> void:
	success_message.text = "¡DEFENSA EXITOSA! ¡Oleada %d completada!" % wave
	success_message.visible = true
	await get_tree().create_timer(1.5).timeout
	var tween = create_tween()
	tween.tween_property(success_message, "modulate:a", 0.0, 0.5)
	await tween.finished
	success_message.visible = false
	success_message.modulate.a = 1.0
