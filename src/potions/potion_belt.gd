class_name PotionBelt
extends RefCounted
## Cargas, nível e efeitos em curso das 4 poções (018 T1806; mechanics-agent T1801). Lógica pura:
## quem bebe é o PotionUser; a loja põe carga; o selo sobe o nível. Nível 0 = nunca comprada.

var tuning: PotionTuning
var _charges: Dictionary[StringName, int] = {}
var _level: Dictionary[StringName, int] = {}
## Efeito em curso: id → s de jogo que faltam (Água Benta, Vinho, invulnerabilidade do Óleo).
var left: Dictionary[StringName, float] = {}
## Vinho: o espaço de arma que estava ativo ao beber e o multiplicador do nível.
var fervor_slot: int = -1
var fervor_mul: float = 1.0


func _init(p_tuning: PotionTuning) -> void:
	tuning = p_tuning
	for id: StringName in tuning.start:
		_level[id] = 1
		_charges[id] = mini(tuning.start[id], tuning.by_id(id).max_charges)


func charges(id: StringName) -> int:
	return _charges.get(id, 0)


func level(id: StringName) -> int:
	return _level.get(id, 0)


func owned(id: StringName) -> bool:
	return level(id) > 0


func max_charges(id: StringName) -> int:
	var p: PotionData = tuning.by_id(id)
	return p.max_charges if p != null else 0


func is_full(id: StringName) -> bool:
	return charges(id) >= max_charges(id)


## +1 carga (loja), respeitando o teto. A 1ª compra põe a poção no nível 1.
func add_charge(id: StringName) -> bool:
	if tuning.by_id(id) == null or is_full(id):
		return false
	_charges[id] = charges(id) + 1
	if level(id) == 0:
		_level[id] = 1
	EventBus.potion_charges_changed.emit(id, charges(id), max_charges(id))
	return true


func consume(id: StringName) -> bool:
	if charges(id) <= 0:
		return false
	_charges[id] = charges(id) - 1
	EventBus.potion_charges_changed.emit(id, charges(id), max_charges(id))
	return true


func can_level(id: StringName) -> bool:
	var p: PotionData = tuning.by_id(id)
	return p != null and owned(id) and level(id) < p.max_level()


func level_up(id: StringName) -> bool:
	if not can_level(id):
		return false
	_level[id] = level(id) + 1
	EventBus.potion_leveled.emit(id, level(id))
	return true


## Poções que um selo pode subir (compradas e abaixo do máximo), na ordem das teclas.
func levelable_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for p: PotionData in tuning.order:
		if can_level(p.id):
			out.append(p.id)
	return out


func stats(id: StringName) -> PotionLevelData:
	return tuning.by_id(id).stats(maxi(level(id), 1))


func active(id: StringName) -> bool:
	return left.get(id, 0.0) > 0.0


## Vinho: multiplicador do intervalo da arma no espaço `slot` (1 fora do efeito ou de outro espaço).
func cadence_mul(slot: int) -> float:
	return fervor_mul if active(&"wine") and slot == fervor_slot else 1.0
