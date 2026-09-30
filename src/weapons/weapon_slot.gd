class_name WeaponSlot
extends RefCounted
## Um espaço do inventário: a arma e o nível dela (o nível fica no espaço; trocar a arma o perde).

var weapon: WeaponData
var level: int = 1
## Recarga 0..1 para o HUD (T1800); o Arsenal escreve todo tick. Não vai para o save.
var charge: float = 0.0


func _init(p_weapon: WeaponData, p_level: int = 1) -> void:
	weapon = p_weapon
	level = p_level


func stats() -> WeaponLevelData:
	return weapon.stats(level)


func can_level() -> bool:
	return level < weapon.max_level()
