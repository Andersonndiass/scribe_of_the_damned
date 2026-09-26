extends GutTest
## 005 T510 [TEST-FIRST] Os 4 comportamentos novos na cena principal (FR-504..FR-507).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _player: Player
var _field: LetterField
var _m: EnemyManager
var _eaten: Array[String] = []


func before_each() -> void:
	_eaten.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_field = _main.get_node("World/LetterField")
	_m = _main.get_node("World/EnemyManager")
	_m.dissolve_all()
	EventBus.letter_eaten.connect(_on_eaten)


func after_each() -> void:
	EventBus.letter_eaten.disconnect(_on_eaten)
	Engine.time_scale = 1.0


func _on_eaten(letter: String, _p: Vector2) -> void:
	_eaten.append(letter)


func _data(path: String) -> EnemyData:
	return load(path)


# --- Traça ---------------------------------------------------------------------------------

func test_moth_eats_the_nearest_letter_then_flees() -> void:
	_player.global_position = Vector2(560, 300)
	_field.spawn_letter("P", false, false, Vector2(150, 100))
	var slot: int = _m.spawn(_data("res://data/enemies/moth.tres"), Vector2(110, 100))
	await wait_seconds(1.6)
	assert_eq(_eaten, ["P"], "comeu a letra")
	assert_eq(_field.active_count(), 0)
	assert_eq(_m.state[slot], EnemyBehavior.STATE_FLEE, "max_eaten = 1: foge depois de comer")
	assert_eq(_m.carried[slot], "P")


func test_moth_returns_eaten_letters_on_death() -> void:
	_player.global_position = Vector2(560, 300)
	_field.spawn_letter("V", false, false, Vector2(150, 100))
	var slot: int = _m.spawn(_data("res://data/enemies/moth.tres"), Vector2(120, 100))
	await wait_seconds(1.4)
	assert_eq(_eaten.size(), 1)
	_m.damage_at(slot, 99)
	var letters: Array = _field.get("_active").map(func(l: Letter) -> String: return l.letter)
	assert_has(letters, "V", "a letra comida volta ao chão")


func test_moth_ignores_magnetized_letters() -> void:
	_player.global_position = Vector2(560, 300)
	var l: Letter = _field.spawn_letter("A", false, false, Vector2(150, 100))
	l.magnetized = true
	l.life = 100.0
	_m.spawn(_data("res://data/enemies/moth.tres"), Vector2(140, 100))
	await wait_seconds(1.0)
	assert_eq(_eaten.size(), 0)


# --- Gárgula -------------------------------------------------------------------------------

func test_gargoyle_winds_up_with_locked_aim_then_dashes() -> void:
	_player.global_position = Vector2(300, 180)
	var slot: int = _m.spawn(_data("res://data/enemies/gargoyle.tres"), Vector2(230, 180 - 4))
	await wait_physics_frames(6)
	assert_eq(_m.state[slot], EnemyBehavior.STATE_WINDUP)
	var locked: Vector2 = _m.aim[slot]
	assert_almost_eq(locked.x, 1.0, 0.1, "mira no jogador, à direita")
	_player.global_position = Vector2(300, 320)  # o jogador foge durante o windup
	await wait_seconds(0.7)
	assert_eq(_m.state[slot], EnemyBehavior.STATE_DASH)
	assert_eq(_m.aim[slot], locked, "direção travada no início do windup")
	await wait_seconds(0.6)
	assert_eq(_m.state[slot], EnemyBehavior.STATE_COOLDOWN)
	assert_gt(_m.positions[slot].x, 300.0, "o dash seguiu reto e passou do ponto antigo")


# --- Monge Oco -----------------------------------------------------------------------------

func test_monk_keeps_distance_and_fires() -> void:
	var projectiles: EnemyProjectileManager = _main.get_node("World/EnemyProjectiles")
	_player.global_position = Vector2(320, 180)
	var near: int = _m.spawn(_data("res://data/enemies/hollow_monk.tres"), Vector2(360, 180))
	await wait_seconds(0.8)
	assert_gt(_m.positions[near].distance_to(_player.global_position), 40.0, "recuou (perto demais)")
	await wait_seconds(2.4)
	assert_gt(projectiles.count + projectiles.fired_total, 0, "atirou")


# --- Borrão --------------------------------------------------------------------------------

func test_blot_leaves_puddles_and_one_on_death() -> void:
	var hazards: HazardField = _main.get_node("HazardField")
	_player.global_position = Vector2(560, 300)
	var slot: int = _m.spawn(_data("res://data/enemies/ink_blot.tres"), Vector2(100, 100))
	await wait_seconds(2.8)
	assert_gte(hazards.count, 1, "deixou poça no rastro")
	var before: int = hazards.count
	_m.damage_at(slot, 99)
	assert_eq(hazards.count, before + 1, "poça na morte")


func test_player_is_slowed_inside_a_puddle() -> void:
	var hazards: HazardField = _main.get_node("HazardField")
	hazards.add_puddle(load("res://data/hazards/puddle_ink.tres"), _player.global_position)
	assert_almost_eq(hazards.slow_at(_player.global_position), 0.6, 0.001)
	assert_almost_eq(hazards.slow_at(_player.global_position + Vector2(100, 0)), 1.0, 0.001)
