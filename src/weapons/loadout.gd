class_name Loadout
extends RefCounted
## Inventário da partida (017 FR-1701, FR-1702, FR-1704; 019 D-103): 2 espaços de arma, a ativa e
## 2 espaços de relíquia. Lógica pura; vive em `GameState.loadout` e zera a cada partida.

var slots: Array[WeaponSlot] = []
var active: int = 0
var relics: Array[RelicSlot] = []


func _init(slot_count: int = 2, start: WeaponData = null, relic_count: int = 2) -> void:
	slots.resize(slot_count)
	relics.resize(relic_count)
	if start != null:
		slots[0] = WeaponSlot.new(start)


func active_slot() -> WeaponSlot:
	return slots[active] if active >= 0 and active < slots.size() else null


func weapon(i: int) -> WeaponData:
	return slots[i].weapon if i >= 0 and i < slots.size() and slots[i] != null else null


## Põe a arma no 1º espaço vazio; com os dois cheios, substitui a ativa. Devolve o espaço.
func equip(w: WeaponData) -> int:
	for i: int in slots.size():
		if slots[i] == null:
			slots[i] = WeaponSlot.new(w)
			return i
	slots[active] = WeaponSlot.new(w)
	return active


func is_full() -> bool:
	for s: WeaponSlot in slots:
		if s == null:
			return false
	return true


## Troca a arma ativa. Falso se o espaço está vazio ou já é o ativo.
func set_active(i: int) -> bool:
	if i < 0 or i >= slots.size() or slots[i] == null or i == active:
		return false
	active = i
	return true


func can_level(i: int) -> bool:
	return i >= 0 and i < slots.size() and slots[i] != null and slots[i].can_level()


## Sobe 1 posto do atributo `uid` da arma do espaço `i` (D-098).
func rank_up(i: int, uid: StringName) -> bool:
	return can_level(i) and slots[i].rank_up(uid)


func has(id: StringName) -> bool:
	return owned_ids().has(id)


func weapon_count() -> int:
	var n: int = 0
	for s: WeaponSlot in slots:
		if s != null:
			n += 1
	return n


## Tira a arma do espaço `i` (venda). Nunca a última; se era a ativa, a ativa vira a outra.
func remove_weapon(i: int) -> WeaponSlot:
	if i < 0 or i >= slots.size() or slots[i] == null or weapon_count() <= 1:
		return null
	var out: WeaponSlot = slots[i]
	slots[i] = null
	if active == i:
		for k: int in slots.size():
			if slots[k] != null:
				active = k
				break
	return out


func relic(i: int) -> RelicSlot:
	return relics[i] if i >= 0 and i < relics.size() else null


func relics_full() -> bool:
	for r: RelicSlot in relics:
		if r == null:
			return false
	return true


## Põe a relíquia no 1º espaço vazio, ou no `replace` (cheio). Devolve o espaço, ou −1.
func equip_relic(r: RelicData, replace: int = -1) -> int:
	for i: int in relics.size():
		if relics[i] == null:
			relics[i] = RelicSlot.new(r)
			return i
	if replace >= 0 and replace < relics.size():
		relics[replace] = RelicSlot.new(r)
		return replace
	return -1


func remove_relic(i: int) -> RelicSlot:
	if i < 0 or i >= relics.size() or relics[i] == null:
		return null
	var out: RelicSlot = relics[i]
	relics[i] = null
	return out


func relic_rank_up(i: int, uid: StringName) -> bool:
	return relic(i) != null and relic(i).rank_up(uid)


func owned_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for s: WeaponSlot in slots:
		if s != null:
			out.append(s.weapon.id)
	for r: RelicSlot in relics:
		if r != null:
			out.append(r.relic.id)
	return out
