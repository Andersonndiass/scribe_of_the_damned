class_name GraceFlow
extends Node
## Fluxo da Graça (016 FR-1601..FR-1610; mechanics-agent): soma a Graça das mortes e das palavras,
## e a cada nível pausa o jogo, oferece 3 selos e aplica a bênção escolhida. FSM:
## IDLE → ARMED (espera o próximo quadro sem pausa alheia nem menu da letra) → BEAM (018 D-095:
## feixe dourado + câmera lenta por 2,5 s, com barra) → ANNOUNCING (pausa; selos entrando)
## → CHOOSING (trava de pick_guard) → STAMPING (carimbo) → CHOOSING (fila) ou IDLE (despausa).
## DEAD (morte) e SEALED (fim do capítulo) descartam a fila. Tempo sempre no relógio real: o
## hit-stop (Engine.time_scale 0) não pode travar a pausa. Fora do jogo de verdade (testes, sonda,
## stress) escolhe sozinho, sem pausar (`auto_pick`).

signal phase_changed(phase: Phase)

enum Phase { IDLE, ARMED, BEAM, ANNOUNCING, CHOOSING, STAMPING, DEAD, SEALED }

const SLOW_OWNER := &"levelup_slow"

var tuning: GraceTuning
var player: Player
var letter_field: LetterField
## Escolhe o 1º selo na hora, sem pausar (testes, sonda, stress).
var auto_pick: bool = false
## Desligado, não soma Graça (testes antigos não podem ganhar bênçãos por acaso).
var active: bool = true
## 018: feixe + câmera lenta antes dos selos (testes antigos desligam para não esperar 2,5 s).
var beam_enabled: bool = true
## Tempo do feixe já corrido (s, relógio que desconta a câmera lenta e o hit-stop).
var beam_t: float = 0.0

var phase: Phase = Phase.IDLE
## Os selos da oferta atual.
var offer: Array[BlessingData] = []
## Estes sinais já saíram da árvore pausada (a Pausa por cima fica sabendo).
var seals_open: bool = false

var _phase_ms: int = 0
var _guard_ms: int = 0
var _pause_menu_open: bool = false
var _boss_fight: bool = false
var _echo_pending: bool = false
var _last_word_grace: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tuning == null:
		tuning = GameState.grace_tuning
	EventBus.enemy_killed.connect(func(_s: int, d: EnemyData, p: Vector2) -> void: _gain(d.grace, &"kill", p))
	EventBus.champion_killed.connect(func(d: EnemyData, p: Vector2) -> void:
		_gain(roundi(d.grace * (tuning.champion_mul - 1.0)), &"champion", p))
	EventBus.verbum_echoed.connect(_on_verbum_echoed)
	EventBus.word_cast.connect(_on_word_cast)
	# D-099: a guardada gasta num combo não passa por word_cast: as letras dela contam aqui.
	EventBus.stored_word_released.connect(func(w: WordData, cause: StringName) -> void:
		if cause == &"combo":
			_gain(roundi(tuning.per_letter * w.latin.length()), &"word", _player_pos()))
	EventBus.combo_cast.connect(func(_c: ComboData, _p: float) -> void:
		_gain(roundi(_last_word_grace * tuning.combo_bonus), &"combo", _player_pos()))
	EventBus.boss_spawned.connect(func(_b: BossData) -> void: _boss_fight = true)
	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_defeated.connect(func(_b: BossData) -> void: _seal())
	EventBus.chapter_completed.connect(func(_c: int) -> void: _seal())
	EventBus.pause_menu_toggled.connect(_on_pause_menu_toggled)
	# O feixe fica atrás do escriba e dos inimigos (camada de efeitos do Main, se houver).
	var view := LevelUpBeamView.new()
	view.name = "LevelUpBeam"
	view.flow = self
	var host: Node = get_parent().get_node_or_null(^"FxLayer") if get_parent() != null else null
	if host != null:
		host.add_child.call_deferred(view)
	else:
		add_child(view)
	_emit_changed()


