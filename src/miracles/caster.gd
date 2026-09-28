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
## Combos (002 FR-202): pares e janela. Os pools usam a chave = id do combo (Main registra).
@export var combos: Array[ComboData] = []
@export var combo_tuning: ComboTuning = preload("res://data/tuning/combo.tres")

var heresy_pool: HeresyPool
var combo_book: ComboBook
## VERBUM (FR-210): a última palavra base ou apócrifa conjurada e o poder dela.
var last_repeatable: WordData = null
var last_repeatable_power: float = 0.0

const VERBUM_ID := &"verbum"


func _ready() -> void:
	heresy_pool = HeresyPool.new()
	heresy_pool.name = "HeresyPool"
	add_child(heresy_pool)
	combo_book = ComboBook.new(combos, combo_tuning)
	EventBus.letter_collected.connect(func(_l: String, _r: bool) -> void: combo_book.on_letter_collected())


func _process(delta: float) -> void:
	var was_open: bool = combo_book.is_open()
	combo_book.tick(delta)
	if was_open and not combo_book.is_open():
		EventBus.combo_window_closed.emit()


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
	if word.id == VERBUM_ID:
		return _cast_verbum()
	var rare_mul: float = pow(letter_field.tuning.rare_power_bonus, taken["rare_count"])
	var power: float = word.power_budget * rare_mul
	var origin: Vector2 = player.global_position + PEN_OFFSET
	var direction: Vector2 = player.facing
	var was_open: bool = combo_book.is_open()
	var combo: ComboData = combo_book.on_cast(word)
	if word.group == &"base" or word.group == &"apocrypha":
		last_repeatable = word
		last_repeatable_power = power
	EventBus.word_cast.emit(word, power, origin, direction)
	EventBus.hitstop_requested.emit(CAST_HITSTOP_MS)
	player.pen_flash()
	if combo != null:
		# O combo substitui o milagre da 2ª palavra (FR-202); as vogais raras dela valem para ele.
		var combo_power: float = combo.power_budget * rare_mul
		EventBus.combo_cast.emit(combo, combo_power)
		_start_miracle(combo, combo_power, origin, direction)
	else:
		_start_miracle(word, power, origin, direction)
	if combo_book.is_open():
		EventBus.combo_window_opened.emit(word, combo_tuning.window, _partner_latins())
	elif was_open:
		EventBus.combo_window_closed.emit()
	letter_field.emit_atril()
	return true


## VERBUM: repete a última palavra base ou apócrifa com o mesmo poder. Não mexe na janela de
## combo (D-055, 1A). Sem o que repetir: falha, as letras se perdem, sem heresia (D-055, 2A).
func _cast_verbum() -> bool:
	if last_repeatable == null:
		EventBus.verbum_failed.emit()
		letter_field.emit_atril()
		return false
	var origin: Vector2 = player.global_position + PEN_OFFSET
	var direction: Vector2 = player.facing
	EventBus.verbum_echoed.emit(last_repeatable)
	# O eco conta como a palavra repetida para quem lê as marcas (chefes, FR-202c).
	EventBus.word_cast.emit(last_repeatable, last_repeatable_power, origin, direction)
	EventBus.hitstop_requested.emit(CAST_HITSTOP_MS)
	player.pen_flash()
	_start_miracle(last_repeatable, last_repeatable_power, origin, direction)
	letter_field.emit_atril()
	return true


func _partner_latins() -> PackedStringArray:
	var out := PackedStringArray()
	if not combo_tuning.hint_highlight:
		return out
	var ids: Array[StringName] = combo_book.partner_ids()
	for c: ComboData in combos:
		for w: WordData in [c.word_a, c.word_b]:
			if ids.has(w.id) and not out.has(w.latin):
				out.append(w.latin)
	return out


func _start_miracle(word: WordData, power: float, origin: Vector2, direction: Vector2) -> void:
	if word.miracle_scene != null and PoolManager.is_registered(word.id):
		var miracle := PoolManager.acquire(word.id) as Miracle
		miracle.damage_mul = player.buffs.damage_mul()
		miracle.start(word, power, origin, direction)
	else:
		push_warning("Caster: '%s' não tem cena de milagre registrada" % word.latin)


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
