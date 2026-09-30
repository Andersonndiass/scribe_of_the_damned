extends SceneTree
## Sonda de balanceamento (ferramenta de desenvolvimento, não entra no build).
## Roda a cena principal com um bot que foge do inimigo mais próximo e mede a onda 1.
## Uso: godot --headless --path . -s tools/balance_probe.gd -- [still]
##   still = o bot fica parado (pior caso). move = foge. cast = foge, busca letras e conjura.
##   god = jogador invencível (2B, D-047): mede o FLUXO DE LETRAS da onda inteira, sem depender de o
##         bot sobreviver. Imprime uma linha FLOW com letras/min, letras-alvo/min, comidas, coletadas,
##         palavras e heresias.
##   chapter = joga as 9 ondas seguidas, com a loja no meio (fecha sozinha), até o fim do capítulo.
##   boss = luta direto contra o chefe do capítulo (o Main lê o mesmo argumento); com god mede o
##          tempo até matar (006 T621, SC-608). Linha BOSS. Combina com unlock=all e atril=N.
##   obstacles=off = sem as peças da página (004 T413, comparação A/B). stage=N = página no estágio N
##         desde o começo. Imprime uma linha ARENA com STUCK: % das amostras (a cada 0,5 s) em que um
##         inimigo que anda QUER andar (velocidade ≥ 30% da dele), está encostado numa peça e não saiu
##         do lugar (≤ 2 px). Monge parado atirando e Gárgula preparando o dash não contam.
##   smart_magnet target=F life=F magnet=F dropall=F = números de letras em memória (D-082).
##   buy = em cada loja o bot compra as cartas mais baratas que couberem na tinta (003 T320, SC-306).
##         Imprime uma linha SHOP com compras, tinta ganha e o que comprou.

const MAIN := "res://src/main/main.tscn"
const TIME_SCALE := 4.0

var _kills: int = 0
var _hits: int = 0
var _died_at: float = -1.0
var _ended: bool = false
var _time: float = 0.0
var _still: bool = false
var _cast_mode: bool = false
var _field: Node
var _caster: Node
var _casts: Dictionary = {}
var _dropped: int = 0
var _collected: String = ""
var _main: Node
var _player: Node2D
var _manager: Node  # sem tipo: EnemyManager depende de autoloads
var _max_alive: int = 0
var _limit: float = 65.0
var _wave_slot: int = -1
var _shots: int = 0
var _god: bool = false
var _targets: int = 0
var _eaten: int = 0
var _heresies: int = 0
var _purges: int = 0
var _chapter: bool = false
var _chapter_done: bool = false
var _shop_bot: bool = false
var _bought: PackedStringArray = []
var _ink_earned: int = 0
var _visits: int = 0
var _boss_mode: bool = false
var _boss_done: float = -1.0
var _boss_hp: int = -1
var _boss_phase: int = 0
var _obstacles: bool = true
var _stage: int = -1
var _stuck: int = 0
var _stuck_max: int = 0
var _samples: int = 0
var _sample_in: float = 0.0
var _last_pos := PackedVector2Array()
const STUCK_EVERY := 0.5
const STUCK_MOVE := 2.0
const STUCK_TOUCH := 1.5
const STUCK_INTENT := 0.3
## Raios do inimigo em volta do escriba que contam como "chegou".
const STUCK_NEAR_PLAYER := 5.0


