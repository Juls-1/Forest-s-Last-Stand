class_name GridUtils
extends RefCounted

## Utilidades para operaciones de grilla/cuadrícula.
## Uso: GridUtils.snap_to_grid(position, grid_size)

## Ajusta una posición al centro de la celda de grilla más cercana.
static func snap_to_grid(pos: Vector2, grid_size: int) -> Vector2:
	var gx := float(grid_size)
	return Vector2(
		floor(pos.x / gx) * gx + gx * 0.5,
		floor(pos.y / gx) * gx + gx * 0.5
	)


## Ajusta una posición a la esquina de la celda de grilla más cercana.
static func snap_to_grid_corner(pos: Vector2, grid_size: int) -> Vector2:
	var gx := float(grid_size)
	return Vector2(
		floor(pos.x / gx) * gx,
		floor(pos.y / gx) * gx
	)


## Convierte una posición del mundo a coordenadas de celda.
static func world_to_cell(pos: Vector2, grid_size: int) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / grid_size)),
		int(floor(pos.y / grid_size))
	)


## Convierte coordenadas de celda a posición del mundo (centro de la celda).
static func cell_to_world(cell: Vector2i, grid_size: int) -> Vector2:
	return Vector2(
		cell.x * grid_size + grid_size * 0.5,
		cell.y * grid_size + grid_size * 0.5
	)
