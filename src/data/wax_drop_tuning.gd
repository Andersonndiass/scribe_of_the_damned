class_name WaxDropTuning
extends Resource
## Pingo de cera (016 FR-1615; rules-agent e animation-agent T1600): vela apagada que cai raramente
## de inimigo comum; pisar acende velas. A chance mora em `EnemyData.wax_drop_chance`.

@export var heal_candles: int = 1
@export var lifetime: float = 12.0
## Máximo no chão (tamanho do pool).
@export var pool_size: int = 3
@export var pickup_radius: float = 6.0
## Só pode ser pego depois disto (a queda).
@export var pickup_lock: float = 0.2
@export_group("Animação")
@export var spawn_step: float = 0.05
@export var idle_step: float = 0.7
@export var blink_time: float = 2.0
@export var blink_slow: float = 0.1
@export var blink_fast: float = 0.05
@export var blink_fast_window: float = 0.5
@export var blink_alpha: float = 0.3
@export var reject_shake: float = 0.1
@export var collect_time: float = 0.1
