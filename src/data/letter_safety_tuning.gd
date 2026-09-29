class_name LetterSafetyTuning
extends Resource
## Garantia de letras na luta (006 FR-605; rules-agent).

## Mínimo de letras úteis no chão.
@export var min_useful: int = 3
## Tempo abaixo do mínimo antes de soltar uma letra.
@export var wait: float = 4.0
## Intervalo mínimo entre duas letras de segurança.
@export var cooldown: float = 4.0
## Distância do escriba onde a letra cai.
@export var min_distance: float = 48.0
@export var max_distance: float = 80.0
