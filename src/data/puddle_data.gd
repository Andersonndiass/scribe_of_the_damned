class_name PuddleData
extends Resource
## Poça de lentidão deixada pelo Borrão (005 data-model §4, ficha 11).

@export var id: StringName = &""
@export var size: Vector2 = Vector2(24, 10)
@export var duration: float = 3.0
@export_range(0.0, 1.0) var player_slow_factor: float = 0.6
