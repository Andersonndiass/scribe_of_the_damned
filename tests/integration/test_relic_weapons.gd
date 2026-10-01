extends GutTest
## 017 T1736–T1738: Rosário (contas em órbita; cada inimigo 1 acerto a cada 0,4 s), Turíbulo
## (balanço que fere e deixa incenso; o rastro fica depois da troca) e Aspersório (leque mirado
## de gotas que não atravessam).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const ROSARY := preload("res://data/weapons/rosary.tres")
const CENSER := preload("res://data/weapons/censer.tres")
const ASPERGILLUM := preload("res://data/weapons/aspergillum.tres")
const PEN := preload("res://data/weapons/pen.tres")
const IMP := preload("res://data/enemies/imp.tres")

var _main: Node2D
var _player: Player
var _manager: EnemyManager
var _tough: EnemyData


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_manager.player = null  # parados: ninguém persegue
	_tough = IMP.duplicate()
	_tough.max_hp = 100
	_tough.move_speed = 0.0


func after_each() -> void:
	TimeScale.reset()
	WeaponZones.clear()


func _arm(w: WeaponData) -> void:
	GameState.loadout.slots[0] = WeaponSlot.new(w)
	GameState.loadout.slots[1] = WeaponSlot.new(PEN)
	GameState.loadout.set_active(0)


func test_all_relic_weapons_are_valid_and_sold() -> void:
	for w: WeaponData in [ROSARY, CENSER, ASPERGILLUM]:
		assert_eq(w.validate(), "", String(w.id))
		assert_has(_player.arsenal.tuning.weapons, w)
	var ids: Array = (_main.get_node("Shop") as Shop).tuning.deck.map(func(c: ShopItemData) -> StringName: return c.id)
	for id: StringName in [&"weapon_rosary", &"weapon_censer", &"weapon_aspergillum"]:
		assert_has(ids, id)


func test_rosary_beads_orbit_and_hit_at_most_every_04s() -> void:
	_arm(ROSARY)
	var body: Vector2 = _player.global_position + OrbitWeapon.BODY
	var i: int = _manager.spawn(_tough, body + Vector2(ROSARY.stats(1).orbit_radius, 0))
	await wait_physics_frames(100)  # ~1,67 s: uma volta
	var taken: int = 100 - _manager.hp[i]
	assert_gt(taken, 0, "as contas passaram por ele")
	assert_lte(taken, 5, "no máximo 1 acerto a cada 0,4 s")
	assert_true(_player.arsenal.orbit.on)
	_player.arsenal.switch_to(1)
	await wait_physics_frames(2)
	assert_false(_player.arsenal.orbit.on, "a troca recolhe as contas")


func test_censer_swings_hurts_and_its_trail_outlives_the_swap() -> void:
	_arm(CENSER)
	var body: Vector2 = _player.global_position + SwingTrailWeapon.BODY
	var i: int = _manager.spawn(_tough, body + Vector2(CENSER.stats(1).range, 0))
	await wait_physics_frames(110)  # pronto em 1,2 s + balanço
	assert_lt(_manager.hp[i], 100, "a cabeça do turíbulo feriu")
	assert_true(_player.arsenal.swing.trail.live, "incenso no chão")
	_player.arsenal.switch_to(1)
	await wait_physics_frames(3)
	assert_false(_player.arsenal.swing.is_swinging(), "a cabeça some na troca")
	assert_true(_player.arsenal.swing.trail.live, "o rastro continua ferindo")


func test_aspergillum_fires_a_fan_toward_the_aim() -> void:
	_arm(ASPERGILLUM)
	_player.arsenal.set_physics_process(false)
	_manager.spawn(_tough, _player.global_position + Vector2(40, -8))
	var was_mouse: bool = GameState.aim_with_mouse
	GameState.aim_with_mouse = true
	GameState.aim_point = _player.global_position + Vector2(100, -8)
	var proj: PlayerProjectileManager = _main.get_node("PlayerProjectiles")
	proj.set_physics_process(false)
	proj.clear()
	assert_true(_player.arsenal._fire(GameState.loadout.active_slot()))
	assert_eq(proj.count, ASPERGILLUM.stats(1).count, "4 gotas no nível 1")
	assert_eq(proj.kind_of(0), 2, "gota de água benta")
	var first: Vector2 = proj.position_of(0)
	GameState.aim_with_mouse = was_mouse
	assert_true(first.distance_to(_player.global_position + ASPERGILLUM.muzzle) < 1.0, "saem da boca do aspersório")
