class_name BossHurtbox
extends Node2D
## Contrato do chefe como alvo das palavras e do ataque automático (006, mechanics-agent):
## o EnemyManager testa este círculo em cada função de dano e repassa com a origem do golpe.
## O Boss estende esta classe; os testes usam um falso.

func hurt_center() -> Vector2:
	return global_position


func hurt_radius() -> float:
	return 0.0


## Está na página e pode ser mirado/ferido?
func is_targetable() -> bool:
	return false


## As armas podem mirar? (012: o chefe que só leva palavra sai da mira das armas.)
func is_weapon_target() -> bool:
	return true


## Recebe `amount` de `tag` (id da palavra/combo, &"auto", &"purgo") da conjuração `cast_id`.
func take(_amount: int, _tag: StringName, _cast_id: int) -> void:
	pass


## Stun pedido por um milagre (DOMINUS); o chefe aplica o próprio multiplicador.
func stun(_seconds: float) -> void:
	pass
