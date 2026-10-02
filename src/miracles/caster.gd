class_name Caster
extends Node
## Liga atril → Lexicon → milagre (FR-017, plan §4.10).
##   Espaço: palavra válida → milagre; letras sem sentido → HERESIA (FR-019); atril vazio → nada.
##   Shift: PURGE (FR-020) — as letras voltam ao chão ao redor do jogador, sem custo, SOLTAS:
##   o ímã as ignora e o jogador escolhe a nova ordem andando por cima (D-031).

## Peso da palavra (017 T1740): hit-stop e tremor por tipo (ataque, tela, ferramenta).
@export var feel: WordFeelData = preload("res://data/tuning/word_feel.tres")
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

## Contador de conjurações (006): cada milagre, eco do VERBUM incluso, é uma conjuração nova.
var _next_cast_id: int = 1


func _ready() -> void:
	heresy_pool = HeresyPool.new()
	heresy_pool.name = "HeresyPool"
	add_child(heresy_pool)
	combo_book = ComboBook.new(combos)
	EventBus.heresy_absolved.connect(_on_heresy_absolved)
	if letter_field != null:
		letter_field.partners_of = func(w: WordData) -> PackedStringArray:
			return combo_book.partners_of(w) if combo_tuning.hint_highlight else PackedStringArray()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.letter_menu_open:
		return  # 017: Espaço e setas são do menu da letra
	if event.is_action_pressed(&"cast"):
		cast()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"purge"):
		purge()
		get_viewport().set_input_as_handled()


## Tenta conjurar (D-099, respostas "1b2a3a"). Retorna true se um milagre foi disparado.
##   atril com palavra pronta + guardada parceira → COMBO (gasta as duas);
##   atril com palavra pronta sem par → conjura a do atril (a guardada fica);
##   atril vazio ou pela metade com guardada → conjura a guardada (as letras do atril ficam);
##   sem guardada e atril pela metade → heresia, como antes.
func cast() -> bool:
	if player == null or not player.vitals.is_alive():
		return false
	var atril: Atril = letter_field.atril
	var guard: WordGuard = letter_field.guard
	if atril.size() > 0 and atril.state(letter_field.lexicon) == Atril.Status.VALID:
		var word: WordData = letter_field.lexicon.word_for(atril.text())
		var combo: ComboData = combo_book.find(guard.word, word) if guard.is_held() else null
		var taken: Dictionary = atril.take_all()
		if combo != null:
			var held: Dictionary = guard.take()
			EventBus.stored_word_released.emit(held["word"], &"combo")
		return _cast_word(word, int(taken["rare_count"]), combo)
	if guard.is_held():
		var stored: Dictionary = guard.take()
		EventBus.stored_word_released.emit(stored["word"], &"cast")
		return _cast_word(stored["word"], int(stored["rare_count"]), null)
	if atril.size() == 0:
		return false
	_commit_heresy()
	return false


## Dispara `word` com as raras dela; com `combo`, o combo substitui o milagre (FR-202; as raras
## da palavra do atril valem para ele).
func _cast_word(word: WordData, rare_count: int, combo: ComboData) -> bool:
	if word.id == VERBUM_ID and combo == null:
		return _cast_verbum()
	var rare_mul: float = pow(letter_field.tuning.rare_power_bonus, rare_count)
	var power: float = word.power_budget * rare_mul
	var origin: Vector2 = player.global_position + PEN_OFFSET
	var direction: Vector2 = aim_direction(origin)
	if word.group == &"base" or word.group == &"apocrypha":
		last_repeatable = word
		last_repeatable_power = power
	EventBus.word_cast.emit(word, power, origin, direction)
	_feel(combo if combo != null else word)
	player.pen_flash()
	if combo != null:
		var combo_power: float = combo.power_budget * rare_mul
		EventBus.combo_cast.emit(combo, combo_power)
		_start_miracle(combo, combo_power, origin, direction)
	else:
		_start_miracle(word, power, origin, direction)
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
	var direction: Vector2 = aim_direction(origin)
	EventBus.verbum_echoed.emit(last_repeatable)
	# O eco conta como a palavra repetida para quem lê as marcas (chefes, FR-202c).
	EventBus.word_cast.emit(last_repeatable, last_repeatable_power, origin, direction)
	_feel(last_repeatable)
	player.pen_flash()
	_start_miracle(last_repeatable, last_repeatable_power, origin, direction)
	letter_field.emit_atril()
	return true


## MISERERE: apaga a poça de heresia ativa e o aggro dela.
func _on_heresy_absolved() -> void:
	heresy_pool.absolve()
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.clear_aggro()


## Direção das palavras direcionais (D-067): o cursor, se a opção estiver ligada e houver mouse;
## senão, para onde o escriba olha.
func aim_direction(origin: Vector2) -> Vector2:
	return Aim.direction(origin, player.facing)


func _feel(w: WordData) -> void:
	var f: Dictionary = feel.for_word(w)
	EventBus.hitstop_requested.emit(f["hitstop_ms"])
	if f["shake_px"] > 0.0:
		EventBus.shake_requested.emit(f["shake_px"], f["shake_time"])


func _start_miracle(word: WordData, power: float, origin: Vector2, direction: Vector2) -> void:
	if word.miracle_scene != null and PoolManager.is_registered(word.id):
		var miracle := PoolManager.acquire(word.id) as Miracle
		var gloria: float = player.buffs.damage_mul()
		miracle.damage_mul = gloria * RunStats.of(player.data).value(&"word_damage_mul")
		miracle.heal_mul = gloria
		miracle.cast_id = _next_cast_id
		miracle.tag = word.id
		_next_cast_id += 1
		miracle.start(word, power, origin, direction)
	else:
		push_warning("Caster: '%s' não tem cena de milagre registrada" % word.latin)


## Shift: esvazia o atril sem heresia (017 D-087). Retorna true se havia letras.
func purge() -> bool:
	if player == null or not player.vitals.is_alive():
		return false
	var atril: Atril = letter_field.atril
	if atril.size() == 0:
		return false
	# 017 T1724 (D-087 item 1): Shift esvazia o atril sem heresia; as letras se perdem (não há
	# mais letras no chão para onde voltar).
	var taken: Dictionary = atril.take_all()
	var letters: PackedStringArray = taken["letters"]
	var center: Vector2 = player.global_position + PURGE_CENTER_OFFSET
	EventBus.atril_purged.emit(letters, center)
	letter_field.emit_atril()
	return true


## Heresia (FR-019): stun, poça de aggro no ponto do erro e atril limpo (as letras se perdem).
func _commit_heresy() -> void:
	var tuning: DropTuning = letter_field.tuning
	var pos: Vector2 = player.global_position
	# MISERERE: a próxima heresia é perdoada — sem stun, sem poça e as letras ficam (FR-212).
	# (Cap. 5: a letra corrompida também passa por aqui.)
	if player.buffs.consume_forgiveness():
		EventBus.heresy_forgiven.emit(pos)
		letter_field.emit_atril()
		return
	letter_field.atril.take_all()
	var stun: float = tuning.heresy_stun * RunStats.of(player.data).value(&"heresy_stun_mul")
	if stun > 0.0:  # Tomé (010): imune ao atordoamento; a poça e o atril limpo continuam
		player.stun(stun)
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.set_aggro(pos, tuning.heresy_pool_time, tuning.heresy_pool_radius)
	heresy_pool.start(pos, tuning.heresy_pool_radius, tuning.heresy_pool_time)
	EventBus.heresy_committed.emit(pos)
	letter_field.emit_atril()