func ledger() -> GraceLedger:
	return GameState.grace


# --- Ganho ---------------------------------------------------------------------------------

func _on_word_cast(word: WordData, _power: float, origin: Vector2, _dir: Vector2) -> void:
	if _echo_pending:
		# O eco do VERBUM já contou as letras de VERBUM (rules-agent).
		_echo_pending = false
		return
	_last_word_grace = roundi(tuning.per_letter * word.latin.length())
	_gain(_last_word_grace, &"word", origin)


func _on_verbum_echoed(_word: WordData) -> void:
	_echo_pending = true
	_last_word_grace = roundi(tuning.per_letter * tuning.echo_word.latin.length())
	_gain(_last_word_grace, &"word", _player_pos())


func _gain(amount: int, source: StringName, pos: Vector2) -> void:
	if not active or amount <= 0 or ledger() == null or phase == Phase.DEAD or phase == Phase.SEALED:
		return
	if _boss_fight:
		amount = roundi(amount * tuning.boss_grace_mul)
	var ups: int = ledger().add(amount)
	EventBus.grace_gained.emit(amount, source, pos)
	_emit_changed()
	if ups > 0:
		EventBus.grace_leveled.emit(ledger().level, ledger().pending)
		if phase == Phase.IDLE:
			_enter(Phase.ARMED)


func _emit_changed() -> void:
	if ledger() != null:
		EventBus.grace_changed.emit(ledger().progress, ledger().needed(), ledger().level)


# --- FSM -----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	match phase:
		Phase.ARMED:
			if not _can_open():
				return
			if auto_pick:
				_auto_pick_all()
				return
			if beam_enabled and tuning.levelup_slow_time > 0.0:
				_start_beam()
			else:
				_open_seals()
		Phase.BEAM:
			_tick_beam(delta)
		Phase.ANNOUNCING:
			if _elapsed() >= tuning.announce_time:
				_guard_ms = Time.get_ticks_msec()
				_enter(Phase.CHOOSING)
		Phase.STAMPING:
			if _elapsed() >= tuning.stamp_time:
				if ledger().pending > 0:
					_new_offer()
				else:
					_close(true)


## Abre por cima de nada: sem outra pausa (Pausa, loja, cutscene), com o escriba vivo e sem o
## menu da letra aberto ou no intervalo entre menus (animation-agent T1802).
func _can_open() -> bool:
	if get_tree().paused or player == null or not player.vitals.is_alive():
		return false
	return letter_field == null or letter_field.menu == null or letter_field.menu.phase == LetterMenu.Phase.IDLE


func _open_seals() -> void:
	get_tree().paused = true
	_new_offer()


# --- Feixe (018, D-095) ----------------------------------------------------------------------

func _start_beam() -> void:
	beam_t = 0.0
	GameState.levelup_beam = true
	_enter(Phase.BEAM)
	_apply_beam_slow()
	EventBus.levelup_beam_started.emit(tuning.levelup_slow_time)


## O relógio desconta a câmera lenta e para no hit-stop e na Pausa (Esc).
func _tick_beam(delta: float) -> void:
	if get_tree().paused:
		return
	var product: float = TimeScale.factor_product()
	if product > 0.001:
		beam_t += delta / product
	_apply_beam_slow()
	if beam_t >= tuning.levelup_slow_time:
		_end_beam()
		_open_seals()


func _apply_beam_slow() -> void:
	var steps: PackedFloat32Array = tuning.levelup_slow_in_steps
	if steps.is_empty():
		return
	var i: int = mini(int(beam_t / maxf(tuning.levelup_slow_in_step_time, 0.001)), steps.size() - 1)
	TimeScale.set_factor(SLOW_OWNER, steps[i])


