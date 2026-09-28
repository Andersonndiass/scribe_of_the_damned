extends Node
## DEBUG (T080, 005 T540): mantém uma carga fixa sobre a cena principal real e mede com o FpsProbe.
##   modo "sc001" (padrão): 300 Diabretes + 150 letras + 200 projéteis do jogador (SC-001).
##   modo "wave9": o mesmo, mas os 300 inimigos são a MISTURA da onda 9 com os comportamentos
##                 ativos, mais 60 projéteis inimigos e 20 poças mantidos no ar/chão (SC-503).
##   modo "purgo": a carga do SC-001 e, a cada PURGO_CYCLE s, um PURGO que limpa os 300; mede o pior
##                 frame nos PURGO_WINDOW s depois de cada um e repõe os inimigos (002 SC-202).
## Inimigos com HP enorme (não morrem) perseguem um alvo que gira no centro; o jogador fica num
## canto, sem ataque automático, invulnerável. Nada de gameplay é alterado nos .tres.

const ENEMIES := 300
const LETTERS := 150
const PROJECTILES := 200
const ENEMY_PROJECTILES := 60
const PUDDLES := 20
const STRESS_HP := 1_000_000
const ORBIT_RADIUS := 80.0
const ORBIT_SPEED := 0.8
const PROJECTILE_RANGE := 900.0
const PURGO_CYCLE := 3.0
const PURGO_CAST_AT := 1.0
const PURGO_WINDOW := 0.8
const PURGO_CYCLES := 5
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
var _purgo_t: float = 0.0
var _purgo_cast: bool = false
var _purgo_cycles: int = 0
var _purgo_worst_ms: float = 0.0
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
	_player.auto_attack.enabled = false
	_player.global_position = Vector2(40, 40)
	main.add_child(_target)
	_manager.player = _target
	_manager.dissolve_all()

	if mode == &"wave9":
		for entry: Array in WAVE9_MIX:
			var d: EnemyData = _tough(load(entry[0]))
			for i: int in entry[1]:
				_manager.spawn(d, _random_point())
	else:
		var imp: EnemyData = _tough(load("res://data/enemies/imp.tres"))
		_imp_tough = imp
		for i: int in ENEMIES:
			_manager.spawn(imp, _random_point())

	var tuning: DropTuning = _field.tuning.duplicate()
	tuning.letter_lifetime = 1.0e6
	_field.tuning = tuning
	_refill_letters()
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
	while _projectiles.count < PROJECTILES:
		var dir := Vector2.RIGHT.rotated(_rng.randf() * TAU)
		_projectiles.fire(_random_point(), dir, 220.0, 1, PROJECTILE_RANGE)
	if mode == &"purgo" or mode == &"purgoctl":
		_purgo_tick(delta)
	if mode == &"wave9":
		# As Traças comem letras; os Monges e Borrões já atiram e sujam, completamos até a carga-alvo.
		_refill_letters()
		while _eproj.count < ENEMY_PROJECTILES:
			_eproj.fire(_shot, _random_point(), Vector2.RIGHT.rotated(_rng.randf() * TAU))
		while _hazards.count < PUDDLES:
			_hazards.add_puddle(_puddle, _random_point())


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if _last_us > 0 and now <= _measure_until_us:
		_purgo_worst_ms = maxf(_purgo_worst_ms, float(now - _last_us) / 1000.0)
	_last_us = now


## Ciclo do modo purgo: PURGO em PURGO_CAST_AT, mede PURGO_WINDOW s, repõe os 300 no fim do ciclo.
func _purgo_tick(delta: float) -> void:
	if _purgo_cycles >= PURGO_CYCLES:
		return
	_purgo_t += delta
	if not _purgo_cast and _purgo_t >= PURGO_CAST_AT:
		_purgo_cast = true
		var word: WordData = null
		for w: WordData in _field.lexicon_data.words:  # o PURGO é apócrifo: word_for só vê as liberadas
			if w.id == &"purgo":
				word = w
		if mode == &"purgo":
			var m := PoolManager.acquire(word.id) as Miracle
			m.start(word, word.power_budget, Vector2(320, 180), Vector2.RIGHT)
		_measure_until_us = Time.get_ticks_usec() + int(PURGO_WINDOW * 1_000_000)
	if _purgo_t >= PURGO_CYCLE:
		_purgo_t = 0.0
		_purgo_cast = false
		_purgo_cycles += 1
		if _purgo_cycles >= PURGO_CYCLES:
			_report_purgo()
			return
		while _manager.count < ENEMIES:
			_manager.spawn(_imp_tough, _random_point())


func _report_purgo() -> void:
	var line: String = "PURGO_PROBE modo=%s worst_ms=%.1f ciclos=%d" % [mode, _purgo_worst_ms, PURGO_CYCLES]
	print(line)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("fetch('/fps_result?' + encodeURIComponent(%s)).catch(function(){})" % JSON.stringify(line))


func _refill_letters() -> void:
	var alphabet: PackedStringArray = _field.lexicon.data.alphabet
	var i: int = _field.active_count()
	while _field.active_count() < LETTERS:
		var p: Vector2 = _random_point()
		p.x = maxf(p.x, 140.0)
		if _field.spawn_letter(alphabet[i % 19], i % 7 == 0, i % 5 == 0, p) == null:
			return
		i += 1


func active_projectiles() -> int:
	return _projectiles.count


func enemy_projectiles() -> int:
	return _eproj.count


func puddles() -> int:
	return _hazards.count


func _random_point() -> Vector2:
	return Vector2(_rng.randf_range(30.0, 610.0), _rng.randf_range(30.0, 330.0))
