class_name RankedSlot
extends RefCounted
## Postos por atributo com cache (D-099 armas; D-103 relíquias; mechanics-agent 019): nível = 1 +
## compras; cada `rank_up` refaz o cache. As filhas dizem quais atributos, o teto de compras e
## como compor os números (`_upgrades`, `_max_upgrades`, `_compose`).

## id do atributo → posto (0 = base).
var ranks: Dictionary[StringName, int] = {}
var level: int:
	get:
		return 1 + bought()
var _cache: Resource


func _upgrades() -> Array[WeaponUpgradeData]:
	return []


func _max_upgrades() -> int:
	return 0


func _compose(_r: Dictionary) -> Resource:
	return null


func upgrade(uid: StringName) -> WeaponUpgradeData:
	for u: WeaponUpgradeData in _upgrades():
		if u.id == uid:
			return u
	return null


## Os números de agora (em cache: lidos várias vezes por tick).
func stats_res() -> Resource:
	if _cache == null:
		_cache = _compose(ranks)
	return _cache


## Os números com +1 posto em `uid` (prévia do selo; aloca).
func preview_res(uid: StringName) -> Resource:
	var r: Dictionary = ranks.duplicate()
	r[uid] = int(r.get(uid, 0)) + 1
	return _compose(r)


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
	if bought() >= _max_upgrades():
		return out
	for u: WeaponUpgradeData in _upgrades():
		if rank(u.id) < u.max_rank():
			out.append(u)
	return out


func can_level() -> bool:
	return not free_upgrades().is_empty()


func rank_up(uid: StringName) -> bool:
	var u: WeaponUpgradeData = upgrade(uid)
	if u == null or bought() >= _max_upgrades() or rank(uid) >= u.max_rank():
		return false
	ranks[uid] = rank(uid) + 1
	_cache = null
	return true


## Sobe o 1º atributo livre na ordem dos dados (sonda, stress, debug); &"" se não há.
func auto_rank_up() -> StringName:
	var free: Array[WeaponUpgradeData] = free_upgrades()
	if free.is_empty():
		return &""
	rank_up(free[0].id)
	return free[0].id


func auto_rank_up_times(n: int) -> void:
	for k: int in n:
		if auto_rank_up() == &"":
			return