## Sem rampa de saída: o jogo pausa para os selos logo em seguida (animation-agent).
func _end_beam() -> void:
	TimeScale.clear(SLOW_OWNER)
	if GameState.levelup_beam:
		GameState.levelup_beam = false
		EventBus.levelup_beam_ended.emit()


func _new_offer() -> void:
	offer = _draw_seals()
	seals_open = true
	_enter(Phase.ANNOUNCING)
	EventBus.seals_shown.emit(offer, ledger().level)


## Escolhe o selo `i`. Falso se ainda não pode (trava, Pausa aberta, fora da escolha).
func pick(i: int) -> bool:
	if phase != Phase.CHOOSING or _pause_menu_open or i < 0 or i >= offer.size():
		return false
	if Time.get_ticks_msec() - _guard_ms < int(tuning.pick_guard * 1000.0):
		return false
	_apply(offer[i])
	_enter(Phase.STAMPING)
	return true


func can_pick() -> bool:
	return phase == Phase.CHOOSING and not _pause_menu_open \
		and Time.get_ticks_msec() - _guard_ms >= int(tuning.pick_guard * 1000.0)


func _apply(b: BlessingData) -> void:
	ledger().consume()
	if b == tuning.fallback and player != null and player.vitals.candles >= player.vitals.max_candles:
		GameState.add_gold(tuning.fallback_ink)
		GameState.run_stats.apply(b)
	else:
		RunUpgrade.apply(b, player, letter_field)
	EventBus.blessing_chosen.emit(b, ledger().level)


func _auto_pick_all() -> void:
	while ledger().pending > 0:
		# Simula o jogador que sobe a arma: o selo de arma primeiro (a garantia o põe por último).
		var o: Array[BlessingData] = _draw_seals()
		var pick: BlessingData = o[0]
		var best: int = 1 << 30
		for b: BlessingData in o:
			if b.kind != &"weapon_level" or GameState.loadout == null:
				continue
			var w: WeaponData = GameState.loadout.weapon(b.slot)
			var score: int = (0 if b.slot == GameState.loadout.active else 100) + w.upgrades.find(w.upgrade(b.target))
			if score < best:
				best = score
				pick = b
		_apply(pick)
	_enter(Phase.IDLE)


## 017 (T1729): selos de arma, status e ímã reverso.
func _draw_seals() -> Array[BlessingData]:
	return SealPool.draw(tuning, GameState.run_stats, GameState.loadout, GameState.grace_rng)


func _close(unpause: bool) -> void:
	offer.clear()
	if seals_open:
		seals_open = false
		EventBus.seals_hidden.emit()
	if unpause:
		get_tree().paused = false
		if player != null:
			player.vitals.grant_iframes_for(tuning.post_pick_iframes)
	_enter(Phase.IDLE)


func _on_player_died() -> void:
	_end_beam()
	if ledger() != null:
		ledger().clear_pending()
	var was_open: bool = seals_open
	offer.clear()
	if was_open:
		seals_open = false
		EventBus.seals_hidden.emit()  # o Game Over cuida da pausa
	_enter(Phase.DEAD)


## Fim do capítulo: não há selo depois da morte do chefe.
func _seal() -> void:
	if ledger() != null:
		ledger().clear_pending()
	if phase == Phase.DEAD or phase == Phase.SEALED:
		return
	_end_beam()
	if seals_open:
		_close(true)
	_enter(Phase.SEALED)


func _on_pause_menu_toggled(open: bool) -> void:
	_pause_menu_open = open
	if not open:
		_guard_ms = Time.get_ticks_msec()  # a trava recomeça ao voltar da Pausa


func _enter(p: Phase) -> void:
	phase = p
	_phase_ms = Time.get_ticks_msec()
	phase_changed.emit(p)


func _elapsed() -> float:
	return float(Time.get_ticks_msec() - _phase_ms) / 1000.0


func _player_pos() -> Vector2:
	return player.global_position if player != null else Vector2.ZERO
