extends GutTest
## D-084 EnemyManager + zonas letais: comum morre (até com vida alta), quem entra depois morre,
## quem está fora vive, nada depois de fechar; campeão leva 1 golpe por zona (uid, mesmo trocando
## de slot); duas zonas não matam duas vezes; teto por tick; REQUIEM marca letra garantida.

const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const IMP := preload("res://data/enemies/imp.tres")
const DT := 1.0 / 60.0

var _manager: EnemyManager
var _killed: int = 0
var _tough: EnemyData


func before_each() -> void:
	PoolManager.clear_all()
	KillZones.clear()
	_killed = 0
	var root := Node2D.new()
	add_child_autofree(root)
	var fx := Node2D.new()
	root.add_child(fx)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, 64, fx)
	_manager = EnemyManager.new()
	root.add_child(_manager)
	_manager.set_physics_process(false)
	_tough = IMP.duplicate()
	_tough.max_hp = 999
	_tough.move_speed = 0.0
	EventBus.enemy_killed.connect(_on_killed)


func after_each() -> void:
	EventBus.enemy_killed.disconnect(_on_killed)
	KillZones.clear()
	PoolManager.clear_all()


func _on_killed(_s: int, _d: EnemyData, _p: Vector2) -> void:
	_killed += 1


func _circle(center: Vector2, r: float, life: float = 1.0) -> KillZone:
	var z := KillZone.new()
	z.open(KillZone.Shape.CIRCLE, life)
	z.origin = center
	z.radius = r
	z.champion_frac = 0.4
	KillZones.register(z)
	return z


func _step(n: int = 1) -> void:
	for k: int in n:
		_manager._physics_process(DT)


func test_common_inside_dies_even_with_high_hp() -> void:
	_manager.spawn(_tough, Vector2(100, 100))
	_manager.spawn(_tough, Vector2(300, 300))
	_circle(Vector2(100, 100), 20)
	_step()
	assert_eq(_manager.count, 1, "o de dentro morreu; o de fora vive")
	assert_eq(_killed, 1)


func test_whoever_enters_later_dies_and_nothing_after_close() -> void:
	var z := _circle(Vector2(100, 100), 20, 0.1)
	_step()
	_manager.spawn(_tough, Vector2(105, 100))
	_step()
	assert_eq(_manager.count, 0, "entrou durante a zona: morreu")
	_step(10)
	assert_eq(z.phase, KillZone.Phase.CLOSED)
	_manager.spawn(_tough, Vector2(100, 100))
	_step()
	assert_eq(_manager.count, 1, "depois de fechar, ninguém morre")


func test_champion_takes_one_strike_per_zone_even_after_slot_swap() -> void:
	var slot: int = _manager.spawn(IMP, Vector2(100, 100), true)
	var max_hp: int = _manager.max_hp_of[slot]
	_manager.spawn(_tough, Vector2(400, 300))  # fica depois do campeão
	_manager.spawn(_tough, Vector2(110, 100))  # morre e troca slots
	var z := _circle(Vector2(100, 100), 30)
	_step(5)
	var champ: int = -1
	for i: int in _manager.count:
		if _manager.champion[i] == 1:
			champ = i
	assert_ne(champ, -1, "o campeão sobrevive a um golpe")
	assert_eq(_manager.hp[champ], max_hp - z.champion_damage(max_hp), "1 golpe só em 5 ticks")
	var z2 := _circle(Vector2(100, 100), 30)
	_step()
	assert_eq(_manager.hp[champ], max_hp - z.champion_damage(max_hp) - z2.champion_damage(max_hp), "zona nova, golpe novo")


func test_two_zones_kill_once() -> void:
	_manager.spawn(_tough, Vector2(100, 100))
	_circle(Vector2(100, 100), 20)
	_circle(Vector2(100, 100), 25)
	_step()
	assert_eq(_killed, 1)


func test_kill_cap_per_tick_then_the_rest() -> void:
	var cap: int = _manager.kill_zone_tuning.max_kills_per_tick
	for i: int in cap + 10:
		_manager.spawn(_tough, Vector2(50 + (i % 20) * 25, 50 + (i / 20) * 25))
	var s := KillZone.new()
	s.open(KillZone.Shape.SCREEN, 0.0, true)
	KillZones.register(s)
	_step()
	assert_eq(_killed, cap, "teto por tick")
	_step(3)
	assert_eq(_manager.count, 0, "o resto morre depois (a zona drena)")
	_step()
	assert_eq(s.phase, KillZone.Phase.CLOSED)


func test_requiem_marks_guaranteed_drops_up_to_the_cap() -> void:
	var marked: Array[int] = []
	var on_kill := func(slot: int, _d: EnemyData, _p: Vector2) -> void: marked.append(_manager.guaranteed_drop[slot])
	EventBus.enemy_killed.connect(on_kill)
	for i: int in 5:
		_manager.spawn(_tough, Vector2(100 + i * 10, 100))
	var z := _circle(Vector2(120, 100), 60)
	z.drops_left = 2
	_step()
	EventBus.enemy_killed.disconnect(on_kill)
	assert_eq(marked.count(1), 2, "só 2 letras garantidas")
