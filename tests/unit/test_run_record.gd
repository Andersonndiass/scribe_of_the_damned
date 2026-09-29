extends GutTest
## T712 Registro da partida para Game Over e Vitória (007 FR-705, FR-706): onda alcançada, tempo,
## palavras, inimigos, tinta e tempo do chefe; zera a cada partida.

const PLAYER := preload("res://data/player/anselmo.tres")


func before_each() -> void:
	GameState.start_run(PLAYER, 1)


func test_counts_the_run() -> void:
	EventBus.wave_started.emit(3, 60.0)
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	EventBus.word_cast.emit(load("res://data/words/pax.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	EventBus.enemy_killed.emit(0, load("res://data/enemies/imp.tres"), Vector2.ZERO)
	EventBus.gold_ink_collected.emit(4, 4)
	EventBus.gold_ink_collected.emit(1, 5)
	GameState.tick_run(12.5)
	var r: Dictionary = GameState.run_record()
	assert_eq(r["wave"], 3)
	assert_eq(r["words"], 2)
	assert_eq(r["kills"], 1)
	assert_eq(r["ink"], 5)
	assert_almost_eq(r["time"], 12.5, 0.001)


func test_boss_time_is_measured() -> void:
	EventBus.boss_spawned.emit(load("res://data/bosses/asmodeus.tres"))
	GameState.tick_run(30.0)
	EventBus.boss_defeated.emit(load("res://data/bosses/asmodeus.tres"))
	GameState.tick_run(10.0)
	assert_almost_eq(GameState.run_record()["boss_time"], 30.0, 0.001)


func test_new_run_resets() -> void:
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	GameState.start_run(PLAYER, 2)
	assert_eq(GameState.run_record()["words"], 0)