func _initialize() -> void:
	_still = OS.get_cmdline_user_args().has("still")
	_cast_mode = OS.get_cmdline_user_args().has("cast")
	_god = OS.get_cmdline_user_args().has("god")
	_chapter = OS.get_cmdline_user_args().has("chapter")
	_shop_bot = OS.get_cmdline_user_args().has("buy")
	_boss_mode = OS.get_cmdline_user_args().has("boss")
	# Overrides só em memória, para simular propostas sem tocar nos .tres: hp=N drop=F
	var imp: Resource = load("res://data/enemies/imp.tres")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("hp="):
			imp.set("max_hp", int(arg.substr(3)))
		elif arg == "smart_magnet":
			(load("res://data/tuning/drop_tuning.tres") as Resource).set("selective_magnet", true)
		elif arg.begins_with("drop="):
			imp.set("letter_drop_chance", float(arg.substr(5)))
		# D-082 (ritmo das palavras): target=F bônus da letra-alvo · life=F segundos da letra no
		# chão · magnet=F raio do ímã · dropall=F multiplica o drop de letra de todos os inimigos.
		elif arg.begins_with("target="):
			(load("res://data/tuning/drop_tuning.tres") as Resource).set("target_bonus", float(arg.substr(7)))
		elif arg.begins_with("life="):
			(load("res://data/tuning/drop_tuning.tres") as Resource).set("letter_lifetime", float(arg.substr(5)))
		elif arg.begins_with("magnet="):
			(load("res://data/player/anselmo.tres") as Resource).set("magnet_radius", float(arg.substr(7)))
		elif arg.begins_with("dropall="):
			for f: String in DirAccess.get_files_at("res://data/enemies/"):
				if f.ends_with(".tres"):
					var e: Resource = load("res://data/enemies/" + f)
					e.set("letter_drop_chance", minf(1.0, float(e.get("letter_drop_chance")) * float(arg.substr(8))))
		elif arg == "obstacles=off":
			_obstacles = false
		elif arg.begins_with("stage="):
			_stage = int(arg.substr(6))
	_main = (load(MAIN) as PackedScene).instantiate()
	if not _obstacles:
		# Só em memória: o capítulo fica sem a página de obstáculos (004 T413).
		(_main.get("chapter") as Resource).set("arena", null)
	_main.set("shop_auto_close", true)  # sem tela: a loja abre e fecha sozinha (003)
	root.add_child(_main)
	_player = _main.get_node("World/Player")
	_manager = _main.get_node("World/EnemyManager")
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	# wave=N: joga só a onda N do capítulo (T533).
	_limit = 65.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("wave="):
			_wave_slot = int(arg.substr(5)) - 1
	var bus: Node = root.get_node("EventBus")
	bus.enemy_killed.connect(func(_s: int, _d: Resource, _p: Vector2) -> void: _kills += 1)
	bus.player_damaged.connect(func(_a: int, _c: int) -> void: _hits += 1)
	bus.player_died.connect(func() -> void: _died_at = _time)
	bus.wave_ended.connect(func(_i: int) -> void: _ended = not _chapter)
	bus.chapter_completed.connect(func(_c: int) -> void: _chapter_done = true)
	bus.gold_ink_collected.connect(func(a: int, _t: int) -> void: _ink_earned += a)
	bus.shop_opened.connect(func(_w: int) -> void: _on_shop_opened())
	bus.boss_damaged.connect(func(hp: int, _m: int) -> void: _boss_hp = hp)
	bus.boss_phase_changed.connect(func(i: int) -> void:
		_boss_phase = i
		print("BOSS fase %d aos %.2f min" % [i + 1, _time / 60.0]))
	bus.boss_defeated.connect(func(_b: Resource) -> void: _boss_done = _time)
	if _boss_mode:
		_limit = 12.0 * 60.0
	if _chapter:
		_limit = 20.0 * 60.0
		bus.wave_started.connect(func(i: int, _d: float) -> void:
			print("CHAPTER onda %d começou (t=%.1fmin, tinta=%d)" % [i, _time / 60.0, int(root.get_node("GameState").get("gold_ink"))]))
	bus.letter_dropped.connect(func(_l: String, _r: bool, t: bool, _p: Vector2) -> void:
		_dropped += 1
		if t:
			_targets += 1)
	bus.letter_eaten.connect(func(_l: String, _p: Vector2) -> void: _eaten += 1)
	bus.heresy_committed.connect(func(_p: Vector2) -> void: _heresies += 1)
	bus.atril_purged.connect(func(_l: PackedStringArray, _p: Vector2) -> void: _purges += 1)
	bus.letter_collected.connect(func(l: String, _r: bool) -> void: _collected += l)
	bus.word_cast.connect(func(w: Resource, _pw: float, _o: Vector2, _d: Vector2) -> void: _casts[w.get("latin")] = _casts.get(w.get("latin"), 0) + 1)
	_player.get_node("AutoAttack").fired.connect(func(_t: Vector2) -> void: _shots += 1)
	Engine.time_scale = TIME_SCALE
	Engine.physics_ticks_per_second = 60


