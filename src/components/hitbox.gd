class_name Hitbox
extends Area2D
## Área que causa dano ao entrar numa Hurtbox (projéteis inimigos, ataques de chefe).

## Nível de dano: 1 = fraco, 2 = forte (D-012).
@export_range(1, 2) var damage: int = 1
## Tag de origem usada pelo DamageFilter dos chefes (feature 006).
@export var source_tag: StringName = &""
