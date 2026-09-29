class_name ObstacleData
extends Resource
## Um obstáculo posto na página (004 FR-408): tipo e canto de cima à esquerda (pixel inteiro).

@export var type: ObstacleTypeData
@export var position: Vector2i = Vector2i.ZERO
## Está na página durante as ondas / durante o chefe (FR-413).
@export var in_waves: bool = true
@export var in_boss: bool = true


func rect() -> Rect2:
	return Rect2(Vector2(position), Vector2(type.footprint)) if type != null else Rect2()