func _physics_process(delta: float) -> bool:
	if _stage >= 0:
		root.get_node("EventBus").emit_signal(&"page_stage_changed", _stage, _stage, false)
		_stage = -1
	_sample_stuck(delta)
	if _wave_slot >= 0:
		# Aplicado no 1º frame: no _initialize o Main ainda não rodou o _ready.
		_manager.call("dissolve_all")
		_main.call("start_wave", _wave_slot)
		var chapter: Resource = _main.get("chapter")
		_limit = float((chapter.get("waves") as Array)[_wave_slot].get("duration")) + 2.0
		_wave_slot = -1
		_time = 0.0
		return false
	_time += delta
	if _god:
		(_player.get("vitals") as RefCounted).set("iframes_left", 1.0e6)
	_max_alive = maxi(_max_alive, _manager.get("count"))
	if not _still:
		_steer()
	if _cast_mode:
		# Só conjura com a palavra VÁLIDA: apertar Espaço antes disso é heresia (FR-019).
		# (Até 2026-09-26 o bot conjurava todo frame e cometia heresia sem parar: medições de
		# palavras por onda feitas antes disso estão contaminadas.)
		var atril: RefCounted = _field.get("atril")
		var st: int = atril.call("state", _field.get("lexicon"))
		if st == 3:  # Atril.Status.VALID
			var boss: Node2D = _main.get_node_or_null("World/Boss")
			if boss != null and bool(boss.get("fighting")):
				# Palavras direcionais (LUX, FLAMMA…) saem para onde o escriba olha: mira o chefe.
				_player.set("facing", (boss.global_position - _player.global_position).normalized())
			_caster.call("cast")
		elif st in [1, 4]:  # FILL / FULL_REJECT: beco sem saída → purge
			_caster.call("purge")
	if _boss_mode and int(_time) % 30 == 0 and int(_time - delta) % 30 != 0:
		var b: Node = _main.get_node_or_null("World/Boss")
		print("BOSS t=%.0fs hp=%d estado=%s pausado=%s palavras=%s" % [_time, _boss_hp, b.call("state_name") if b != null else "-", paused, _casts])
	if _boss_mode and (_boss_done >= 0.0 or _died_at >= 0.0 or _time > _limit):
		print("BOSS resultado venceu=%s tempo=%.2fmin hp_restante=%d fase=%d conjurações=%s" % [
			_boss_done >= 0.0, (_boss_done if _boss_done >= 0.0 else _time) / 60.0, _boss_hp, _boss_phase + 1, _casts])
		return true
	if _boss_mode and (_boss_done >= 0.0 or _died_at >= 0.0 or _time > _limit):
		_print_arena()
	if _ended or _chapter_done or _died_at >= 0.0 or _time > _limit:
		_print_arena()
		if _chapter:
			print("SHOP visitas=%d compras=%d tinta_ganha=%d tinta_sobrando=%d capítulo_completo=%s tempo=%.1fmin compradas=%s" % [
				_visits, _bought.size(), _ink_earned, int(root.get_node("GameState").get("gold_ink")), _chapter_done,
				_time / 60.0, ", ".join(_bought)])
		print("PROBE onda=%d still=%s tempo=%.1fs mortes=%d golpes_sofridos=%d morreu_em=%s max_vivos=%d onda_terminou=%s tiros=%d conjurações=%s letras_caídas=%d coletadas=%s" % [
			GameState_wave(), _still, _time, _kills, _hits, ("%.1fs" % _died_at) if _died_at >= 0.0 else "não", _max_alive, _ended, _shots, _casts, _dropped, _collected])
		if _god:
			var minutes: float = maxf(_time / 60.0, 0.001)
			var words: int = 0
			for k: String in _casts:
				words += int(_casts[k])
			print("FLOW onda=%d min=%.2f letras/min=%.1f alvo/min=%.1f comidas=%d coletadas/min=%.1f palavras=%d palavras/min=%.2f heresias=%d purges=%d mortes/min=%.1f" % [
				GameState_wave(), minutes, _dropped / minutes, _targets / minutes, _eaten,
				_collected.length() / minutes, words, words / minutes, _heresies, _purges, _kills / minutes])
		return true
	return false


