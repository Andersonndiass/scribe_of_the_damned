class_name WeaponLevelData
extends Resource
## Números de uma arma num nível (017; rules-agent T1700). Cada padrão usa os campos que precisa;
## os outros ficam em 0.

## Dano por acerto (inteiro: a vida dos inimigos é inteira).
@export var damage: int = 1
## Rajada/leque: tempo entre disparos. Raio/órbita/rastro: tempo entre toques no mesmo inimigo.
@export var interval: float = 0.8
@export var range: float = 160.0
## Projéteis: velocidade (px/s).
@export var speed: float = 220.0
## Quantos projéteis por disparo (Pena: nos N mais próximos) ou contas (Rosário).
@export var count: int = 1
## Quantos inimigos um projétil ou o raio fere no máximo (0 ou 1 = só o primeiro). Bíblia: os 2
## mais próximos; Crucifixo: até 8 (rules-agent, 2026-09-30).
@export var pierce: int = 0
## Raio: largura (px). Projétil: diâmetro do acerto (0 = o da gota de tinta).
@export var width: float = 0.0
@export var spread_deg: float = 0.0
@export var orbit_radius: float = 0.0
@export var orbit_period: float = 0.0
@export var trail_life: float = 0.0
## D-098 (T1830): lentidão no acerto (fator de velocidade e duração); 1 = nenhuma. Piso 0,75.
@export var slow_factor: float = 1.0
@export var slow_time: float = 0.0
