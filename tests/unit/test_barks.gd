extends GutTest
## T825 Frases na partida (008 FR-815, D-072): cada gatilho mostra a sua frase; os intervalos valem
## (4 s entre frases, 15 s para repetir a da heresia); as do Asmodeus cortam a atual; os filtros
## (fase, velas) escolhem a frase certa; o balão nunca cobre o HUD.

var _d: BarkDirector
var _player: Node2D
var _boss: Node2D


func before_each() -> void:
	_player = Node2D.new()
	_player.global_position = Vector2(320, 180)
	_boss = Node2D.new()
	_boss.global_position = Vector2(320, 110)
	add_child_autofree(_player)
	add_child_autofree(_boss)
	_d = BarkDirector.new()
	_d.player = _player
	_d.boss = _boss
	add_child_autofree(_d)
	_d.set_process(false)


func _age(seconds: float) -> void:
	_d._process(seconds)


func _id() -> String:
	return "" if _d.current.is_empty() else str(_d.current["bark"]["id"])


func test_trigger_shows_its_line() -> void:
	EventBus.heresy_committed.emit(Vector2.ZERO)
	assert_eq(_id(), "anselmo_heresy")
	assert_eq(" ".join(_d.current["lines"]), PixelFont.normalize(tr(&"BARK_ANSELMO_HERESY")), "o texto da frase, em até 2 linhas")


func test_gaps_are_respected() -> void:
	EventBus.heresy_committed.emit(Vector2.ZERO)
	_age(3.0)
	_d.current = {}
	EventBus.wave_ended.emit(1)
	assert_eq(_id(), "", "menos de 4 s desde a última frase")
	_age(2.0)
	EventBus.wave_ended.emit(1)
	assert_eq(_id(), "anselmo_wave_clear")
	_d.current = {}
	_age(9.0)
	EventBus.heresy_committed.emit(Vector2.ZERO)
	assert_eq(_id(), "", "a heresia só repete depois de 15 s (aqui, 14 s)")
	_age(2.0)
	EventBus.heresy_committed.emit(Vector2.ZERO)
	assert_eq(_id(), "anselmo_heresy")


func test_asmodeus_priority_cuts_the_current_line() -> void:
	EventBus.wave_ended.emit(1)
	assert_eq(_id(), "anselmo_wave_clear")
	EventBus.boss_phase_changed.emit(1)
	assert_eq(_id(), "asmodeus_phase_2", "prioridade corta o balão atual")


func test_filters_pick_the_right_line() -> void:
	EventBus.boss_phase_changed.emit(2)
	assert_eq(_id(), "asmodeus_phase_3")
	_d.current = {}
	_age(30.0)
	EventBus.player_damaged.emit(1, 2)
	assert_eq(_id(), "", "com 2 velas não é a última vela")
	EventBus.player_damaged.emit(1, 1)
	assert_eq(_id(), "anselmo_last_candle")


func test_line_disappears_after_its_time() -> void:
	EventBus.wave_ended.emit(1)
	_age(3.1)
	assert_eq(_id(), "", "some depois de no máximo 2,5–3 s")


func test_balloon_never_covers_the_hud() -> void:
	for anchor: Vector2 in [Vector2(320, 290), Vector2(320, 70), Vector2(40, 200), Vector2(600, 150), Vector2(320, 180)]:
		var who := Rect2(anchor - Vector2(8, 8), Vector2(16, 16))
		var placed: Dictionary = _d.place(who)
		var r: Rect2 = placed["rect"]
		for h: Rect2 in BarkDirector.HUD_RECTS:
			assert_false(h.intersects(r) and placed["side"] != &"above", "balão em %s não cobre o HUD %s" % [anchor, h])
		assert_true(r.position.x >= 8.0 and r.end.x <= 632.0, "dentro da tela")
		if placed["side"] != &"above":
			assert_false(r.intersects(who), "não cobre quem fala")
