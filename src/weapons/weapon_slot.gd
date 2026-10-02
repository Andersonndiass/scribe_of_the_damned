class_name WeaponSlot
extends RankedSlot
## Um espaço do inventário: a arma e os postos dos atributos dela (D-099; T1830). Trocar a arma
## perde os postos.

var weapon: WeaponData
## Recarga 0..1 para o HUD (T1800); o Arsenal escreve todo tick. Não vai para o save.
var charge: float = 0.0
## Tinta paga por esta arma (venda, D-103); 0 = a arma inicial (vale `SellTuning.start_weapon_base`).
var paid: int = 0


func _init(p_weapon: WeaponData) -> void:
	weapon = p_weapon


func _upgrades() -> Array[WeaponUpgradeData]:
	return weapon.upgrades


func _max_upgrades() -> int:
	return weapon.max_upgrades


func _compose(r: Dictionary) -> Resource:
	return weapon.compose(r)


func stats() -> WeaponLevelData:
	return stats_res()


func preview(uid: StringName) -> WeaponLevelData:
	return preview_res(uid)
