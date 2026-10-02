class_name WeaponSlot
extends RefCounted
## Um espaço do inventário: a arma e os postos dos atributos dela (D-098; T1830): nível = 1 +
## compras. Os números ficam em cache (o Arsenal lê várias vezes por tick); `rank_up` refaz.
## Trocar a arma perde os postos.

var weapon: WeaponData
## id do atributo → posto (0 = base).
var ranks: Dictionary[StringName, int] = {}
var level: int:
	get:
		return 1 + bought()
## Recarga 0..1 para o HUD (T1800); o Arsenal escreve todo tick. Não vai para o save.
var charge: float = 0.0
var _cache: WeaponLevelData


func _init(p_weapon: WeaponData) -> void:
	weapon = p_weapon


func stats() -> WeaponLevelData:
	if _cache == null:
		_cache = weapon.compose(ranks)
	return _cache


## Os números com +1 posto em `uid` (prévia do selo; aloca).
func preview(uid: StringName) -> WeaponLevelData:
	var r: Dictionary = ranks.duplicate()
	r[uid] = int(r.get(uid, 0)) + 1
	return weapon.compose(r)


func bought() -> int:
	var n: int = 0
	for uid: StringName in ranks:
		n += ranks[uid]
	return n


func rank(uid: StringName) -> int:
	return ranks.get(uid, 0)


## Atributos que ainda podem subir, na ordem dos dados.
func free_upgrades() -> Array[WeaponUpgradeData]:
	var out: Array[WeaponUpgradeData] = []
	if bought() >= weapon.max_upgrades:
		return out
	for u: WeaponUpgradeData in weapon.upgrades:
		if rank(u.id) < u.max_rank():
			out.append(u)
	return out


func can_level() -> bool:
	return not free_upgrades().is_empty()


func rank_up(uid: StringName) -> bool:
	var u: WeaponUpgradeData = weapon.upgrade(uid)
	if u == null or bought() >= weapon.max_upgrades or rank(uid) >= u.max_rank():
		return false
	ranks[uid] = rank(uid) + 1
	_cache = null
	return true


## Sobe o 1º atributo livre na ordem dos dados (sonda, stress, `?wlevel`); &"" se não há.
func auto_rank_up() -> StringName:
	var free: Array[WeaponUpgradeData] = free_upgrades()
	if free.is_empty():
		return &""
	rank_up(free[0].id)
	return free[0].id


## Sobe `n` postos pela ordem dos dados (debug e testes).
func auto_rank_up_times(n: int) -> void:
	for k: int in n:
		if auto_rank_up() == &"":
			return
