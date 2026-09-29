class_name LetterField
extends Node2D
## Letras no chão e o atril do jogador (FR-011..FR-016). Um único loop cuida de vida, ímã,
## coleta e recusa. Dono do Lexicon, do Atril e do LetterDropper.
## As letras (pool &"letter") ficam como filhas deste nó.

## Distância (px) do corpo do jogador em que a letra é coletada.
const PICKUP_RADIUS := 6.0
## Tinteiro Duplo: a letra extra cai ao lado da primeira (visual).
const DOUBLE_LETTER_OFFSET := Vector2(8, 0)
## Rasura (006): não apaga a letra pega há menos disso (s; o BossData manda o valor da luta).
var erase_grace: float = 0.5
## Letra marcada pelo clique (D-067): com marca, o ímã (mesmo raio) puxa só ela.
var marked: Letter = null
var _last_push_msec: int = -100000
## Aceleração do ímã (px/s²): a letra parte devagar e acelera (QUAD_IN, ficha 21).
const MAGNET_ACCEL := 900.0
## Depois de recusada (atril cheio), a letra fica parada este tempo antes de tentar de novo.
const REJECT_COOLDOWN := 0.6
## Clique marca a letra mais próxima dentro deste raio (px; tolerância de mira, D-067).
const MARK_PICK_RADIUS := 10.0
const PLAYER_BODY_OFFSET := Vector2(0, -6)

@export var player: Player
@export var lexicon_data: LexiconData
@export var tuning: DropTuning

var lexicon := Lexicon.new()
var atril: Atril
var dropper := LetterDropper.new()

var _active: Array[Letter] = []


func _ready() -> void:
	add_to_group(&"letter_field")
	if not lexicon.load_data(lexicon_data):
		push_error("LetterField: dicionário inválido — %s" % lexicon.error)
	lexicon.set_known_filter(GameState.is_word_known)
	EventBus.word_unlocked.connect(func(_w: WordData) -> void: emit_atril())
	# O LetterField fica pronto antes do Main chamar GameState.start_run: lê direto do jogador.
	atril = Atril.new(RunStats.of(player.data).int_value(&"atril_capacity") if player != null else GameState.atril_capacity)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.atril_erase_requested.connect(erase_last_letter)
	emit_atril()


func active_count() -> int:
	return _active.size()


## Cria uma letra no chão (pool). lock_time: tempo em que ela não pode ser coletada.
## loose: o ímã ignora a letra (letras do purge, D-031).
func spawn_letter(letter: String, rare: bool, target: bool, pos: Vector2, lock_time: float = 0.0, loose: bool = false) -> Letter:
	# Teto = prewarm do pool (150, SC-001). Acima disso a letra não cai: nunca instancia na onda.
	var l := PoolManager.try_acquire(Letter.POOL_KEY) as Letter
	if l == null:
		return null
	# Letra que cairia numa peça da página vai para fora dela, nunca some (004 FR-411).
	pos = ObstacleQuery.drop_point(pos)
	l.start(letter, rare, target, pos, tuning.letter_lifetime, lock_time, loose)
	_active.append(l)
	EventBus.letter_dropped.emit(letter, rare, target, pos)
	return l


## Letra no chão mais próxima de `pos` (até `radius`) que uma Traça pode comer: não magnetizada
## e não travada por outra Traça. null se não houver (005 FR-504).
func nearest_edible(pos: Vector2, radius: float) -> Letter:
	var best: Letter = null
	var best_d: float = radius * radius
	for l: Letter in _active:
		if l.magnetized:
			continue
		var d: float = l.global_position.distance_squared_to(pos)
		if d <= best_d:
			best_d = d
			best = l
	return best


## Come a letra mais próxima de `pos` (até `radius`). Devolve a letra comida ou "".
func eat_letter_near(pos: Vector2, radius: float) -> String:
	for idx: int in range(_active.size() - 1, -1, -1):
		var l: Letter = _active[idx]
		if not l.magnetized and l.global_position.distance_to(pos) <= radius:
			var letter: String = l.letter
			var where: Vector2 = l.global_position
			_release(idx)
			EventBus.letter_eaten.emit(letter, where)
			return letter
	return ""


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


## Letras no chão que estão em alguma palavra conhecida (LetterSafety, 006 FR-605).
func count_useful_on_ground() -> int:
	var useful := {}
	for w: WordData in lexicon_data.words:
		if lexicon.is_known(w):
			for ch: String in w.latin:
				useful[ch] = true
	var n: int = 0
	for l: Letter in _active:
		if useful.has(l.letter):
			n += 1
	return n


## Solta uma letra do drop ponderado (FR-013) em `pos` (LetterSafety).
func drop_safety_letter(pos: Vector2) -> void:
	var r: Dictionary = dropper.roll(atril, lexicon, tuning, GameState.rng, GameState.unlocked_words)
	spawn_letter(r["letter"], r["rare"], r["target"], pos)


