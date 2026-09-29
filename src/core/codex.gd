extends Node
## Grimório: o que o jogador já descobriu (007 FR-709, FR-710; D-066). Autoload "Codex".
## Palavra/combo ao conjurar pela primeira vez, inimigo ao aparecer na página, chefe ao ser
## enfrentado. Fica salvo entre partidas (`user://codex.save`; no web, IndexedDB). É conhecimento,
## não poder: nenhuma entrada dá bônus mecânico (D-018).

const CATEGORIES: Array[StringName] = [&"words", &"combos", &"enemies", &"bosses"]
## O Campeão é um verbete de inimigo próprio (narrativa §11), descoberto ao aparecer o primeiro.
const CHAMPION_ID := &"champion"

var save_path: String = "user://codex.save"
## Rodando a suíte GUT, o registro real não grava no save do jogador (os testes usam outro caminho).
var persist: bool = not " ".join(OS.get_cmdline_args()).contains("gut_cmdln")

var _found: Dictionary[StringName, Dictionary] = {}
## Entradas descobertas nesta partida: [categoria, id] (a tela de Vitória lista).
var _new_this_run: Array = []


func _ready() -> void:
	reset()
	load_saved()
	EventBus.word_cast.connect(func(w: WordData, _p: float, _o: Vector2, _d: Vector2) -> void:
		discover(&"words", w.id))
	EventBus.combo_cast.connect(func(c: ComboData, _p: float) -> void: discover(&"combos", c.id))
	EventBus.enemy_spawned.connect(func(_s: int, d: EnemyData) -> void: discover(&"enemies", d.id))
	EventBus.boss_spawned.connect(func(b: BossData) -> void: discover(&"bosses", b.id))
	EventBus.champion_spawned.connect(func(_s: int, _d: EnemyData) -> void: discover(&"enemies", CHAMPION_ID))


func reset() -> void:
	for c: StringName in CATEGORIES:
		_found[c] = {}
	_new_this_run.clear()


func begin_run() -> void:
	_new_this_run.clear()


func is_discovered(category: StringName, id: StringName) -> bool:
	return _found.get(category, {}).has(id)


func discovered(category: StringName) -> Array:
	return _found.get(category, {}).keys()


func new_this_run() -> Array:
	return _new_this_run.duplicate()


func discover(category: StringName, id: StringName) -> void:
	if id == &"" or is_discovered(category, id):
		return
	_found[category][id] = true
	_new_this_run.append([category, id])
	EventBus.codex_discovered.emit(category, id)
	if persist or save_path != "user://codex.save":
		save()


func save() -> int:
	var cfg := ConfigFile.new()
	for c: StringName in CATEGORIES:
		cfg.set_value("codex", String(c), PackedStringArray(_found[c].keys()))
	return cfg.save(save_path)


func load_saved() -> int:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(save_path)
	if err != OK:
		return err
	for c: StringName in CATEGORIES:
		for id: String in cfg.get_value("codex", String(c), PackedStringArray()):
			_found[c][StringName(id)] = true
	return OK
