class_name ResourceManager
extends Node

# Señales
signal resources_updated(resources: Dictionary)
signal resource_depleted(resource_name: String)

# Recursos del juego
var resources: Dictionary = {
	"gold": 0,
	"wood": 0,
	"stone": 0
}

# Upgrade tiers
var pickaxe_tier: int = 1  # Tier 1 (default), Tier 2, Tier 3

# Costes de las unidades
const UNIT_COSTS = {
	"archer": {"gold": 25, "wood": 10},
	"soldier": {"gold": 15, "stone": 5},
	"veteran_archer": {"gold": 70, "wood": 20},
	"veteran_soldier": {"gold": 50, "stone": 15}
}

# Añade recursos
func add_resources(gold_delta: int = 0, wood_delta: int = 0, stone_delta: int = 0) -> void:
	resources["gold"] = max(0, resources["gold"] + gold_delta)
	resources["wood"] = max(0, resources["wood"] + wood_delta)
	resources["stone"] = max(0, resources["stone"] + stone_delta)
	
	_emit_resources_updated()

# Verifica si hay suficientes recursos
func has_enough_resources(costs: Dictionary) -> bool:
	for resource in costs:
		if resources.get(resource, 0) < costs[resource]:
			return false
	return true

# Gasta recursos si hay suficientes
func spend_resources(costs: Dictionary) -> bool:
	# Primero verifica si hay suficientes recursos
	if not has_enough_resources(costs):
		return false
	
	# Si hay suficientes, gástalos
	for resource in costs:
		resources[resource] -= costs[resource]
		if resources[resource] <= 0:
			resources[resource] = 0
			resource_depleted.emit(resource)
	
	_emit_resources_updated()
	return true

# Obtiene la cantidad de un recurso específico
func get_resource(resource_name: String) -> int:
	return resources.get(resource_name, 0)

# Establece la cantidad de un recurso específico
func set_resource(resource_name: String, amount: int) -> void:
	if resources.has(resource_name):
		resources[resource_name] = max(0, amount)
		_emit_resources_updated()

# Establece gold, wood y stone de una vez (una sola emisión de señal)
func set_resources_bulk(gold_val: int = 0, wood_val: int = 0, stone_val: int = 0) -> void:
	resources["gold"] = max(0, gold_val)
	resources["wood"] = max(0, wood_val)
	resources["stone"] = max(0, stone_val)
	_emit_resources_updated()

# Emite la señal de recursos actualizados
func _emit_resources_updated() -> void:
	resources_updated.emit(resources.duplicate())

# Verifica si se puede comprar una unidad
func can_afford_unit(unit_type: String) -> bool:
	var costs = UNIT_COSTS.get(unit_type, {})
	return has_enough_resources(costs)

# Intenta comprar una unidad
func purchase_unit(unit_type: String) -> bool:
	var costs = UNIT_COSTS.get(unit_type, {})
	return spend_resources(costs)
# Upgrade pickaxe tier
func upgrade_pickaxe() -> void:
	if pickaxe_tier < 3:
		pickaxe_tier += 1
		set_meta("pickaxe_tier", pickaxe_tier)

# Get pickaxe tier
func get_pickaxe_tier() -> int:
	return pickaxe_tier
