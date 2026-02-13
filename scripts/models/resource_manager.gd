class_name ResourceManager
extends Node
signal resources_updated(resources: Dictionary)
signal resource_depleted(resource_name: String)
var resources: Dictionary = {
	"gold": 0,
	"wood": 0,
	"stone": 0
}
var pickaxe_tier: int = 1 
const UNIT_COSTS = {
	"archer": {"gold": 25, "wood": 10},
	"soldier": {"gold": 15, "stone": 5},
	"veteran_archer": {"gold": 70, "wood": 20},
	"veteran_soldier": {"gold": 50, "stone": 15}
}
func add_resources(gold_delta: int = 0, wood_delta: int = 0, stone_delta: int = 0) -> void:
	resources["gold"] = max(0, resources["gold"] + gold_delta)
	resources["wood"] = max(0, resources["wood"] + wood_delta)
	resources["stone"] = max(0, resources["stone"] + stone_delta)
	
	_emit_resources_updated()
func has_enough_resources(costs: Dictionary) -> bool:
	for resource in costs:
		if resources.get(resource, 0) < costs[resource]:
			return false
	return true
func spend_resources(costs: Dictionary) -> bool:
	if not has_enough_resources(costs):
		return false
	for resource in costs:
		resources[resource] -= costs[resource]
		if resources[resource] <= 0:
			resources[resource] = 0
			resource_depleted.emit(resource)
	
	_emit_resources_updated()
	return true
func get_resource(resource_name: String) -> int:
	return resources.get(resource_name, 0)
func set_resource(resource_name: String, amount: int) -> void:
	if resources.has(resource_name):
		resources[resource_name] = max(0, amount)
		_emit_resources_updated()
func set_resources_bulk(gold_val: int = 0, wood_val: int = 0, stone_val: int = 0) -> void:
	resources["gold"] = max(0, gold_val)
	resources["wood"] = max(0, wood_val)
	resources["stone"] = max(0, stone_val)
	_emit_resources_updated()
func _emit_resources_updated() -> void:
	resources_updated.emit(resources.duplicate())
func can_afford_unit(unit_type: String) -> bool:
	var costs = UNIT_COSTS.get(unit_type, {})
	return has_enough_resources(costs)
func purchase_unit(unit_type: String) -> bool:
	var costs = UNIT_COSTS.get(unit_type, {})
	return spend_resources(costs)
func upgrade_pickaxe() -> void:
	if pickaxe_tier < 3:
		pickaxe_tier += 1
		set_meta("pickaxe_tier", pickaxe_tier)
func get_pickaxe_tier() -> int:
	return pickaxe_tier
