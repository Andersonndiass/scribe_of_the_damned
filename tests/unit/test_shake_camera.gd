extends GutTest
## T620 ShakeCamera (006 FR-612; animation-agent): o mais forte substitui (nunca soma), decai
## até parar, px inteiros, e desligar a opção ignora os pedidos.

var _cam: ShakeCamera


func before_each() -> void:
	GameState.shake_enabled = true
	_cam = ShakeCamera.new()
	add_child_autofree(_cam)


func after_each() -> void:
	GameState.shake_enabled = true


func test_stronger_replaces_weaker_never_sums() -> void:
	_cam.request(1.0, 0.2)
	_cam.request(4.0, 0.7)
	assert_eq(_cam.strength, 4.0)
	_cam.request(2.0, 0.4)
	assert_eq(_cam.strength, 4.0, "mais fraco não substitui")


func test_decays_to_rest() -> void:
	_cam.request(2.0, 0.4)
	for i: int in 30:
		_cam.step(0.02)
		assert_eq(_cam.offset, _cam.offset.round(), "px inteiros")
		assert_true(absf(_cam.offset.x) <= 2.0 and absf(_cam.offset.y) <= 2.0)
	assert_eq(_cam.offset, Vector2.ZERO, "parou")


func test_disabled_ignores_requests() -> void:
	GameState.shake_enabled = false
	_cam.request(4.0, 0.7)
	_cam.step(0.05)
	assert_eq(_cam.offset, Vector2.ZERO)


func test_champion_death_asks_a_weak_shake() -> void:
	var got: Array[float] = []
	var on_shake := func(s: float, _d: float) -> void: got.append(s)
	EventBus.shake_requested.connect(on_shake)
	var em := EnemyManager.new()
	add_child_autofree(em)
	var i: int = em.spawn(load("res://data/enemies/imp.tres"), Vector2(100, 100), true)
	em.kill(i)
	EventBus.shake_requested.disconnect(on_shake)
	assert_eq(got, [1.0] as Array[float], "morte de campeão = shake fraco (pendência da 005)")
