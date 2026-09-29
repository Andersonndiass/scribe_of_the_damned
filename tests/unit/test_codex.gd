extends GutTest
## T702 Codex (007 FR-709, FR-710, SC-703; D-066): descobre palavra/combo ao conjurar, inimigo ao
## aparecer, chefe ao enfrentar; salva entre partidas; lista as novas desta partida (Vitória).

const PATH := "user://test_codex.save"

var _c: Node


func before_each() -> void:
	_c = (load("res://src/core/codex.gd") as GDScript).new()
	_c.save_path = PATH
	add_child_autofree(_c)
	_c.reset()


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_starts_empty() -> void:
	assert_false(_c.is_discovered(&"words", &"lux"))


func test_casting_a_word_discovers_it() -> void:
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	assert_true(_c.is_discovered(&"words", &"lux"))


func test_combo_enemy_and_boss_are_discovered() -> void:
	EventBus.combo_cast.emit(load("res://data/combos/flamma.tres"), 3.0)
	EventBus.enemy_spawned.emit(0, load("res://data/enemies/moth.tres"))
	EventBus.boss_spawned.emit(load("res://data/bosses/asmodeus.tres"))
	assert_true(_c.is_discovered(&"combos", &"flamma"))
	assert_true(_c.is_discovered(&"enemies", &"moth"))
	assert_true(_c.is_discovered(&"bosses", &"asmodeus"), "enfrentar basta, não precisa vencer")


func test_progress_survives_a_restart() -> void:
	EventBus.word_cast.emit(load("res://data/words/pax.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	var other: Node = (load("res://src/core/codex.gd") as GDScript).new()
	other.save_path = PATH
	add_child_autofree(other)
	other.load_saved()
	assert_true(other.is_discovered(&"words", &"pax"), "SC-703")


func test_new_this_run_is_listed_once() -> void:
	_c.begin_run()
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(_c.new_this_run().size(), 1)
	_c.begin_run()
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(_c.new_this_run().size(), 0, "já conhecida: não é nova")
