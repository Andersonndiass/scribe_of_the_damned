class_name Hurtbox
extends Area2D
## Área que recebe dano. Respeita invulnerabilidade (i-frames).

signal hit(damage: int, source_tag: StringName)

var invulnerable: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		receive((area as Hitbox).damage, (area as Hitbox).source_tag)


## Entrada de dano que não vem de física (ex.: contato calculado pelo EnemyManager).
func receive(damage: int, source_tag: StringName = &"") -> void:
	if invulnerable:
		return
	hit.emit(damage, source_tag)
