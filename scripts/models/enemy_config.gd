class_name EnemyConfig
extends Node

# Configuración centralizada de enemigos
const ENEMIES := {
	"basic": {
		"scene": "res://scenes/enemies/orc_peon.tscn",
		"gold_drop": 15,
		"health": 40,
		"speed": 60.0,
		"damage": 15,
		"weight": 1.0,
	},
	"fast": {
		"scene": "res://scenes/enemies/orc_explorer.tscn", 
		"gold_drop": 8,
		"health": 30,
		"speed": 80.0,
		"damage": 10,
		"weight": 0.7,
	},
	"tank": {
		"scene": "res://scenes/enemies/orc_tank.tscn",
		"gold_drop": 20,
		"health": 100,
		"speed": 40.0,
		"damage": 25,
		"weight": 1.4,
	},
}

static func types_for_wave(wave: int) -> Array:
	var types := ["basic"]
	if wave >= 3:
		types.append("fast")
	if wave >= 5:
		types.append("tank")
	return types

static func enemy_count_for_wave(wave: int) -> int:
	#var base = 3.0 + wave * 1.5
	var base = 1.0
	var extra = pow(wave * 0.8, 1.5)
	var max_e = 50 + wave * 2
	return min(int(base + extra), max_e)

static func spawn_rate_for_wave(wave: int) -> float:
	return max(0.3, 2.0 - wave * 0.08)

static func random_type_weighted(types: Array) -> String:
	var total_weight := 0.0
	for t in types:
		total_weight += ENEMIES[t].weight
	var r := randf() * total_weight
	var acc := 0.0
	for t in types:
		acc += ENEMIES[t].weight
		if r <= acc:
			return t
	return types[0]
