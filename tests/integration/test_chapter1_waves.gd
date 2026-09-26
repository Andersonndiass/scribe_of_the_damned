extends GutTest
## 005 T532: as 9 ondas do Cap. 1 rodam em sequência, com os inimigos certos, 1 campeão por onda
## a partir da 3 e "capítulo completo" no fim — sem erro e sem instantiate (SC-501, SC-504).
## Tempo comprimido: cópias das ondas com 1/20 da duração (mesma composição e ordem).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const CHAPTER := preload("res://data/chapters/chapter_1.tres")
const COMPRESS := 20.0

var _main: Node2D
var _m: EnemyManager
var _started: Array[int] = []
var _completed: Array[int] = []
var _seen: Dictionary[StringName, bool] = {}
var _champions_by_wave: Dictionary[int, int] = {}


func _compressed_chapter() -> ChapterData:
	var ch: ChapterData = CHAPTER.duplicate()
	ch.waves = []
	for w: WaveData in CHAPTER.waves:
		var c: WaveData = w.duplicate(true)
		c.duration = w.duration / COMPRESS
		for g: SpawnGroup in c.groups:
			g.start_time /= COMPRESS
			g.end_time /= COMPRESS
			g.spawn_rate_start *= COMPRESS
			g.spawn_rate_end *= COMPRESS
		var times := PackedFloat32Array()
		for t: float in w.champion_times:
			times.append(t / COMPRESS)
		c.champion_times = times
		ch.waves.append(c)
	return ch


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	_main.set("chapter", _compressed_chapter())
	_main.set("between_waves", 0.3)
	# Conectar ANTES de entrar na árvore: a onda 1 começa no _ready do Main.
	EventBus.wave_started.connect(_on_started)
	EventBus.chapter_completed.connect(_on_completed)
	EventBus.enemy_spawned.connect(_on_spawned)
	add_child_autofree(_main)
	_m = _main.get_node("World/EnemyManager")
	(_main.get_node("World/Player") as Player).vitals.iframes_left = 1.0e9


func after_each() -> void:
	EventBus.wave_started.disconnect(_on_started)
	EventBus.chapter_completed.disconnect(_on_completed)
	EventBus.enemy_spawned.disconnect(_on_spawned)


func _on_started(i: int, _d: float) -> void:
	_started.append(i)


func _on_completed(c: int) -> void:
	_completed.append(c)


func _on_spawned(slot: int, d: EnemyData) -> void:
	_seen[d.id] = true
	if _m == null:
		return
	if _m.champion[slot] == 1:
		_champions_by_wave[GameState.wave_index] = _champions_by_wave.get(GameState.wave_index, 0) + 1


func test_nine_waves_in_sequence_with_champions_and_completion() -> void:
	var before: int = PoolManager.instantiate_count
	var timeout: float = 60.0  # 9 ondas comprimidas ≈ 37 s + pausas
	while _completed.is_empty() and timeout > 0.0:
		await wait_seconds(0.25)
		timeout -= 0.25
	assert_eq(_started, [1, 2, 3, 4, 5, 6, 7, 8, 9], "as 9 ondas em ordem")
	assert_eq(_completed, [1], "capítulo completo depois da 9")
	for id: StringName in [&"imp", &"moth", &"ink_blot", &"gargoyle", &"hollow_monk"]:
		assert_true(_seen.has(id), "apareceu %s" % id)
	for w: int in [1, 2]:
		assert_false(_champions_by_wave.has(w), "sem campeão na onda %d" % w)
	for w: int in range(3, 10):
		assert_lte(_champions_by_wave.get(w, 0), 1, "no máximo 1 campeão na onda %d (D-019)" % w)
	assert_gte(_champions_by_wave.size(), 5, "campeões apareceram na maioria das ondas 3–9")
	assert_eq(PoolManager.instantiate_count, before, "zero instantiate nas 9 ondas (SC-504)")
