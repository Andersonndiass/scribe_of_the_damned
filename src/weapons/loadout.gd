class_name Loadout
extends RefCounted
## Inventário da partida (017 FR-1701, FR-1702, FR-1704): 2 espaços de arma, a ativa e os passivos
## (id → nível). Lógica pura; vive em `GameState.loadout` e zera a cada partida.

var slots: Array[WeaponSlot] = []
var active: int = 0
var passives: Dictionary[StringName, int] = {}


func _init(slot_count: int = 2, start: WeaponData = null) -> void:
	slots.resize(slot_count)
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
	for s: WeaponSlot in slots:
		if s != null and s.weapon.id == id:
			return true
	return passives.get(id, 0) > 0


func owned_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for s: WeaponSlot in slots:
		if s != null:
			out.append(s.weapon.id)
	for id: StringName in passives:
		if passives[id] > 0:
			out.append(id)
	return out
