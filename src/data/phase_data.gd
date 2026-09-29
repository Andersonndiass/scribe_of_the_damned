class_name PhaseData
extends Resource
## Uma fase de chefe (006 FR-601): começa quando a vida cai a `threshold` (fração) ou menos.

@export var threshold: float = 1.0
@export var attacks: Array[AttackData] = []
## Pesos na mesma ordem de `attacks`.
@export var weights: PackedFloat32Array = PackedFloat32Array()
## Intervalo entre ataques (a F3 do Asmodeus já vem com o ×1,3 aplicado).
@export var interval: float = 1.6
