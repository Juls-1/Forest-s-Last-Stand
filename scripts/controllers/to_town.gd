extends Area2D

@export var target_scene: String = "" # Si se deja vacío, se infiere por el nombre del nodo
var _player_inside: bool = false
var _transitioning: bool = false

# Configura la escena de destino si no se estableció explícitamente
func _ready() -> void:
	# Si no está fijado, inferir por nombre del nodo
	if target_scene == "":
		if name.to_lower() == "totown":
			target_scene = "res://scenes/levels/town.tscn"
		elif name.to_lower() == "toworld":
			target_scene = "res://scenes/levels/world.tscn"

# Detecta la entrada del jugador y dispara la transición
func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return
	if not body.is_in_group("player"):
		return
	# No permitir ir al pueblo durante la defensa (noche)
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.get("is_night") and target_scene.find("/town.tscn") != -1:
		return
	_player_inside = true
	_start_transition()

# Marca que el jugador ha salido del área
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

# Inicia la transición de escena con fade negro
func _start_transition() -> void:
	if _transitioning:
		return
	_transitioning = true
	if target_scene == "":
		_transitioning = false
		return
	_do_transition_with_fade()

func _do_transition_with_fade() -> void:
	if not SceneTransition:
		_do_change_scene()
		return
	await SceneTransition.transition_to_scene(0.4, func(): _do_change_scene())

# Realiza el cambio de escena y persiste estado vía SessionPersistence
func _do_change_scene() -> void:
	if target_scene == "":
		return

	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm:
		get_tree().change_scene_to_file(target_scene)
		return

	var game_state: Dictionary = {
		"current_day": gm.current_day,
		"is_night": gm.is_night,
		"gold": gm.gold,
		"wood": gm.wood,
		"stone": gm.stone,
		"current_wave": gm.current_wave,
		"enemies_remaining": gm.enemies_remaining,
		"enemies_reached_entrance": gm.enemies_reached_entrance,
		"axe_tier": gm.axe_tier,
		"pickaxe_tier": gm.pickaxe_tier,
	}

	var location: String = "world"
	if target_scene.find("/town.tscn") != -1:
		location = "town"
	elif target_scene.find("/world.tscn") != -1:
		location = "world"

	var units_state: Array = []
	if location == "world":
		# Volviendo a world: usar caché guardada al salir de world (en town no hay unidades).
		units_state = SessionPersistence.get_cached_units_state()
	else:
		# Saliendo de world hacia town: guardar unidades actuales del world.
		var um = get_tree().get_first_node_in_group("unit_manager")
		if um and um.has_method("save_state"):
			units_state = um.save_state()
		else:
			for u in get_tree().get_nodes_in_group("friendly_units"):
				if u is Node2D:
					var utype: String = u.get_meta("unit_type") if u.has_meta("unit_type") else ""
					if not utype.is_empty():
						units_state.append({"type": utype, "position": (u as Node2D).global_position})

	SessionPersistence.save(location, game_state, units_state)
	get_tree().change_scene_to_file(target_scene)
