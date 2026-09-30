extends GutTest
## D-084 Fase 2 na cena real: palavra de ataque conjurada pelo Caster abre a zona; o comum no
## alcance morre (até com vida alta) e solta recompensa; quem entra no LUX durante os 0,5 s morre;
## o campeão leva o golpe forte uma vez; ferramentas (PAX) não abrem zona.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const LUX := preload("res://data/words/lux.tres")
const IGNIS := preload("res://data/words/ignis.tres")
const PAX := preload("res://data/words/pax.tres")
const IMP := preload("res://data/enemies/imp.tres")

var _main: Node2D
var _em: EnemyManager
var _caster: Caster
var _player: Player
var _tough: EnemyData
var _killed: int = 0


func before_each() -> void:
	_killed = 0
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_em = _main.get_node("World/EnemyManager")
	_em.dissolve_all()
	_caster = _main.get_node("Caster")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_tough = IMP.duplicate()
	_tough.max_hp = 999
	_tough.move_speed = 0.0
	EventBus.enemy_killed.connect(_on_killed)


func after_each() -> void:
	EventBus.enemy_killed.disconnect(_on_killed)


func _on_killed(_s: int, _d: EnemyData, _p: Vector2) -> void:
	_killed += 1


func test_the_zone_words_are_the_attack_list() -> void:
	for id: String in ["lux", "ignis", "crux", "sanctus"]:
		assert_true((load("res://data/words/%s.tres" % id) as WordData).kill_zone, "%s é ataque" % id)
	for id: String in ["flamma", "vapor", "caecitas"]:
		assert_true((load("res://data/combos/%s.tres" % id) as WordData).kill_zone, "%s é ataque" % id)
	for id: String in ["pax", "aqua", "vita", "lumen", "fides", "gloria", "dominus", "spiritus", "salvator"]:
		assert_false((load("res://data/words/%s.tres" % id) as WordData).kill_zone, "%s é ferramenta" % id)
	assert_almost_eq(LUX.duration, 0.5, 0.001, "LUX 0,5 s (autor)")


func test_lux_kills_the_tough_common_on_the_line_and_whoever_walks_in() -> void:
	var o: Vector2 = _player.global_position
	_em.spawn(_tough, o + Vector2(60, 0))
	_caster._start_miracle(LUX, 1.0, o, Vector2.RIGHT)
	await wait_physics_frames(2)
	assert_eq(_killed, 1, "vida 999 na linha: morreu")
	_em.spawn(_tough, o + Vector2(120, 0))
	await wait_physics_frames(2)
	assert_eq(_killed, 2, "entrou no raio enquanto ele estava na tela: morreu")
	await wait_seconds(LUX.duration + 0.1)
	_em.spawn(_tough, o + Vector2(90, 0))
	await wait_physics_frames(3)
	assert_eq(_killed, 2, "depois do raio, ninguém morre")


func test_champion_takes_the_strike_once_per_cast() -> void:
	var o: Vector2 = _player.global_position + Vector2(0, 60)
	var slot: int = _em.spawn(IMP, o, true)
	var max_hp: int = _em.max_hp_of[slot]
	_caster._start_miracle(IGNIS, 1.0, o, Vector2.RIGHT)
	await wait_physics_frames(3)
	assert_eq(_em.count, 1, "o campeão aguenta o 1º golpe")
	assert_lt(_em.hp[0], max_hp - roundi(0.4 * max_hp) + 1, "levou o golpe forte (40%)")


func test_tools_do_not_open_a_zone() -> void:
	var o: Vector2 = _player.global_position
	_em.spawn(_tough, o + Vector2(30, 0))
	_caster._start_miracle(PAX, 1.0, o, Vector2.RIGHT)
	await wait_physics_frames(3)
	assert_eq(_killed, 0, "PAX empurra e atordoa, não mata")


func test_angelus_feathers_and_martyrium_cross_kill_what_they_sweep() -> void:
	# D-084 Fase 3: zonas que se movem com o escriba.
	var ang: WordData = load("res://data/words/angelus.tres")
	var mar: WordData = load("res://data/combos/martyrium.tres")
	assert_true(ang.kill_zone and mar.kill_zone)
	var body: Vector2 = _player.global_position
	# Anel de inimigos na órbita das penas: elas passam por todos.
	for k: int in 8:
		_em.spawn(_tough, body + Vector2(0, -10) + Vector2.RIGHT.rotated(TAU * k / 8.0) * ang.radius)
	_caster._start_miracle(ang, 1.0, body, Vector2.RIGHT)
	await wait_seconds(1.5)
	assert_eq(_em.count, 0, "as penas mataram todos os comuns da órbita")
	for k: int in 6:
		_em.spawn(_tough, _em.player_body() + Vector2.RIGHT.rotated(TAU * k / 6.0 + 0.3) * (mar.length * 0.6))
	_caster._start_miracle(mar, 1.0, body, Vector2.RIGHT)
	await wait_seconds(2.0)
	assert_eq(_em.count, 0, "a cruz girando varreu todos")
