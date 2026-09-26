class_name Caster
extends Node
## Liga atril → Lexicon → milagre (FR-017, plan §4.10).
##   Espaço: palavra válida → milagre; letras sem sentido → HERESIA (FR-019); atril vazio → nada.
##   Shift: PURGE (FR-020) — as letras voltam ao chão ao redor do jogador, sem custo, SOLTAS:
##   o ímã as ignora e o jogador escolhe a nova ordem andando por cima (D-031).

## Hit-stop da conjuração (design-tokens: hitstop_ms.cast).
const CAST_HITSTOP_MS := 60
## A pena fica na altura do peito do Anselmo.
const PEN_OFFSET := Vector2(0, -8)
## As letras do purge saem em anel ao redor do corpo, não dos pés.
const PURGE_CENTER_OFFSET := Vector2(0, -6)

@export var letter_field: LetterField
@export var player: Player

var heresy_pool: HeresyPool


func _ready() -> void:
	heresy_pool = HeresyPool.new()
	heresy_pool.name = "HeresyPool"
	add_child(heresy_pool)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cast"):
		cast()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"purge"):
		purge()
		get_viewport().set_input_as_handled()


## Tenta conjurar. Retorna true se um milagre foi disparado.
func cast() -> bool:
	if player == null or not player.vitals.is_alive():
		return false
	var atril: Atril = letter_field.atril
	if atril.size() == 0:
		return false
	if atril.state(letter_field.lexicon) != Atril.Status.VALID:
		_commit_heresy()
		return false
	var word: WordData = letter_field.lexicon.word_for(atril.text())
	var taken: Dictionary = atril.take_all()
	var power: float = word.power_budget * pow(letter_field.tuning.rare_power_bonus, taken["rare_count"])
	var origin: Vector2 = player.global_position + PEN_OFFSET
	var direction: Vector2 = player.facing
	EventBus.word_cast.emit(word, power, origin, direction)
	EventBus.hitstop_requested.emit(CAST_HITSTOP_MS)
	player.pen_flash()
	if word.miracle_scene != null and PoolManager.is_registered(word.id):
		var miracle := PoolManager.acquire(word.id) as Miracle
		miracle.start(word, power, origin, direction)
	else:
		push_warning("Caster: '%s' não tem cena de milagre registrada" % word.latin)
	letter_field.emit_atril()
	return true


## Shift: devolve as letras ao chão, num anel ao redor do jogador. Retorna true se havia letras.
func purge() -> bool:
	if player == null or not player.vitals.is_alive():
		return false
	var atril: Atril = letter_field.atril
	if atril.size() == 0:
		return false
	var tuning: DropTuning = letter_field.tuning
	var taken: Dictionary = atril.take_all()
	var letters: PackedStringArray = taken["letters"]
	var rare: Array = taken["rare"]
	var center: Vector2 = player.global_position + PURGE_CENTER_OFFSET
	for i: int in letters.size():
		var angle: float = TAU * float(i) / letters.size() - PI / 2.0
		var pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * tuning.purge_scatter_radius
		letter_field.spawn_letter(letters[i], rare[i], false, pos, tuning.purge_pickup_lock, true)
	EventBus.atril_purged.emit(letters, center)
	letter_field.emit_atril()
	return true


## Heresia (FR-019): stun, poça de aggro no ponto do erro e atril limpo (as letras se perdem).
func _commit_heresy() -> void:
	var tuning: DropTuning = letter_field.tuning
	var pos: Vector2 = player.global_position
	letter_field.atril.take_all()
	player.stun(tuning.heresy_stun)
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.set_aggro(pos, tuning.heresy_pool_time, tuning.heresy_pool_radius)
	heresy_pool.start(pos, tuning.heresy_pool_radius, tuning.heresy_pool_time)
	EventBus.heresy_committed.emit(pos)
	letter_field.emit_atril()
