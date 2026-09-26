class_name SpawnGroup
extends Resource
## Um grupo de spawn dentro de uma onda (data-model §5).

@export var enemy: EnemyData
@export var start_time: float = 0.0
@export var end_time: float = 60.0
@export var spawn_rate_start: float = 0.5
@export var spawn_rate_end: float = 1.0
@export var max_alive: int = 60


## Ritmo de spawn (inimigos/s) no instante t da onda; 0 fora da janela do grupo.
func rate_at(t: float) -> float:
	if t < start_time or t >= end_time or end_time <= start_time:
		return 0.0
	var k: float = (t - start_time) / (end_time - start_time)
	return lerpf(spawn_rate_start, spawn_rate_end, k)
