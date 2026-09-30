class_name LetterField
extends Node2D
## O atril do jogador e de onde vêm as letras (FR-011..FR-016; 017 D-087). As letras não caem mais
## no chão: cada letra que um inimigo soltaria vira um pedido ao menu de escolha (LetterMenu).
## Dono do Lexicon, do Atril, do LetterDropper e do LetterMenu.

## Letras que as palavras podem soltar por conjuração (rules-agent T1700: no máximo 1).
const WORD_LETTERS_PER_CAST := 1

## Rasura (006): não apaga a letra pega há menos disso (s; o BossData manda o valor da luta).
var erase_grace: float = 0.5
var _last_push_msec: int = -100000

@export var player: Player
@export var lexicon_data: LexiconData
@export var tuning: DropTuning

var lexicon := Lexicon.new()
var atril: Atril
var dropper := LetterDropper.new()
var menu: LetterMenu

## Menus abertos desde a última leitura (LetterSafety do chefe conta o tempo sem menu).
var offers_opened: int = 0
## Letras já pedidas por cada conjuração (cast_id → quantas).
var _word_letters: Dictionary[int, int] = {}


func _ready() -> void:
	add_to_group(&"letter_field")
	if not lexicon.load_data(lexicon_data):
		push_error("LetterField: dicionário inválido — %s" % lexicon.error)
	lexicon.set_known_filter(GameState.is_word_known)
	EventBus.word_unlocked.connect(func(_w: WordData) -> void: emit_atril())
	# O LetterField fica pronto antes do Main chamar GameState.start_run: lê direto do jogador.
	atril = Atril.new(RunStats.of(player.data).int_value(&"atril_capacity") if player != null else GameState.atril_capacity)
	menu = LetterMenu.new()
	menu.name = "LetterMenu"
	menu.field = self
	menu.player = player
	add_child(menu)
	var view := LetterMenuView.new()
	view.name = "View"
	view.menu = menu
	menu.add_child(view)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.atril_erase_requested.connect(erase_last_letter)
	EventBus.wave_ended.connect(func(_i: int) -> void: _word_letters.clear())
	EventBus.letter_menu_opened.connect(func(_o: Array) -> void: offers_opened += 1)
	emit_atril()


## Tenta pôr a letra no atril. false = recusada (atril cheio).
func collect(letter: String, rare: bool) -> bool:
	if atril.push(letter, rare):
		_last_push_msec = Time.get_ticks_msec()
		EventBus.letter_collected.emit(letter, rare)
		emit_atril()
		return true
	EventBus.letter_rejected.emit(letter)
	return false


## Rasura (006 FR-609; D-062): apaga a última letra do atril, com as proteções — nunca com a
## palavra pronta (VALID), nunca a letra pega há menos de `erase_grace` s, nada com o atril vazio.
## Retorna a letra apagada ("" se protegida).
func erase_last_letter() -> String:
	if atril.size() == 0 or atril.state(lexicon) == Atril.Status.VALID:
		return ""
	if Time.get_ticks_msec() - _last_push_msec < int(erase_grace * 1000.0):
		return ""
	var gone: Dictionary = atril.pop_last()
	var pos: Vector2 = player.global_position if player != null else Vector2.ZERO
	EventBus.letter_erased.emit(gone["letter"], pos)
	emit_atril()
	return gone["letter"]


## A Traça (017 D-087 item 2): tira a última letra do atril (mesmo com a palavra pronta, sem a
## proteção da Rasura). Retorna a letra ("" com o atril vazio).
func steal_last_letter() -> String:
	if atril.size() == 0:
		return ""
	var gone: Dictionary = atril.pop_last()
	var pos: Vector2 = player.global_position if player != null else Vector2.ZERO
	EventBus.letter_eaten.emit(gone["letter"], pos)
	emit_atril()
	return gone["letter"]


## Pede um menu de segurança (LetterSafety do chefe, 006 FR-605).
func offer_safety() -> void:
	menu.offer()


## Publica o estado do atril e as dicas (FR-023) no EventBus.
func emit_atril() -> void:
	var status: Atril.Status = atril.state(lexicon)
	var hints := PackedStringArray()
	if status == Atril.Status.EMPTY or status == Atril.Status.PARTIAL or status == Atril.Status.VALID:
		for w: WordData in lexicon.words_with_prefix(atril.text(), atril.capacity, tuning.hint_count):
			hints.append(w.latin)
	GameState.atril_capacity = atril.capacity
	EventBus.atril_changed.emit(atril.letters(), status, hints, atril.rare_mask())


func _on_enemy_killed(slot: int, data: EnemyData, _pos: Vector2) -> void:
	var em := EnemyQuery.provider as EnemyManager
	var alive: bool = em != null and slot < em.count
	# REQUIEM marca o slot antes da morte (o sinal sai antes do swap-remove).
	var guaranteed: bool = alive and em.guaranteed_drop[slot] == 1
	var champion: bool = alive and em.champion[slot] == 1
	if not guaranteed and not champion:
		var chance: float = data.letter_drop_chance * GameState.letter_drop_mul
		if player != null:
			chance *= player.buffs.letter_chance_mul()
		if GameState.rng.randf() >= chance:
			return
	# Mortes de palavra: no máximo WORD_LETTERS_PER_CAST letras por conjuração.
	var cast: int = em.kill_cast_id if em != null and em.kill_cast_id > 0 else 0
	if cast == 0 and DamageSource.tag != &"auto" and DamageSource.tag != &"":
		cast = DamageSource.cast_id
	if cast > 0 and not guaranteed:
		var n: int = _word_letters.get(cast, 0)
		if n >= WORD_LETTERS_PER_CAST:
			return
		_word_letters[cast] = n + 1
	menu.offer("", champion)
	# Tinteiro Duplo (003 FR-310b, D-058): um pedido extra (a fila de 1 decide se cabe).
	var stats: RunStats = RunStats.of(player.data) if player != null else null
	var double_chance: float = stats.value(&"double_letter_chance") if stats != null else 0.0
	if double_chance > 0.0 and GameState.rng.randf() < double_chance:
		menu.offer()
