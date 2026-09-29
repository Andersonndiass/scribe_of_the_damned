class_name BossDamageFilterData
extends Resource
## Tetos de dano no chefe (006 FR-604, rules-agent; D-062).

## Soma de uma mesma conjuração até aqui entra inteira.
@export var cast_soft_cap: float = 120.0
## Entre o suave e este, entra `over_soft_mul` do excedente; acima, nada.
@export var cast_hard_cap: float = 240.0
@export var over_soft_mul: float = 0.5
## Fontes sem teto por conjuração (ataque automático; PURGO já é literal).
@export var uncapped_tags: Array[StringName] = [&"auto", &"purgo"]
