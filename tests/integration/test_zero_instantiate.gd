extends GutTest
## T083 SC-002: durante a onda, nenhum instantiate — nem sob a carga do SC-001 nem numa MORTIS
## que mata 300 de uma vez (dissoluções e letras excedentes são puladas, não instanciadas).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _manager: EnemyManager
var _field: LetterField
var _caster: Caster
var _player: Player


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_manager = _main.get_node("World/EnemyManager")
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	_player = _main.get_node("World/Player")
	_player.vitals.iframes_left = 1.0e6  # i-frames longos: o contato não mata o jogador no teste


func after_each() -> void:
	Engine.time_scale = 1.0


func test_sc001_load_and_mass_kill_do_not_instantiate() -> void:
	var before: int = PoolManager.instantiate_count
	var imp: EnemyData = load("res://data/enemies/imp.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 300:
		_manager.spawn(imp, Vector2(rng.randf_range(30, 610), rng.randf_range(30, 330)))
	for i: int in 150:
		_field.spawn_letter("L", false, false, Vector2(rng.randf_range(200, 610), rng.randf_range(30, 330)))
	var projectiles: PlayerProjectileManager = _main.get_node("PlayerProjectiles")
	for i: int in 200:
		assert_true(projectiles.fire(Vector2(320, 180), Vector2.RIGHT.rotated(i * 0.1), 220.0, 1, 600.0))
	await wait_physics_frames(30)
	_field.atril.clear()  # o ímã pode ter puxado Ls durante a carga
	_field.atril.set_capacity(6)
	for ch: String in "MORTIS":
		_field.collect(ch, false)
	assert_true(_caster.cast(), "MORTIS conjurada")
	await wait_physics_frames(20)
	assert_eq(_manager.count, 0, "MORTIS limpou a tela")
	assert_eq(PoolManager.instantiate_count, before, "zero instantiate durante a onda (SC-002)")
