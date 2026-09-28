extends GutTest
## T902 VoiceAllocator (009 FR-903, SC-902): cooldown, max_voices por som, roubo por prioridade.

var _a: VoiceAllocator


func before_each() -> void:
	_a = VoiceAllocator.new(4)


func test_free_voices_are_used_first() -> void:
	assert_eq(_a.request(&"a", 4, 0, 1, 0.0), 0)
	assert_eq(_a.request(&"b", 4, 0, 1, 0.0), 1)
	assert_eq(_a.busy_count(), 2)


func test_cooldown_ignores_repeats() -> void:
	assert_ne(_a.request(&"hit", 4, 30, 1, 1.000), -1)
	assert_eq(_a.request(&"hit", 4, 30, 1, 1.020), -1, "dentro de 30 ms")
	assert_ne(_a.request(&"hit", 4, 30, 1, 1.031), -1, "depois de 30 ms")


func test_max_voices_steals_oldest_of_same_sound() -> void:
	var v0: int = _a.request(&"kill", 2, 0, 1, 0.0)
	var v1: int = _a.request(&"kill", 2, 0, 1, 0.1)
	var v2: int = _a.request(&"kill", 2, 0, 1, 0.2)
	assert_eq(v2, v0, "rouba a voz mais antiga do mesmo som")
	assert_eq(_a.active_count(&"kill"), 2)
	assert_ne(v1, v2)


func test_full_pool_steals_lower_or_equal_priority() -> void:
	for i: int in 4:
		_a.request(StringName("low%d" % i), 4, 0, 0, float(i))
	var v: int = _a.request(&"high", 4, 0, 3, 10.0)
	assert_eq(v, 0, "roubou a mais antiga de prioridade menor")
	assert_eq(_a.sound_of(v), &"high")


func test_full_pool_of_higher_priority_refuses() -> void:
	for i: int in 4:
		_a.request(StringName("high%d" % i), 4, 0, 3, float(i))
	assert_eq(_a.request(&"low", 4, 0, 0, 10.0), -1)


func test_release_frees_the_voice() -> void:
	var v: int = _a.request(&"a", 1, 0, 1, 0.0)
	_a.release(v)
	assert_eq(_a.busy_count(), 0)
	assert_eq(_a.active_count(&"a"), 0)


func test_mass_kill_never_exceeds_max_voices() -> void:
	# SC-902: 300 mortes em ~10 frames.
	var big := VoiceAllocator.new(24)
	for i: int in 300:
		big.request(&"enemy_killed", 3, 0, 1, float(i / 30) / 60.0)
	assert_eq(big.active_count(&"enemy_killed"), 3)
	assert_true(big.busy_count() <= 24)
