extends GutTest
## 010 (D-101; respostas "2a3a"): a Hildegarda guarda 2 palavras; as 2 parceiras fazem o combo com
## Espaço; sem par, Espaço solta a mais nova; a pronta no atril forma combo com uma guardada.

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _field: LetterField
var _caster: Caster
var _combos: Array[StringName] = []
var _cast: Array[StringName] = []


func before_each() -> void:
	GameState.picked_character = &"hildegarda"
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	(_main.get_node("World/Player") as Player).vitals.iframes_left = 1.0e6
	_field = _main.get_node("World/LetterField")
	_field.atril.set_capacity(6)
	_caster = _main.get_node("Caster")
	_combos.clear()
	_cast.clear()
	EventBus.combo_cast.connect(_on_combo)
	EventBus.word_cast.connect(_on_cast)


func after_each() -> void:
	EventBus.combo_cast.disconnect(_on_combo)
	EventBus.word_cast.disconnect(_on_cast)
	GameState.picked_character = &""


func _on_combo(c: ComboData, _p: float) -> void:
	_combos.append(c.id)


func _on_cast(w: WordData, _p: float, _o: Vector2, _d: Vector2) -> void:
	_cast.append(w.id)


func _write(word: String) -> void:
	for ch: String in word:
		_field.collect(ch, false)


func test_two_slots_and_the_pair_combos() -> void:
	assert_eq(_field.guard.capacity, 2)
	_write("LUX")
	_write("IGNIS")
	assert_eq(_field.guard.size(), 2, "as duas guardadas")
	assert_eq(_field.atril.size(), 0)
	assert_true(_caster.cast())
	assert_eq(_combos, [&"flamma"] as Array[StringName], "2a: as duas parceiras fazem o combo")
	assert_false(_field.guard.is_held())


func test_without_pair_space_releases_the_newest() -> void:
	_write("VITA")
	_write("PAX")
	assert_true(_caster.cast())
	assert_eq(_cast, [&"pax"] as Array[StringName], "3a: sai a mais nova")
	assert_eq(_field.guard.word.id, &"vita", "a outra fica")
