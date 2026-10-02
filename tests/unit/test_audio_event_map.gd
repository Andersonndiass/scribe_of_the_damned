extends GutTest
## T904 AudioEventMap (009 FR-905, FR-906): variante antes da base; todos os eventos cobertos.

const MAP := preload("res://data/audio/event_map.tres")
const REQUIRED: Array[StringName] = [
	&"wave_started", &"wave_ended", &"chapter_completed", &"enemy_killed", &"champion_killed",
	&"player_damaged", &"player_healed", &"player_died", &"letter_menu_opened", &"letter_lost", &"letter_collected",
	&"letter_rejected", &"letter_eaten", &"gold_ink_collected", &"atril_valid", &"word_cast",
	&"combo_cast", &"heresy_committed", &"atril_purged", &"word_stored",
]


func _sound(id: StringName, event: StringName) -> SoundData:
	var s := SoundData.new()
	s.id = id
	s.event = event
	return s


func test_variant_wins_over_base() -> void:
	var map := AudioEventMap.new()
	map.sounds = [_sound(&"word_cast", &"word_cast"), _sound(&"word_cast_lux", &"word_cast:lux")]
	assert_eq(map.resolve(&"word_cast", &"lux").id, &"word_cast_lux")
	assert_eq(map.resolve(&"word_cast", &"sanctus").id, &"word_cast", "sem variante: a base")
	assert_eq(map.resolve(&"word_cast").id, &"word_cast")
	assert_null(map.resolve(&"nope"))
	assert_eq(map.by_id(&"word_cast_lux").event, &"word_cast:lux")


func test_every_required_event_has_a_sound() -> void:
	for key: StringName in REQUIRED:
		assert_not_null(MAP.resolve(key), "evento %s coberto" % key)


func test_every_word_and_combo_of_chapter_1_has_its_own_sound() -> void:
	for id: StringName in [&"lux", &"pax", &"crux", &"vita", &"aqua", &"ignis", &"mortis"]:
		assert_eq(MAP.resolve(&"word_cast", id).event, StringName("word_cast:%s" % id))
	for id: StringName in [&"vapor", &"flamma", &"caecitas", &"martyrium", &"requiem"]:
		assert_eq(MAP.resolve(&"combo_cast", id).event, StringName("combo_cast:%s" % id))


func test_every_sound_says_what_to_record() -> void:
	for s: SoundData in MAP.sounds:
		assert_ne(s.note, "", "%s tem nota" % s.id)


func test_every_priority_sound_has_a_stream() -> void:
	# 009 Fase 2 (T910): todo evento de prioridade ≥ 1 toca algo (provisório ou do autor).
	for s: SoundData in MAP.sounds:
		if s.priority >= 1:
			assert_not_null(s.stream, "%s tem som" % s.id)
