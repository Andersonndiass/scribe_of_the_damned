class_name ChampionRewards
extends Node
## Recompensas da morte de campeão (005 FR-511, D-011): +1 vela e 3–5 gotas de tinta dourada.
## O hit-stop de 40 ms sai do EnemyManager junto com o sinal.

@export var tuning: ChampionTuning = preload("res://data/tuning/champion.tres")
@export var player: Player
@export var gold: GoldInkField

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1348
	EventBus.champion_killed.connect(_on_champion_killed)


func _on_champion_killed(_data: EnemyData, pos: Vector2) -> void:
	if player != null:
		player.heal(tuning.heal_candles)
	if gold != null:
		gold.spawn_drops(_rng.randi_range(tuning.gold_drops_min, tuning.gold_drops_max), pos)
