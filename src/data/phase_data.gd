class_name PhaseData
extends Resource
## Uma fase de chefe (006 FR-601): começa quando a vida cai a `threshold` (fração) ou menos.

@export var threshold: float = 1.0
@export var attacks: Array[AttackData] = []
## Pesos na mesma ordem de `attacks`.
@export var weights: PackedFloat32Array = PackedFloat32Array()
## Intervalo entre ataques (a F3 do Asmodeus já vem com o ×1,3 aplicado).
@export var interval: float = 1.6
## Cadência do idle (ms por quadro; animation-agent: F1 140, F2 125, F3 110).
@export var idle_frame_ms: int = 140
@export_group("Ataque por relógio (012)")
## Sai a cada `timed_interval` s (o primeiro `timed_first_delay` s depois da troca de fase), fora
## do sorteio — o Eat_Page da Mãe na F3. Vazio = nenhum.
@export var timed_attack: AttackData
@export var timed_interval: float = 15.0
@export var timed_first_delay: float = 5.0