## Publica o estado do atril e as dicas (FR-023) no EventBus.
func emit_atril() -> void:
	var status: Atril.Status = atril.state(lexicon)
	var hints := PackedStringArray()
	if status == Atril.Status.EMPTY or status == Atril.Status.PARTIAL or status == Atril.Status.VALID:
		for w: WordData in lexicon.words_with_prefix(atril.text(), atril.capacity, tuning.hint_count):
			hints.append(w.latin)
	GameState.atril_capacity = atril.capacity
	EventBus.atril_changed.emit(atril.letters(), status, hints, atril.rare_mask())


func _on_enemy_killed(slot: int, data: EnemyData, pos: Vector2) -> void:
	# REQUIEM marca o slot antes da morte (o sinal sai antes do swap-remove).
	var em := EnemyQuery.provider as EnemyManager
	var guaranteed: bool = em != null and slot < em.count and em.guaranteed_drop[slot] == 1
	if not guaranteed and GameState.rng.randf() >= data.letter_drop_chance:
		return
	var target_mul: float = player.buffs.target_weight_mul() if player != null else 1.0
	var stats: RunStats = RunStats.of(player.data) if player != null else null
	var target_add: float = stats.value(&"target_bonus_add") if stats != null else 0.0
	var r: Dictionary = dropper.roll(atril, lexicon, tuning, GameState.rng, GameState.unlocked_words, target_mul, target_add)
	spawn_letter(r["letter"], r["rare"], r["target"], pos)
	# Tinteiro Duplo (003 FR-310b, D-058): uma letra extra, sorteio independente, ao lado.
	var double_chance: float = stats.value(&"double_letter_chance") if stats != null else 0.0
	if double_chance > 0.0 and GameState.rng.randf() < double_chance:
		var r2: Dictionary = dropper.roll(atril, lexicon, tuning, GameState.rng, GameState.unlocked_words, target_mul, target_add)
		spawn_letter(r2["letter"], r2["rare"], r2["target"], pos + DOUBLE_LETTER_OFFSET)


## Clique do mouse (D-067): marca a letra mais próxima do ponto; clicar na marcada ou no chão
## vazio desmarca. Retorna a letra marcada (ou null).
func mark_at(pos: Vector2) -> Letter:
	var best: Letter = null
	var best_d: float = MARK_PICK_RADIUS
	for l: Letter in _active:
		var d: float = l.global_position.distance_to(pos)
		if d <= best_d:
			best_d = d
			best = l
	if best == marked:
		best = null
	if marked != null:
		marked.marked = false
	marked = best
	if marked != null:
		marked.marked = true
		# As outras param e ficam de lado até sair do raio do ímã: só a marcada vem, e as
		# indesejadas não vêm logo depois que ela é coletada.
		for l: Letter in _active:
			if l != marked:
				l.magnetized = false
				l.magnet_speed = 0.0
				l.magnet_skip = true
	return marked


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		mark_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _active.is_empty():
		return
	var t0: int = Prof.start()
	var can_collect: bool = player != null and player.vitals.is_alive()
	var body: Vector2 = player.global_position + PLAYER_BODY_OFFSET if player != null else Vector2.INF
	var magnet_r: float = RunStats.of(player.data).value(&"magnet_radius") * player.buffs.magnet_mul() if player != null else 0.0
	for idx: int in range(_active.size() - 1, -1, -1):
		var l: Letter = _active[idx]
		l.life -= delta
		if l.life <= 0.0:
			_release(idx)
			continue
		l.lock_left -= delta
		l.reject_cooldown -= delta
		if can_collect and l.lock_left <= 0.0 and l.reject_cooldown <= 0.0:
			var dist: float = l.global_position.distance_to(body)
			if dist <= PICKUP_RADIUS:
				if collect(l.letter, l.rare):
					_release(idx)
					continue
				l.reject_cooldown = REJECT_COOLDOWN
				l.magnetized = false
				l.magnet_speed = 0.0
			elif l.magnet_skip and dist > magnet_r:
				l.magnet_skip = false
			elif not l.loose and not l.magnet_skip and (l.magnetized or dist <= magnet_r) and _magnet_accepts(l) \
					and (marked == null or l == marked):
				l.magnetized = true
				l.magnet_speed += MAGNET_ACCEL * delta
				l.global_position = l.global_position.move_toward(body, l.magnet_speed * delta)
		l.update_view(delta, tuning.blink_time)
	Prof.stop(&"letras", t0)


func _magnet_accepts(l: Letter) -> bool:
	if not tuning.selective_magnet or l.magnetized:
		return true
	return lexicon.is_prefix(atril.text() + l.letter, atril.capacity)


func _release(idx: int) -> void:
	var l: Letter = _active[idx]
	if l == marked:
		l.marked = false
		marked = null
	_active[idx] = _active[_active.size() - 1]
	_active.pop_back()
	PoolManager.release(l)
