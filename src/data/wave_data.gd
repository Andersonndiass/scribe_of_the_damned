class_name WaveData
extends Resource
## Uma onda (data-model §6).

@export var chapter: int = 1
@export var index: int = 1
@export var duration: float = 60.0
@export var groups: Array[SpawnGroup] = []
@export var min_spawn_distance: float = 96.0
@export_range(0, 3) var degradation_stage: int = 0
@export_group("Campeões")
## Quantos campeões nesta onda (D-019: 1 a partir da onda 3).
@export var champions: int = 0
## Tipos que podem virar campeão (a Traça não entra, D-040).
@export var champion_pool: Array[EnemyData] = []
## Instantes (s desde o início da onda) em que cada campeão surge.
@export var champion_times: PackedFloat32Array = PackedFloat32Array()
