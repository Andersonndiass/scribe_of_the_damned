extends Node
## DEBUG (T080, 005 T540): mantém uma carga fixa sobre a cena principal real e mede com o FpsProbe.
##   modo "sc001" (padrão): 300 Diabretes + 200 projéteis do jogador (SC-001; as 150 letras do chão saíram na 017).
##   modo "wave9": o mesmo, mas os 300 inimigos são a MISTURA da onda 9 com os comportamentos
##                 ativos, mais 60 projéteis inimigos e 20 poças mantidos no ar/chão (SC-503).
##   modo "boss": a luta contra o chefe do capítulo com o Summon ativo e 200 projéteis
##                do jogador; o chefe tem vida enorme e o escriba é invulnerável (006 SC-607).
##   modo "sweep": a carga do SC-001 e, a cada SWEEP_CYCLE s, uma varredura de tela (sweep_word:
##                 PURGO, DOMINUS ou MISERERE; vazio = controle, não conjura). Registra os frames nos
##                 SWEEP_WINDOW s seguintes e repõe os inimigos (002 SC-202).
##   modo "bible": a carga do SC-001 e a Bíblia no nível 5 ligada, girando a mira pelo meio da
##                 multidão (017 SC-1703).
##   modo "refuge": a carga do SC-001 com o círculo da Água Benta (raio 48) no meio do caminho dos
##                 inimigos o tempo todo (018 SC-1803).
##   modo "arsenal": a carga do SC-001 com Turíbulo e Rosário no nível 5, trocando a cada
##                 ARSENAL_SWAP s (rastro de incenso no teto + contas; 017 T1739).
##   modo "crucifix": a carga do SC-001 com o Crucifixo no nível 5 (0,5 s; T1820 dobrou a cadência:
##                 ~2,4× mais cruzes com perfuração) e a Pena nível 5 na reserva.
## Inimigos com HP enorme (não morrem) perseguem um alvo que gira no centro; o jogador fica num
## canto, sem ataque automático, invulnerável. Nada de gameplay é alterado nos .tres.

const ENEMIES := 300
const PROJECTILES := 200
const ENEMY_PROJECTILES := 60
const PUDDLES := 20
const STRESS_HP := 1_000_000
const ORBIT_RADIUS := 80.0
const ORBIT_SPEED := 0.8
const PROJECTILE_RANGE := 900.0
const SWEEP_CYCLE := 3.0
const SWEEP_CAST_AT := 1.0
const SWEEP_WINDOW := 0.8
const SWEEP_CYCLES := 8
const SLOW_FRAME_MS := 33.0
## Modo bible: onde fica o escriba e a volta da mira (s).
const BIBLE_PLAYER_AT := Vector2(220, 180)
const BIBLE_AIM_PERIOD := 4.0
const ARSENAL_SWAP := 2.0
var _swap_left: float = 0.0
## Proporção da onda 9 (max_alive de wave_09.tres: 110/16/15/12/12), escalada para 300.
const WAVE9_MIX: Array = [
	["res://data/enemies/imp.tres", 200],
	["res://data/enemies/moth.tres", 30],
	["res://data/enemies/ink_blot.tres", 25],
	["res://data/enemies/gargoyle.tres", 22],
	["res://data/enemies/hollow_monk.tres", 23],
]

var main: Node2D
var mode: StringName = &"sc001"
var _manager: EnemyManager
var _field: LetterField
var _player: Player
var _eproj: EnemyProjectileManager
var _projectiles: PlayerProjectileManager
var _hazards: HazardField
var _puddle: PuddleData
var _shot: EnemyProjectileData
var _target := Node2D.new()
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0
var _ready_to_run: bool = false
var _imp_tough: EnemyData
## Palavra da varredura (id); vazio = controle.
var sweep_word: StringName = &""
var _sweep_t: float = 0.0
var _sweep_cast: bool = false
var _sweep_cycles: int = 0
var _window_ms := PackedFloat32Array()
var _measure_until_us: int = 0
var _last_us: int = 0


