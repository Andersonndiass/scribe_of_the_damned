class_name EnemyProjectileData
extends Resource
## Projétil inimigo (005 data-model §3). Sempre BLOOD, no máximo 10×10 (art bible §2.2, §10).

@export var id: StringName = &""
@export var speed: float = 90.0
@export var radius: float = 3.0
## 1 = fraco, 2 = forte (D-012).
@export_range(1, 2) var damage: int = 1
@export var lifetime: float = 4.0
@export var size: Vector2i = Vector2i(6, 6)
