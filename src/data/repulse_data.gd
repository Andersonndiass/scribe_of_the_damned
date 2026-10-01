class_name RepulseData
extends Resource
## Ímã reverso (017 FR-1712; rules-agent T1700 §6): passivo comprado na loja (uma vez); os níveis
## vêm dos selos. A cada `intervals[n]` s empurra os inimigos no raio e, a partir do nível 3, fere.
## Uma entrada por nível (1..5).

@export var id: StringName = &"reverse_magnet"
@export var display_name: String = "ITEM_REVERSE_MAGNET"
@export var intervals: PackedFloat32Array = PackedFloat32Array()
@export var radii: PackedFloat32Array = PackedFloat32Array()
## Empurrão (px) para longe do escriba.
@export var knockbacks: PackedFloat32Array = PackedFloat32Array()
@export var damages: PackedInt32Array = PackedInt32Array()
## O campeão é empurrado só esta fração (o dano é o normal); o chefe nunca é empurrado.
@export var champion_knockback_mul: float = 0.5
## Sem ninguém no raio, o pulso espera (não gasta a recarga à toa).
@export var hold_when_empty: bool = true


func max_level() -> int:
	return intervals.size()


func at(values: Variant, level: int) -> Variant:
	return values[clampi(level, 1, max_level()) - 1]


## "" se os dados fazem sentido; senão, o motivo.
func validate() -> String:
	var n: int = intervals.size()
	if n == 0 or radii.size() != n or knockbacks.size() != n or damages.size() != n:
		return "níveis do ímã reverso com tamanhos diferentes"
	return ""
