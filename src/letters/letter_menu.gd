class_name LetterMenu
extends Node
## Menu de escolha da letra (017 T1719; mechanics-agent T1700; D-087). Substitui as letras no chão:
## cada letra que um inimigo soltaria vira um pedido na fila; o menu abre com 3 opções (1 continua
## a palavra), o jogo entra em câmera lenta e o escriba fica parado; setas + Espaço ou clique
## escolhem; se o tempo acabar, a letra se perde.
## FSM: IDLE → OPEN → (escolha | tempo) → GAP → IDLE. O relógio desconta a câmera lenta e o
## hit-stop (tempo de jogo a ×1).
## D-098 (`tuning.pause_game`): aberto, o menu pausa a árvore e conta o tempo em tempo real (o nó
## roda sempre). Pausa de outro dono (Esc, selos, loja) congela o menu e impede de abrir; só
## despausa o que ele mesmo pausou.

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

## Este menu veio da Tinta Iluminada (018): cantoneiras nas 3 cartas.
var illuminated: bool = false
## Pedidos esperando: {"forced": String, "rare_first": bool}.
var _queue: Array[Dictionary] = []
var _gap: float = 0.0
var _ramp := PackedFloat32Array()
var _ramp_step: float = 0.0
var _ramp_t: float = 0.0
## A pausa da árvore é deste menu (D-098)?
var _paused_by_me: bool = false
## O menu de pausa (Esc) está aberto por cima.
var _pause_menu: bool = false


func _ready() -> void:
	if tuning.pause_game:
		process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.wave_ended.connect(func(_i: int) -> void: cancel())
	EventBus.player_died.connect(cancel)
	EventBus.pause_menu_toggled.connect(func(open: bool) -> void:
		_pause_menu = open
		if not open and _paused_by_me and phase == Phase.OPEN and is_inside_tree():
			get_tree().paused = true)  # o Esc despausou por cima do menu: volta a pausar


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
	_release_pause()


func _process(delta: float) -> void:
	if tuning.pause_game and is_inside_tree() and get_tree().paused and (not _paused_by_me or _pause_menu):
		return  # pausa de outro dono: nada anda, nada abre
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
				if not tuning.pause_game and (_queue.is_empty() or not _can_open()):
					_start_ramp(tuning.slow_out_steps, tuning.slow_out_step_time)
	if phase == Phase.IDLE and not _queue.is_empty() and _can_open():
		_open()


func _can_open() -> bool:
	if field == null or (player != null and not player.vitals.is_alive()) or GameState.levelup_beam:
		return false  # 018: durante o feixe do nível o pedido espera na fila
	var st: Atril.Status = field.atril.state(field.lexicon)
	return not field.atril.is_full() and st != Atril.Status.VALID


## Iluminura (018 T1812): pode abrir um menu agora? (fechado, sem fila e sem o intervalo)
func can_open_now() -> bool:
	return phase == Phase.IDLE and _queue.is_empty() and _can_open()


## Abre na hora, pulando a fila, com `useful_count` letras que continuam a palavra.
## Falso se não pôde (a poção não é gasta).
func open_now(useful_count: int) -> bool:
	if not can_open_now():
		return false
	_queue.push_front({"forced": "", "rare_first": false, "useful": useful_count, "illuminated": true})
	_open()
	return phase == Phase.OPEN


func _open() -> void:
	var req: Dictionary = _queue.pop_front()
	illuminated = req.get("illuminated", false)
	options = LetterOfferRoll.roll(field.atril, field.lexicon, field.tuning, tuning, GameState.rng,
		GameState.unlocked_words, req["forced"], req["rare_first"], req.get("useful", 1))
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
	if tuning.pause_game:
		if is_inside_tree() and not get_tree().paused:
			get_tree().paused = true
			_paused_by_me = true
	elif not TimeScale.has_factor(SLOW_OWNER) or _ramp.size() > 0 and _ramp[_ramp.size() - 1] >= 1.0:
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
		var before: int = focus
		focus = clampi(focus + step, 0, options.size() - 1)
		if focus != before:
			EventBus.letter_menu_cursor_moved.emit(focus)


func _expire() -> void:
	EventBus.letter_lost.emit()
	_close()


func _close() -> void:
	options.clear()
	phase = Phase.GAP
	_gap = tuning.reopen_gap
	GameState.letter_menu_open = false
	_release_pause()
	EventBus.letter_menu_closed.emit()


func _release_pause() -> void:
	if _paused_by_me and is_inside_tree():
		get_tree().paused = false
	_paused_by_me = false


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
