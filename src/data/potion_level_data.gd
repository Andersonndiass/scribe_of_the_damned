class_name PotionLevelData
extends Resource
## Números de uma poção num nível (018; rules-agent T1801). Cada efeito usa os campos que precisa.

## Óleo: velas acesas e invulnerabilidade depois (s).
@export var heal: int = 0
@export var iframes: float = 0.0
## Água Benta e Vinho: duração (s de jogo).
@export var duration: float = 0.0
## Água Benta: raio do círculo (px).
@export var radius: float = 0.0
## Vinho: multiplica o intervalo da arma ativa (< 1 = mais rápido).
@export var interval_mul: float = 1.0
## Iluminura: quantas das 3 opções do menu continuam a palavra.
@export var useful_options: int = 1
