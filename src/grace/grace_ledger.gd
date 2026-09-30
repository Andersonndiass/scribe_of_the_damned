class_name GraceLedger
extends RefCounted
## Graça da partida (016 FR-1601..FR-1605): quanto falta para o próximo nível e a fila de níveis
## ainda não escolhidos. Lógica pura; vive em `GameState.grace` (zera a cada partida, continua
## entre as ondas e na loja).

var tuning: GraceTuning
var level: int = 1
## Graça acumulada dentro do nível atual.
var progress: int = 0
## Níveis subidos que ainda não viraram escolha de selo.
var pending: int = 0
## Total da partida (sonda).
var total: int = 0


func _init(p_tuning: GraceTuning) -> void:
	tuning = p_tuning


## Graça que falta juntar no nível atual para subir.
func needed() -> int:
	return tuning.cost(level)


## Soma Graça; devolve quantos níveis subiram agora (ficam em `pending`).
func add(amount: int) -> int:
	if amount <= 0:
		return 0
	total += amount
	progress += amount
	var ups: int = 0
	while progress >= needed():
		progress -= needed()
		level += 1
		pending += 1
		ups += 1
	return ups


## Um nível da fila virou escolha.
func consume() -> bool:
	if pending <= 0:
		return false
	pending -= 1
	return true


func clear_pending() -> void:
	pending = 0