func setup(p_main: Node2D, p_mode: StringName = &"sc001") -> void:
	main = p_main
	mode = p_mode
	_rng.seed = 1348
	(main.get_node("WaveDirector") as WaveDirector).stop()
	_manager = main.get_node("World/EnemyManager")
	_field = main.get_node("World/LetterField")
	_player = main.get_node("World/Player")
	_eproj = main.get_node("World/EnemyProjectiles")
	_projectiles = main.get_node("PlayerProjectiles")
	_hazards = main.get_node("HazardField")
	_puddle = load("res://data/hazards/puddle_ink.tres")
	_shot = load("res://data/projectiles/prj_page.tres")
	_player.arsenal.enabled = false
	_player.global_position = Vector2(40, 40)
	if mode == &"arsenal":
		for k: int in 2:
			var w: WeaponData = load("res://data/weapons/%s.tres" % ["censer", "rosary"][k])
			var ws := WeaponSlot.new(w)
			ws.level = w.max_level()
			GameState.loadout.slots[k] = ws
		_player.arsenal.enabled = true
		_player.global_position = BIBLE_PLAYER_AT
	if mode == &"crucifix":
		for k: int in 2:
			var cw: WeaponData = load("res://data/weapons/%s.tres" % ["crucifix", "pen"][k])
			var cs := WeaponSlot.new(cw)
			cs.level = cw.max_level()
			GameState.loadout.slots[k] = cs
		GameState.loadout.set_active(0)
		_player.arsenal.enabled = true
		_player.global_position = BIBLE_PLAYER_AT
	if mode == &"bible":
		var bible: WeaponData = load("res://data/weapons/bible.tres")
		var slot := WeaponSlot.new(bible)
		slot.level = bible.max_level()
		GameState.loadout.slots[0] = slot
		GameState.loadout.set_active(0)
		_player.arsenal.enabled = true
		_player.global_position = BIBLE_PLAYER_AT
	main.add_child(_target)
	_manager.player = _target
	_manager.dissolve_all()

	if mode == &"boss":
		# O chefe de verdade, com vida enorme; o alvo do EnemyManager continua sendo o escriba
		# (os Diabretes do Summon o perseguem) e o escriba fica no meio, invulnerável.
		_manager.player = _player
		_player.global_position = Vector2(320, 240)
		var ch: ChapterData = main.get("chapter")
		var tough_boss: BossData = ch.boss.duplicate()
		tough_boss.max_hp = STRESS_HP
		ch = ch.duplicate()
		ch.boss = tough_boss
		main.set("chapter", ch)
		main.call("start_boss")
	elif mode == &"wave9":
		for entry: Array in WAVE9_MIX:
			var d: EnemyData = _tough(load(entry[0]))
			for i: int in entry[1]:
				_manager.spawn(d, _random_point())
	else:
		var imp: EnemyData = _tough(load("res://data/enemies/imp.tres"))
		_imp_tough = imp
		for i: int in ENEMIES:
			_manager.spawn(imp, _random_point())

	_ready_to_run = true


func _tough(src: EnemyData) -> EnemyData:
	var d: EnemyData = src.duplicate()
	d.max_hp = STRESS_HP
	d.letter_drop_chance = 0.0
	return d


