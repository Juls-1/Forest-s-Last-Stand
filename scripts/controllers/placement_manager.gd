extends Node
class_name PlacementManager

var unit_scenes: Dictionary = {
	"archer": preload("res://scenes/units/archer.tscn"),
	"soldier": preload("res://scenes/units/soldier.tscn"),
	"veteran_archer": preload("res://scenes/units/veteran_archer.tscn"),
	"veteran_soldier": preload("res://scenes/units/veteran_soldier.tscn")
}

var is_placing: bool = false
var pending_unit_type: String = ""
var placement_ghost: Node2D = null

# Zonas de colocación (world): nodos Area2D con CollisionPolygon2D
var _soldier_placement_area: Area2D = null
var _archer_placement_area: Area2D = null

func _ready():
	var parent = get_parent()
	if parent:
		_soldier_placement_area = parent.get_node_or_null("SoldierPlacement") as Area2D
		_archer_placement_area = parent.get_node_or_null("ArcherPlacement") as Area2D

signal unit_placed(unit: Node2D, type: String)

func start_placement(unit_type: String):
	if not unit_scenes.has(unit_type):
		push_error("Unit type not found: " + unit_type)
		return
	
	# Clean up any existing ghost
	cancel_placement()
	
	is_placing = true
	pending_unit_type = unit_type
	
	# Create ghost
	placement_ghost = Node2D.new()
	placement_ghost.name = "PlacementGhost"
	
	var sprite := Sprite2D.new()
	sprite.name = "GhostSprite"
	sprite.modulate = Color(0, 1, 0, 0.5)
	sprite.scale = Vector2(1, 1)
	sprite.z_index = 1000
	
	var texture: Texture2D
	match unit_type:
		"archer":
			texture = preload("res://assets/art/characters/ArcherIcon.png")
		"soldier":
			texture = preload("res://assets/art/characters/SoldierIcon.png")
		"veteran_archer":
			texture = preload("res://assets/art/characters/VeteranArcherIcon.png")
		"veteran_soldier":
			texture = preload("res://assets/art/characters/VeteranSoldierIcon.png")
		_:
			push_warning("Unknown unit type: %s" % unit_type)
			texture = preload("res://icon.svg")
	
	sprite.texture = texture
	placement_ghost.add_child(sprite)
	get_tree().root.add_child(placement_ghost)

func cancel_placement():
	if placement_ghost:
		placement_ghost.queue_free()
		placement_ghost = null
	is_placing = false
	pending_unit_type = ""

func confirm_placement(position: Vector2):
	if not is_placing or not placement_ghost:
		return
	
	var snaped = GridUtils.snap_to_grid(position, 32)
	if not _is_valid_placement(snaped):
		return
	
	var unit = unit_scenes[pending_unit_type].instantiate()
	unit.global_position = snaped
	get_tree().root.add_child(unit)
	
	unit_placed.emit(unit, pending_unit_type)
	
	cancel_placement()

func _is_valid_placement(pos: Vector2) -> bool:
	var gm = get_parent()
	if gm and "is_night" in gm and gm.is_night:
		return false
	# Restricción por tipo: soldier solo en SoldierPlacement, archer solo en ArcherPlacement
	if not _is_position_in_placement_zone(pos, pending_unit_type):
		return false
	# Evitar superposición con otras unidades aliadas
	for u in get_tree().get_nodes_in_group("friendly_units"):
		if is_instance_valid(u) and u is Node2D:
			if (u as Node2D).global_position.distance_to(pos) < 24.0:
				return false
	return true

func update_ghost_position(position: Vector2):
	if placement_ghost:
		var snaped = GridUtils.snap_to_grid(position, 32)
		placement_ghost.global_position = snaped
		var ok = _is_valid_placement(snaped)
		var spr = placement_ghost.get_node_or_null("GhostSprite") as Sprite2D
		if spr:
			# Verde si zona válida, rojo si fuera de zona permitida o inválido
			spr.modulate = Color(0, 1, 0, 0.5) if ok else Color(1, 0, 0, 0.5)

func _is_position_in_placement_zone(global_pos: Vector2, unit_type: String) -> bool:
	var area: Area2D = null
	match unit_type:
		"soldier", "veteran_soldier":
			area = _soldier_placement_area
		"archer", "veteran_archer":
			area = _archer_placement_area
		_:
			return true
	if not area:
		return true
	for child in area.get_children():
		if child is CollisionPolygon2D:
			var shape := child as CollisionPolygon2D
			var local_pt := shape.global_transform.affine_inverse() * global_pos
			if Geometry2D.is_point_in_polygon(local_pt, shape.polygon):
				return true
	return false
