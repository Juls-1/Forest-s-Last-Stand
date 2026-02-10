extends Node
class_name AggroComponent

@export var enemy_type: String = "basic" 

var aggro_targets: Array = []
var current_aggro_target: Node2D = null

func set_aggro_target(unit: Node2D):
	if enemy_type == "explorer": return 
	if not aggro_targets.has(unit):
		aggro_targets.append(unit)
		_update_aggro_target()

func clear_aggro_target(unit: Node2D):
	if aggro_targets.has(unit):
		aggro_targets.erase(unit)
	_update_aggro_target()

func _update_aggro_target():
	aggro_targets = aggro_targets.filter(func(t): return is_instance_valid(t))
	current_aggro_target = aggro_targets[0] if not aggro_targets.is_empty() else null

func get_current_target() -> Node2D:
	if current_aggro_target and not is_instance_valid(current_aggro_target):
		_update_aggro_target()
	return current_aggro_target

func has_aggro_targets() -> bool:
	# Asegurarse de que esté limpio antes de verificar
	if not aggro_targets.is_empty() and not is_instance_valid(aggro_targets[0]):
		_update_aggro_target()
	return not aggro_targets.is_empty()
