class_name UnitManager
extends Node

## Gestiona creación, curación y persistencia de unidades aliadas (soldiers, archers).

@export var archer_scene: PackedScene = preload("res://scenes/units/archer.tscn")
@export var soldier_scene: PackedScene = preload("res://scenes/units/soldier.tscn")

var _units_node: Node2D
var _resource_manager: Node

func _ready() -> void:
	add_to_group("unit_manager")
	_units_node = _get_or_create_units_node()
	_resource_manager = get_parent().get_node_or_null("ResourceManager")


func _get_or_create_units_node() -> Node2D:
	if has_node("Units"):
		return get_node("Units")
	var n = Node2D.new()
	n.name = "Units"
	add_child(n)
	return n


func get_units_node() -> Node2D:
	return _units_node


## Recluta una unidad (compra en ResourceManager, instancia y añade al contenedor). Devuelve true si se reclutó.
func recruit_unit(unit_type: String, spawn_position: Vector2) -> bool:
	if not _resource_manager or not _resource_manager.has_method("purchase_unit"):
		push_error("[UnitManager] ResourceManager no disponible.")
		return false
	if not _resource_manager.purchase_unit(unit_type):
		return false

	var scene: PackedScene = _scene_for_type(unit_type)
	if not scene:
		return false

	var unit = _create_and_setup_unit(scene, unit_type, spawn_position)
	if unit:
		_units_node.add_child(unit)
	return unit != null


## Registra una unidad ya instanciada (p. ej. por PlacementManager): reparenta al contenedor, grupos y projectile.
func register_placed_unit(unit: Node2D, unit_type: String) -> void:
	if not is_instance_valid(unit):
		return
	if unit.get_parent() != _units_node:
		var pos_global: Vector2 = unit.global_position
		unit.get_parent().remove_child(unit)
		_units_node.add_child(unit)
		unit.global_position = pos_global
	unit.set_meta("unit_type", unit_type)
	unit.add_to_group("friendly_units")
	if unit_type == "soldier":
		unit.add_to_group("soldiers")
	_apply_projectile_to_archer(unit, unit_type)


## Cura todas las unidades aliadas por el porcentaje indicado (0.0–1.0).
func heal_all_units(heal_percentage: float) -> void:
	if not is_instance_valid(_units_node):
		return
	for unit in _units_node.get_children():
		if unit.has_method("heal"):
			unit.heal(heal_percentage)


## Serializa el estado de las unidades para persistencia (array de {type, position}).
func save_state() -> Array:
	var out: Array = []
	for unit in _units_node.get_children():
		if unit is Node2D:
			var utype: String = unit.get_meta("unit_type") if unit.has_meta("unit_type") else ""
			if utype.is_empty():
				continue
			out.append({
				"type": utype,
				"position": (unit as Node2D).global_position
			})
	return out


## Restaura unidades desde un array de {type, position}. Limpia las actuales si clear_existing es true.
func restore_state(units_state: Array, clear_existing: bool = true) -> void:
	if not is_instance_valid(_units_node):
		return
	if clear_existing:
		for c in _units_node.get_children():
			c.queue_free()

	for u in units_state:
		if typeof(u) != TYPE_DICTIONARY:
			continue
		var utype: String = u.get("type", "")
		var pos: Vector2 = u.get("position", Vector2.ZERO)
		var scene: PackedScene = _scene_for_type(utype)
		if not scene:
			continue
		var unit = _create_and_setup_unit(scene, utype, pos)
		if unit:
			_units_node.add_child(unit)


func _scene_for_type(unit_type: String) -> PackedScene:
	match unit_type:
		"archer":
			return archer_scene
		"soldier":
			return soldier_scene
	return null


func _create_and_setup_unit(scene: PackedScene, unit_type: String, position: Vector2) -> Node2D:
	var unit = scene.instantiate()
	if not unit is Node2D:
		return null
	unit.global_position = position
	unit.set_meta("unit_type", unit_type)
	unit.add_to_group("friendly_units")
	if unit_type == "soldier":
		unit.add_to_group("soldiers")
	_apply_projectile_to_archer(unit, unit_type)
	return unit as Node2D


func _apply_projectile_to_archer(unit: Node, unit_type: String) -> void:
	if unit_type != "archer" or not ("projectile_scene" in unit):
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and "projectile_scene" in player and player.projectile_scene:
		unit.projectile_scene = player.projectile_scene
