class_name LetterMenu
extends Node
## Menu de escolha da letra (017 T1719; mechanics-agent T1700; D-087). Substitui as letras no chão:
## cada letra que um inimigo soltaria vira um pedido na fila; o menu abre com 3 opções (1 continua
## a palavra), o jogo entra em câmera lenta e o escriba fica parado; setas + Espaço ou clique
## escolhem; se o tempo acabar, a letra se perde.
## FSM: IDLE → OPEN → (escolha | tempo) → GAP → IDLE. Com o jogo pausado, nada anda (o nó é
## pausável). O relógio desconta a câmera lenta e o hit-stop (tempo de jogo a ×1).

enum Phase { IDLE, OPEN, GAP }

const SLOW_OWNER := &"letter_menu"
const MIDDLE := 1

@export var tuning: LetterMenuTuning = preload("res://data/tuning/letter_menu.tres")
var field: LetterField
var player: Player
## Desligado em testes que não querem o menu (o pedido some sem abrir).
var enabled: bool = true

var phase: Phase = Phase.IDLE
var options: Array[Dictionary] = []
var focus: int = MIDDLE
## Tempo que falta e o total desta abertura (s de jogo a ×1).
var left: float = 0.0
var total: float = 0.0
var open_for: float = 0.0

## Pedidos esperando: {"forced": String, "rare_first": bool}.
var _queue: Array[Dictionary] = []
var _gap: float = 0.0
var _ramp := PackedFloat32Array()
var _ramp_step: float = 0.0
var _ramp_t: float = 0.0


func _ready() -> void:
	EventBus.wave_ended.connect(func(_i: int) -> void: cancel())
	EventBus.player_died.connect(cancel)


## A cena sai com o menu aberto (reiniciar, trocar de tela): nada de câmera lenta nem escriba
## parado na próxima.
func _exit_tree() -> void:
	cancel()


func is_open() -> bool:
	return phase == Phase.OPEN


func queued() -> int:
	return _queue.size()


## Pede um menu. `forced`: letra que precisa estar entre as opções (a Traça devolvendo a que
## roubou; entra sempre, na frente: é a letra do jogador voltando); `rare_first`: a certa sai
## rara (campeão). Falso se a fila estava cheia (perdida).
func offer(forced: String = "", rare_first: bool = false) -> bool:
	if not enabled:
		return false
	if forced != "":
		_queue.push_front({"forced": forced, "rare_first": rare_first})
		return true
	if _queue.size() >= tuning.queue_cap:
		EventBus.letter_offer_dropped.emit()
		return false
	_queue.append({"forced": forced, "rare_first": rare_first})
	return true


## Fim da onda e morte: descarta a fila e fecha sem escolher.
func cancel() -> void:
	_queue.clear()
	if phase == Phase.OPEN:
		options.clear()
		EventBus.letter_menu_closed.emit()
	phase = Phase.IDLE
	GameState.letter_menu_open = false
	_ramp = PackedFloat32Array()
	TimeScale.clear(SLOW_OWNER)


func _process(delta: float) -> void:
	var product: float = TimeScale.factor_product()
	var dt: float = delta / product if product > 0.001 else 0.0
	_tick_ramp(dt)
	match phase:
		Phase.OPEN:
			left -= dt
			open_for += dt
			if left <= 0.0:
				_expire()
		Phase.GAP:
			_gap -= dt
			if _gap <= 0.0:
				phase = Phase.IDLE
				if _queue.is_empty() or not _can_open():
					_start_ramp(tuning.slow_out_steps, tuning.slow_out_step_time)
	if phase == Phase.IDLE and not _queue.is_empty() and _can_open():
		_open()


func _can_open() -> bool:
	if field == null or (player != null and not player.vitals.is_alive()) or GameState.levelup_beam:
		return false  # 018: durante o feixe do nível o pedido espera na fila
	var st: Atril.Status = field.atril.state(field.lexicon)
	return not field.atril.is_full() and st != Atril.Status.VALID


func _open() -> void:
	var req: Dictionary = _queue.pop_front()
	options = LetterOfferRoll.roll(field.atril, field.lexicon, field.tuning, tuning, GameState.rng,
		GameState.unlocked_words, req["forced"], req["rare_first"])
	if options.is_empty():
		EventBus.letter_offer_dropped.emit()  # sem letra possível: o pedido se perde, com aviso
		return
	focus = mini(MIDDLE, options.size() - 1)
	var extra: float = 0.0
	if player != null:
		extra = minf(RunStats.of(player.data).value(&"menu_time_add"), tuning.time_add_cap)
	total = tuning.menu_time + extra
	left = total
	open_for = 0.0
	phase = Phase.OPEN
	GameState.letter_menu_open = true
	if not TimeScale.has_factor(SLOW_OWNER) or _ramp.size() > 0 and _ramp[_ramp.size() - 1] >= 1.0:
		_start_ramp(tuning.slow_in_steps, tuning.slow_in_step_time)
	EventBus.letter_menu_opened.emit(options)


## Escolhe a opção `i` (Espaço ou clique). Falso se fechado ou na trava do começo.
func pick(i: int) -> bool:
	if phase != Phase.OPEN or open_for < tuning.pick_guard or i < 0 or i >= options.size():
		return false
	var o: Dictionary = options[i]
	field.collect(o["letter"], o["rare"])
	EventBus.letter_chosen.emit(o["letter"], o["rare"])
	_close()
	return true


func move_focus(step: int) -> void:
	if phase == Phase.OPEN and not options.is_empty():
		focus = clampi(focus + step, 0, options.size() - 1)


func _expire() -> void:
	EventBus.letter_lost.emit()
	_close()


func _close() -> void:
	options.clear()
	phase = Phase.GAP
	_gap = tuning.reopen_gap
	GameState.letter_menu_open = false
	EventBus.letter_menu_closed.emit()


func _input(event: InputEvent) -> void:
	if phase != Phase.OPEN or not event.is_pressed() or event.is_echo():
		return
	if event.is_action(&"letter_prev"):
		move_focus(-1)
	elif event.is_action(&"letter_next"):
		move_focus(1)
	elif event.is_action(&"letter_pick"):
		pick(focus)
	else:
		return
	get_viewport().set_input_as_handled()


# --- câmera lenta em degraus (animation-agent) -------------------------------------------------

func _start_ramp(steps: PackedFloat32Array, step_time: float) -> void:
	_ramp = steps
	_ramp_step = step_time
	_ramp_t = 0.0
	_apply_ramp()


func _tick_ramp(dt: float) -> void:
	if _ramp.is_empty():
		return
	_ramp_t += dt
	_apply_ramp()


func _apply_ramp() -> void:
	var i: int = mini(int(_ramp_t / maxf(_ramp_step, 0.001)), _ramp.size() - 1)
	var f: float = _ramp[i]
	if f >= 1.0 and i == _ramp.size() - 1:
		TimeScale.clear(SLOW_OWNER)
		_ramp = PackedFloat32Array()
		return
	TimeScale.set_factor(SLOW_OWNER, f)
