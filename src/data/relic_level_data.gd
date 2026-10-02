class_name RelicLevelData
extends Resource
## Números de uma relíquia (D-103; rules-agent T1900). Cada gatilho usa os campos que precisa.

## Pulso: tempo entre pulsos. Aura: tique da aura. Escudo: recarga de 1 carga. Ao tomar dano: recarga.
@export var interval: float = 5.0
@export var radius: float = 56.0
@export var damage: int = 0
@export var knockback: float = 0.0
## Atordoamento (s) do pulso do Sino.
@export var stun: float = 0.0
## Lentidão da aura (fator) e quanto ela dura em quem saiu do raio (s; > interval: não pisca).
@export var slow_factor: float = 1.0
@export var slow_time: float = 0.0
## Escudo: cargas máximas.
@export var charges: int = 0
## Relicário: invulnerabilidade extra (s) ao disparar (o total fica ≤ RelicTuning.max_iframes).
@export var iframes_bonus: float = 0.0
