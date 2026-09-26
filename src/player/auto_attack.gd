class_name AutoAttack
extends Node
## Ataque automático: a cada attack_interval, dispara uma gota de tinta no inimigo mais próximo
## dentro de attack_range. Sem alvo, não dispara (FR-002). Nunca para enquanto `enabled`.
## As gotas vivem no PlayerProjectileManager, injetado pela cena principal.

signal fired(target: Vector2)

## Ponto de saída relativo à origem (altura da pena do Anselmo).
const MUZZLE := Vector2(0, -8)

@export var origin: Node2D
var data: PlayerData
var projectiles: PlayerProjectileManager
var enabled: bool = true

var _time: float = 0.0


func _ready() -> void:
	if origin == null:
		origin = get_parent() as Node2D


func _physics_process(delta: float) -> void:
	if not enabled or data == null or projectiles == null:
		return
	_time += delta
	while _time >= data.attack_interval:
		_time -= data.attack_interval
		_try_fire()


func _try_fire() -> void:
	var from: Vector2 = origin.global_position + MUZZLE
	var target: Vector2 = EnemyQuery.nearest(from, data.attack_range)
	if target == Vector2.INF:
		return
	if projectiles.fire(from, target - from, data.projectile_speed, data.projectile_damage, data.attack_range * 1.25):
		fired.emit(target)
