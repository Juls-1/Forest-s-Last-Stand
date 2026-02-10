class_name DirectionUtils
extends RefCounted

## Utilidades para convertir vectores de dirección a nombres de animación.
## Uso: DirectionUtils.vector_to_direction_name(direction)

enum Direction { E, SE, S, SW, W, NW, N, NE }

const DIRECTION_NAMES: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

## Convierte un vector de dirección a un nombre de dirección (e, se, s, sw, w, nw, n, ne).
static func vector_to_direction_name(dir: Vector2) -> String:
	if dir.length_squared() < 0.01:
		return "s"  # Default direction
	
	var angle = dir.angle()
	# Normalizar a 0-2PI
	if angle < 0:
		angle += TAU
	
	# Añadir offset de PI/8 para centrar los sectores
	var normalized_angle = fmod(angle + PI / 8, TAU)
	var index = int(normalized_angle / (PI / 4))
	
	return DIRECTION_NAMES[clampi(index, 0, 7)]


## Convierte un vector de dirección a un enum Direction.
static func vector_to_direction(dir: Vector2) -> Direction:
	if dir.length_squared() < 0.01:
		return Direction.S
	
	var angle = dir.angle()
	if angle < 0:
		angle += TAU
	
	var normalized_angle = fmod(angle + PI / 8, TAU)
	var index = int(normalized_angle / (PI / 4))
	
	return index as Direction


## Obtiene el nombre completo de animación (prefijo + dirección).
## Ejemplo: get_animation_name("walk", Vector2(1, 0)) -> "walk_e"
static func get_animation_name(prefix: String, dir: Vector2) -> String:
	return "%s_%s" % [prefix, vector_to_direction_name(dir)]
