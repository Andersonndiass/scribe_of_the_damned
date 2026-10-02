class_name RelicTuning
extends Resource
## Relíquias (D-103; rules-agent T1900): espaços, a lista e os limites do teto.

@export var slots: int = 2
## Lista explícita (o build web não lista pastas).
@export var relics: Array[RelicData] = []
## Piso da aura de lentidão (acima do de arma, 0,75; AQUA/SANCTUS seguem mais fortes).
@export var min_slow_factor: float = 0.80
@export var max_charges: int = 2
## Sino: a recarga é sempre ≥ isto × o atordoamento (sem stun-lock).
@export var min_stun_ratio: float = 7.0
## Relicário: invulnerabilidade total máxima (s), como o Óleo nv 3.
@export var max_iframes: float = 1.5
## Selo de Cera: o golpe absorvido dá esta invulnerabilidade (s), como o FIDES.
@export var shield_iframes: float = 1.0


func by_id(rid: StringName) -> RelicData:
	for r: RelicData in relics:
		if r.id == rid:
			return r
	return null