func _physics_process(delta: float) -> void:
	if not _ready_to_run:
		return
	_time += delta
	_target.global_position = Vector2(320, 180) + Vector2.RIGHT.rotated(_time * ORBIT_SPEED) * ORBIT_RADIUS
	_player.vitals.iframes_left = 1.0
	if mode == &"refuge":
		RefugeZones.open(Vector2(320, 180), 48.0)
	if mode == &"arsenal":
		_player.global_position = BIBLE_PLAYER_AT
		_swap_left -= delta
		if _swap_left <= 0.0:
			_swap_left = ARSENAL_SWAP
			_player.arsenal.switch_to(1 - GameState.loadout.active)
	if mode == &"bible":
		_player.global_position = BIBLE_PLAYER_AT
		GameState.aim_with_mouse = true
		GameState.aim_point = BIBLE_PLAYER_AT + Vector2.RIGHT.rotated(_time * TAU / BIBLE_AIM_PERIOD) * 100.0
	if mode == &"boss":
		# Fase 3 (Cruz giratória + Summon): o pior caso da luta.
		var boss: Boss = main.get_node("World/Boss")
		if boss.filter != null and boss.filter.phase_index < boss.data.phases.size() - 1:
			boss.filter.phase_index = boss.data.phases.size() - 1
	while _projectiles.count < PROJECTILES:
		var dir := Vector2.RIGHT.rotated(_rng.randf() * TAU)
		_projectiles.fire(_random_point(), dir, 220.0, 1, PROJECTILE_RANGE)
	if mode == &"sweep":
		_sweep_tick(delta)
	if mode == &"wave9":
		# Os Monges e Borrões já atiram e sujam, completamos até a carga-alvo.
		while _eproj.count < ENEMY_PROJECTILES:
			_eproj.fire(_shot, _random_point(), Vector2.RIGHT.rotated(_rng.randf() * TAU))
		while _hazards.count < PUDDLES:
			_hazards.add_puddle(_puddle, _random_point())


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if _last_us > 0 and now <= _measure_until_us:
		_window_ms.append(float(now - _last_us) / 1000.0)
	_last_us = now


## Ciclo do modo sweep: conjura em SWEEP_CAST_AT, registra SWEEP_WINDOW s, repõe os 300.
func _sweep_tick(delta: float) -> void:
	if _sweep_cycles >= SWEEP_CYCLES:
		return
	_sweep_t += delta
	if not _sweep_cast and _sweep_t >= SWEEP_CAST_AT:
		_sweep_cast = true
		if sweep_word != &"":
			var word: WordData = null
			for w: WordData in _field.lexicon_data.words:  # apócrifos: word_for só vê os liberados
				if w.id == sweep_word:
					word = w
			var m := PoolManager.acquire(word.id) as Miracle
			m.start(word, word.power_budget, Vector2(320, 180), Vector2.RIGHT)
		_measure_until_us = Time.get_ticks_usec() + int(SWEEP_WINDOW * 1_000_000)
	if _sweep_t >= SWEEP_CYCLE:
		_sweep_t = 0.0
		_sweep_cast = false
		_sweep_cycles += 1
		if _sweep_cycles >= SWEEP_CYCLES:
			_report_sweep()
			return
		while _manager.count < ENEMIES:
			_manager.spawn(_imp_tough, _random_point())


func _report_sweep() -> void:
	var sorted: PackedFloat32Array = _window_ms.duplicate()
	sorted.sort()
	var slow: int = 0
	for ms: float in sorted:
		if ms > SLOW_FRAME_MS:
			slow += 1
	var p95: float = sorted[int(floor(0.95 * (sorted.size() - 1)))] if not sorted.is_empty() else 0.0
	var worst: float = sorted[sorted.size() - 1] if not sorted.is_empty() else 0.0
	var line: String = "SWEEP_PROBE palavra=%s frames=%d acima_33ms=%d p95_ms=%.1f pior_ms=%.1f" % [
		sweep_word if sweep_word != &"" else &"controle", sorted.size(), slow, p95, worst]
	print(line)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("fetch('/fps_result?' + encodeURIComponent(%s)).catch(function(){})" % JSON.stringify(line))


func active_projectiles() -> int:
	return _projectiles.count


func enemy_projectiles() -> int:
	return _eproj.count


func puddles() -> int:
	return _hazards.count


func _random_point() -> Vector2:
	return Vector2(_rng.randf_range(30.0, 610.0), _rng.randf_range(30.0, 330.0))
