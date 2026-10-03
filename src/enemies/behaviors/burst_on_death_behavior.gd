class_name BurstOnDeathBehavior
extends ChaseBehavior
## Traça-Mãe pequena (012 FR-1207; T1200 §3): persegue e, ao morrer, estoura em `burst_count`
## inimigos `burst_enemy` em volta da carcaça. O estouro vai para a fila do manager (esvaziada no
## fim do tick), nunca no meio dos laços. Teto de vivas do tipo filho: `burst_max_alive`. As crias
## nascem congeladas por `burst_grace` s (sem contato e sem roubar do atril). Dentro de uma zona
## letal viva nascem 0 (abafadas, FR-1208).

@export var burst_enemy: EnemyData
@export var burst_count: int = 3
@export var burst_max_alive: int = 14
@export var burst_radius: float = 14.0
@export var burst_grace: float = 0.4


func on_death(m: EnemyManager, i: int) -> void:
	m.queue_burst(m.positions[i], self)
