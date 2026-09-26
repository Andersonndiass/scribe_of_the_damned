class_name SpatialHash
extends RefCounted
## Grade uniforme reconstruída a cada frame por contagem (plan §4.6, Princípio V).
## rebuild() é O(n); as consultas só visitam as células que cobrem o raio.
## Pontos fora do mundo são presos à borda da grade, mas a distância usa a posição real.

var _world: Rect2
var _cell: float
var _cols: int
var _rows: int
var _positions: PackedVector2Array
var _count: int = 0
## Índice da primeira entrada de cada célula em _sorted (tamanho cols*rows + 1).
var _cell_start: PackedInt32Array
## Slots ordenados por célula.
var _sorted: PackedInt32Array
var _cell_of: PackedInt32Array


func _init(world: Rect2, cell_size: float = 32.0) -> void:
	_world = world
	_cell = cell_size
	_cols = maxi(1, ceili(world.size.x / cell_size))
	_rows = maxi(1, ceili(world.size.y / cell_size))
	_cell_start.resize(_cols * _rows + 1)


func rebuild(positions: PackedVector2Array, count: int) -> void:
	_positions = positions
	_count = mini(count, positions.size())
	_cell_start.fill(0)
	_cell_of.resize(_count)
	_sorted.resize(_count)
	for i: int in _count:
		var c: int = _cell_index(positions[i])
		_cell_of[i] = c
		_cell_start[c + 1] += 1
	for c: int in _cols * _rows:
		_cell_start[c + 1] += _cell_start[c]
	var cursor: PackedInt32Array = _cell_start.duplicate()
	for i: int in _count:
		var c: int = _cell_of[i]
		_sorted[cursor[c]] = i
		cursor[c] += 1


# --- acesso direto à grade (laços quentes sem alocar arrays) ----------------------------------
## Índice da 1ª entrada de cada célula em `sorted_slots()`; tamanho cols*rows + 1.
func cell_start() -> PackedInt32Array:
	return _cell_start


## Slots ordenados por célula.
func sorted_slots() -> PackedInt32Array:
	return _sorted


func cols() -> int:
	return _cols


func rows() -> int:
	return _rows


func cell_size() -> float:
	return _cell


func origin() -> Vector2:
	return _world.position


## Todos os slots a até `radius` de `center` (distância euclidiana, borda inclusa).
func query_radius(center: Vector2, radius: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	if _count == 0:
		return out
	var r2: float = radius * radius
	var min_c: Vector2i = _cell_coords(center - Vector2(radius, radius))
	var max_c: Vector2i = _cell_coords(center + Vector2(radius, radius))
	for cy: int in range(min_c.y, max_c.y + 1):
		for cx: int in range(min_c.x, max_c.x + 1):
			var c: int = cy * _cols + cx
			for k: int in range(_cell_start[c], _cell_start[c + 1]):
				var slot: int = _sorted[k]
				if _positions[slot].distance_squared_to(center) <= r2:
					out.append(slot)
	return out


## Slot mais próximo de `center` dentro de `max_radius`, ou -1.
func nearest(center: Vector2, max_radius: float) -> int:
	var best: int = -1
	var best_d: float = max_radius * max_radius
	for slot: int in query_radius(center, max_radius):
		var d: float = _positions[slot].distance_squared_to(center)
		if d <= best_d:
			best_d = d
			best = slot
	return best


func _cell_coords(p: Vector2) -> Vector2i:
	var local: Vector2 = p - _world.position
	return Vector2i(
		clampi(floori(local.x / _cell), 0, _cols - 1),
		clampi(floori(local.y / _cell), 0, _rows - 1))


func _cell_index(p: Vector2) -> int:
	var cc: Vector2i = _cell_coords(p)
	return cc.y * _cols + cc.x