## Loja (003 T320): compra, a cada visita, as cartas mais baratas que couberem na tinta.
func _on_shop_opened() -> void:
	_visits += 1
	if not _shop_bot:
		return
	var shop: Node = _main.get_node("Shop")
	var offer: RefCounted = shop.get("offer")
	while true:
		var best: int = -1
		var prices: PackedInt32Array = offer.get("prices")
		var cards: Array = offer.get("cards")
		for i: int in cards.size():
			if bool(shop.call("can_afford", i)) and (best < 0 or prices[i] < prices[best]):
				best = i
		if best < 0 or not bool(shop.call("buy", best)):
			return
		_bought.append(String((cards[best] as Resource).get("id")))


func GameState_wave() -> int:
	return int(root.get_node("GameState").get("wave_index"))


func _steer() -> void:
	for a: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(a)
	var p: Vector2 = _player.global_position
	var flee := Vector2.ZERO
	var positions: PackedVector2Array = _manager.get("positions")
	for i: int in int(_manager.get("count")):
		var away: Vector2 = p - positions[i]
		var d: float = away.length()
		if d < 70.0 and d > 0.01:
			flee += away / d * (70.0 - d)
	if _cast_mode:
		var best_d: float = INF
		var best := Vector2.INF
		var atril_now: RefCounted = _field.get("atril")
		var lex: RefCounted = _field.get("lexicon")
		var prefix: String = atril_now.call("text")
		var cap: int = atril_now.get("capacity")
		for l: Node2D in _field.get("_active"):
			# Jogador competente: só busca letras que continuam uma palavra que cabe no atril.
			if not lex.call("is_prefix", prefix + String(l.get("letter")), cap):
				continue
			var dl: float = l.global_position.distance_to(p)
			if dl < best_d:
				best_d = dl
				best = l.global_position
		if best != Vector2.INF:
			# Invencível: buscar letras é a prioridade (mede o fluxo, não a sobrevivência).
			flee += (best - p).normalized() * (400.0 if _god else 40.0)
	# Evita as bordas puxando para o centro.
	flee += (Vector2(320, 180) - p) * 0.15
	if flee.x < -2.0:
		Input.action_press(&"move_left")
	elif flee.x > 2.0:
		Input.action_press(&"move_right")
	if flee.y < -2.0:
		Input.action_press(&"move_up")
	elif flee.y > 2.0:
		Input.action_press(&"move_down")


## STUCK (004 T413): amostra a cada 0,5 s os inimigos que andam, encostados numa peça e parados.
func _sample_stuck(delta: float) -> void:
	_sample_in -= delta
	if _sample_in > 0.0:
		return
	_sample_in = STUCK_EVERY
	var n: int = int(_manager.get("count"))
	var positions: PackedVector2Array = _manager.get("positions")
	var radius_of: PackedFloat32Array = _manager.get("radius_of")
	var stun_left: PackedFloat32Array = _manager.get("stun_left")
	var velocities: PackedVector2Array = _manager.get("velocities")
	var data_of: Array = _manager.get("data_of")
	var now := 0
	for i: int in n:
		var d: Resource = data_of[i]
		if i >= _last_pos.size() or bool(d.get("flying")) or stun_left[i] > 0.0:
			continue
		if velocities[i].length() < float(d.get("move_speed")) * STUCK_INTENT:
			continue
		# Colado no escriba não é travado: já chegou (amontoado em volta dele perto de uma peça).
		if positions[i].distance_to(_player.global_position) <= radius_of[i] * STUCK_NEAR_PLAYER:
			continue
		_samples += 1
		if ObstacleQuery.map != null and not ObstacleQuery.map.is_free(positions[i], radius_of[i] + STUCK_TOUCH) and positions[i].distance_to(_last_pos[i]) <= STUCK_MOVE:
			now += 1
			if OS.get_cmdline_user_args().has("stuck_log") and _stuck + now < 60:
				print("STUCK_AT %s r=%.1f id=%s v=%s jogador=%s" % [positions[i].round(), radius_of[i], d.get("id"), velocities[i].round(), _player.global_position.round()])
	_stuck += now
	_stuck_max = maxi(_stuck_max, now)
	_last_pos = positions.slice(0, n)


func _print_arena() -> void:
	print("ARENA obstáculos=%s estágio=%d STUCK=%.2f%% (%d de %d amostras, pico %d)" % [
		"on" if _obstacles else "off", int((_main.get_node("Arena") as Node).get("degradation_stage")),
		100.0 * _stuck / maxf(1.0, _samples), _stuck, _samples, _stuck_max])
