class_name RelicSlot
extends RankedSlot
## Um espaço de relíquia (D-103): a relíquia, os postos e o estado vivo do disparo (não vai para o
## save). O RelicRunner escreve `timer`, `charges` e `charge`.

var relic: RelicData
## Tinta paga (venda).
var paid: int = 0
## Relógio do gatilho (s de jogo), cargas do escudo e a recarga 0..1 para o HUD.
var timer: float = 0.0
var charges: int = 0
var charge: float = 0.0


func _init(p_relic: RelicData) -> void:
	relic = p_relic
	if relic.effect == &"absorb":
		charges = relic.base.charges  # vem carregado ao comprar (T1900)


func _upgrades() -> Array[WeaponUpgradeData]:
	return relic.upgrades


func _max_upgrades() -> int:
	return relic.max_upgrades


func _compose(r: Dictionary) -> Resource:
	return relic.compose(r)


func stats() -> RelicLevelData:
	return stats_res()


func preview(uid: StringName) -> RelicLevelData:
	return preview_res(uid)
