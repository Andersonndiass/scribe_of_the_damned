extends SceneTree
## Sonda de balanceamento (ferramenta de desenvolvimento, não entra no build).
## Roda a cena principal com um bot que foge do inimigo mais próximo e mede a onda 1.
## Uso: godot --headless --path . -s tools/balance_probe.gd -- [still]
##   still = o bot fica parado (pior caso). move = foge. cast = foge, busca letras e conjura.
##   god = jogador invencível (2B, D-047): mede o FLUXO DE LETRAS da onda inteira, sem depender de o
##         bot sobreviver. Imprime uma linha FLOW com letras/min, letras-alvo/min, comidas, coletadas,
##         palavras e heresias.

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


func _initialize() -> void:
	_still = OS.get_cmdline_user_args().has("still")
	_cast_mode = OS.get_cmdline_user_args().has("cast")
	_god = OS.get_cmdline_user_args().has("god")
	# Overrides só em memória, para simular propostas sem tocar nos .tres: hp=N drop=F
	var imp: Resource = load("res://data/enemies/imp.tres")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("hp="):
			imp.set("max_hp", int(arg.substr(3)))
		elif arg == "smart_magnet":
			(load("res://data/tuning/drop_tuning.tres") as Resource).set("selective_magnet", true)
		elif arg.begins_with("drop="):
			imp.set("letter_drop_chance", float(arg.substr(5)))
	_main = (load(MAIN) as PackedScene).instantiate()
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
	bus.wave_ended.connect(func(_i: int) -> void: _ended = true)
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
			_caster.call("cast")
		elif st in [1, 4]:  # FILL / FULL_REJECT: beco sem saída → purge
			_caster.call("purge")
	if _ended or _died_at >= 0.0 or _time > _limit:
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
