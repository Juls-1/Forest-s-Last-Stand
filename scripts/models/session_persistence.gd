extends Node

## API única para guardar/cargar estado de sesión entre world y town (meta del SceneTree).
## Acceso global vía Autoload "SessionPersistence" (no usar class_name para no ocultar el singleton).

## Al cargar town, units_state (de world) se guarda aquí para usarlo al volver a world.
var _cached_units_state: Array = []

## Guarda estado en el árbol actual. Debe llamarse antes de change_scene_to_file.
## game_state: dict con current_day, is_night, gold, wood, stone, current_wave, enemies_remaining, enemies_reached_entrance.
## units_state: array de {type, position} (p. ej. desde UnitManager.save_state()).
func save(location: String, game_state: Dictionary, units_state: Array) -> void:
	var st = Engine.get_main_loop() as SceneTree
	if not st:
		return
	st.set_meta("location", location)
	st.set_meta("game_state", game_state)
	st.set_meta("units_state", units_state)


## Carga estado del árbol y lo borra de meta para evitar reuso. Devuelve { location, game_state, units_state }.
## Si viene units_state (p. ej. al cargar town desde world), se guarda en caché para usarlo al volver a world.
func load_session() -> Dictionary:
	var st = Engine.get_main_loop() as SceneTree
	var out := {
		"location": "",
		"game_state": null,
		"units_state": null
	}
	if not st:
		return out

	if st.has_meta("location"):
		out.location = String(st.get_meta("location"))
		st.remove_meta("location")

	if st.has_meta("game_state"):
		var data = st.get_meta("game_state")
		if typeof(data) == TYPE_DICTIONARY:
			out.game_state = data
		st.remove_meta("game_state")

	if st.has_meta("units_state"):
		var units = st.get_meta("units_state")
		if typeof(units) == TYPE_ARRAY:
			out.units_state = units
			_cached_units_state = units.duplicate()
		st.remove_meta("units_state")

	return out


## Devuelve el units_state guardado al ir de world a town (para usarlo al volver a world).
func get_cached_units_state() -> Array:
	return _cached_units_state.duplicate()


## Limpia la caché tras restaurar unidades en world.
func clear_cached_units_state() -> void:
	_cached_units_state.clear()
