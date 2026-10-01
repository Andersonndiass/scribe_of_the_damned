class_name PotionTuning
extends Resource
## As 4 poções e as regras comuns (018 FR-1804; rules-agent T1801). `order` = teclas 3, 4, 5, 6.

@export var order: Array[PotionData] = []
## Intervalo mínimo entre duas poções quaisquer (s de jogo).
@export var use_gap: float = 1.5
## Vinho × Pena de Ganso: o intervalo da arma nunca desce abaixo disto × o original.
@export var cadence_floor: float = 0.55
## Cargas no começo da partida (a poção conta como comprada, nível 1).
@export var start: Dictionary[StringName, int] = {&"oil": 1}


func by_id(id: StringName) -> PotionData:
	for p: PotionData in order:
		if p.id == id:
			return p
	return null


func validate() -> String:
	if order.size() != 4:
		return "são 4 poções (teclas 3–6)"
	var ids := {}
	for p: PotionData in order:
		if p == null:
			return "poção vazia"
		var why: String = p.validate()
		if why != "":
			return why
		if ids.has(p.id):
			return "poção repetida: %s" % p.id
		ids[p.id] = true
	for id: StringName in start:
		if not ids.has(id):
			return "poção inicial desconhecida: %s" % id
	return ""
